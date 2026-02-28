import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_insta/flutter_insta.dart';
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

  // Get Instagram Reel video info using flutter_insta
  Future<Map<String, dynamic>?> getInstagramVideoInfo(String url) async {
    try {
      final flutterInsta = FlutterInsta();
      try {
        await flutterInsta.downloadReels(url);
      } catch (e) {
        debugPrint('Instagram: downloadReels failed: $e');
        return null;
      }
      final directUrl = flutterInsta.reelsDownloadUrl;

      if (directUrl == null || directUrl.isEmpty) {
        debugPrint('Instagram: downloadReels returned null/empty URL');
        return null;
      }

      int contentLength = 0;
      try {
        final response = await _dio.head(directUrl);
        final lengthHeader = response.headers.value('content-length');
        if (lengthHeader != null) {
          contentLength = int.tryParse(lengthHeader) ?? 0;
        }
      } catch (e) {
        debugPrint('Instagram: could not get content-length: $e');
      }

      return {
        'title': 'Instagram Reel',
        'author': 'Instagram',
        'duration': 0,
        'thumbnail': '',
        'views': 0,
        'videoUrl': url,
        'streams': [
          {
            'quality': '720p (with audio)',
            'size': contentLength,
            'itag': -1,
            'url': directUrl,
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
