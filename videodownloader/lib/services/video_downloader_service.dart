import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoDownloaderService {
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();

  // Request storage permission — handles Android 13+ (READ_MEDIA_VIDEO) and older (WRITE_EXTERNAL_STORAGE)
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try legacy storage permission first (Android ≤ 12)
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) return true;

      // On Android 13+ storage permission is deprecated; request READ_MEDIA_VIDEO instead
      final videoStatus = await Permission.videos.request();
      if (videoStatus.isGranted) return true;

      // As a last resort, request manage external storage
      if (status.isPermanentlyDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }

      // Both permissions were denied — the file write will likely fail
      return false;
    }
    return true;
  }

  // Get YouTube video info; includes 'itag' so the download step can re-fetch the right stream
  Future<Map<String, dynamic>?> getYouTubeVideoInfo(String url) async {
    try {
      final videoId = VideoId(url);
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Sort muxed streams from highest to lowest bitrate
      final sortedStreams = manifest.muxed.toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

      return {
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inSeconds ?? 0,
        'thumbnail': video.thumbnails.mediumResUrl,
        'views': video.engagement.viewCount,
        'videoUrl': url,
        'streams': sortedStreams.map((stream) => {
          'quality': stream.qualityLabel,
          'size': stream.size.totalBytes,
          'itag': stream.tag,
          'url': stream.url.toString(),
        }).toList(),
      };
    } catch (e) {
      debugPrint('Error getting YouTube video info: $e');
      return null;
    }
  }

  // Download a YouTube video using youtube_explode_dart's stream client (avoids expired signed URLs)
  Future<String?> downloadYouTubeStream({
    required String videoUrl,
    required int itag,
    required String fileName,
    required Function(int, int) onProgress,
  }) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getDownloadDirectory();
      // Sanitise fileName to remove characters that are invalid on FAT/NTFS
      final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = '${directory.path}/$safeFileName.mp4';

      final videoId = VideoId(videoUrl);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Find the requested quality; fall back to highest bitrate if not found or itag is invalid
      final allStreams = manifest.muxed.toList();
      MuxedStreamInfo streamInfo = itag >= 0
          ? allStreams.firstWhere(
              (s) => s.tag == itag,
              orElse: () => allStreams.reduce(
                (a, b) => a.bitrate.compareTo(b.bitrate) >= 0 ? a : b,
              ),
            )
          : allStreams.reduce(
              (a, b) => a.bitrate.compareTo(b.bitrate) >= 0 ? a : b,
            );

      final totalBytes = streamInfo.size.totalBytes;
      final stream = _yt.videos.streamsClient.get(streamInfo);

      final file = File(filePath);
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress(downloaded, totalBytes);
      }

      await sink.flush();
      await sink.close();

      return filePath;
    } catch (e) {
      debugPrint('Error downloading YouTube stream: $e');
      return null;
    }
  }

  // Download video via Dio (for non-YouTube sources or direct URLs)
  Future<String?> downloadVideo({
    required String url,
    required String fileName,
    required Function(int, int) onProgress,
  }) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getDownloadDirectory();
      final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = '${directory.path}/$safeFileName.mp4';

      await _dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received, total);
          }
        },
      );

      return filePath;
    } catch (e) {
      debugPrint('Error downloading video: $e');
      return null;
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download/VideoDownloader');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
    return getApplicationDocumentsDirectory();
  }

  // Get Instagram Reel video info by scraping the page HTML
  // This replaces flutter_insta which had a dependency conflict with google_fonts
  Future<Map<String, dynamic>?> getInstagramVideoInfo(String url) async {
    try {
      // Fetch the page with a mobile user agent to get the video meta tags
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
          },
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('Instagram returned status: ${response.statusCode}');
        return null;
      }

      final html = response.data.toString();
      String? videoUrl;
      String? thumbnailUrl;

      // Method 1: Look for og:video meta tag
      final ogVideoRegex = RegExp(r'<meta\s+(?:property|name)="og:video"\s+content="([^"]+)"', caseSensitive: false);
      final ogVideoMatch = ogVideoRegex.firstMatch(html);
      if (ogVideoMatch != null) {
        videoUrl = ogVideoMatch.group(1);
        videoUrl = videoUrl?.replaceAll('&amp;', '&');
      }

      // Method 2: Look for video_url in JSON data embedded in the page
      if (videoUrl == null) {
        final videoUrlRegex = RegExp(r'"video_url"\s*:\s*"([^"]+)"');
        final videoUrlMatch = videoUrlRegex.firstMatch(html);
        if (videoUrlMatch != null) {
          videoUrl = videoUrlMatch.group(1);
          videoUrl = videoUrl?.replaceAll(r'\u0026', '&');
          videoUrl = videoUrl?.replaceAll(r'\/', '/');
        }
      }

      // Method 3: Look for any .mp4 URL in the page
      if (videoUrl == null) {
        final mp4Regex = RegExp(r'(https?://[^\s"<>]+\.mp4[^\s"<>]*)');
        final mp4Match = mp4Regex.firstMatch(html);
        if (mp4Match != null) {
          videoUrl = mp4Match.group(1);
          videoUrl = videoUrl?.replaceAll('&amp;', '&');
          videoUrl = videoUrl?.replaceAll(r'\u0026', '&');
          videoUrl = videoUrl?.replaceAll(r'\/', '/');
        }
      }

      // Get thumbnail from og:image
      final ogImageRegex = RegExp(r'<meta\s+(?:property|name)="og:image"\s+content="([^"]+)"', caseSensitive: false);
      final ogImageMatch = ogImageRegex.firstMatch(html);
      if (ogImageMatch != null) {
        thumbnailUrl = ogImageMatch.group(1)?.replaceAll('&amp;', '&');
      }

      // Get title from og:title
      String title = 'Instagram Reel';
      final ogTitleRegex = RegExp(r'<meta\s+(?:property|name)="og:title"\s+content="([^"]+)"', caseSensitive: false);
      final ogTitleMatch = ogTitleRegex.firstMatch(html);
      if (ogTitleMatch != null) {
        title = ogTitleMatch.group(1) ?? 'Instagram Reel';
        if (title.length > 80) {
          title = '${title.substring(0, 77)}...';
        }
      }

      if (videoUrl == null || videoUrl.isEmpty) {
        debugPrint('Could not extract video URL from Instagram page');
        return null;
      }

      // Try to get the file size via HEAD request
      int fileSize = 0;
      try {
        final headResponse = await _dio.head(
          videoUrl,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        final contentLength = headResponse.headers.value('content-length');
        if (contentLength != null) {
          fileSize = int.tryParse(contentLength) ?? 0;
        }
      } catch (e) {
        debugPrint('Could not get Instagram video file size: $e');
      }

      return {
        'title': title,
        'author': 'Instagram',
        'duration': 0,
        'thumbnail': thumbnailUrl ?? '',
        'views': 0,
        'videoUrl': url,
        'streams': [
          {
            'quality': '720p (with audio)',
            'size': fileSize,
            'itag': -1,
            'url': videoUrl,
          }
        ],
      };
    } catch (e) {
      debugPrint('Error getting Instagram video info: $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
