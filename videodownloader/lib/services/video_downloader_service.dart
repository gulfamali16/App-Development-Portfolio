import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoDownloaderService {
  YoutubeExplode? _ytInstance;
  bool _disposed = false;
  YoutubeExplode get _yt {
    if (_disposed) throw StateError('VideoDownloaderService has been disposed');
    return _ytInstance ??= YoutubeExplode();
  }
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

  // ============================================================
  // INSTAGRAM DOWNLOAD — Multi-strategy approach
  // ============================================================

  /// Extract shortcode from any Instagram URL format
  String? _extractInstagramShortcode(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final path = uri.path;

    // Match /reel/SHORTCODE/, /reels/SHORTCODE/, /p/SHORTCODE/
    final regex = RegExp(r'/(reel|reels|p)/([A-Za-z0-9_-]+)');
    final match = regex.firstMatch(path);
    if (match != null) {
      return match.group(2);
    }

    return null;
  }

  /// Build a clean Instagram URL from shortcode
  String _buildCleanInstagramUrl(String shortcode) {
    return 'https://www.instagram.com/reel/$shortcode/';
  }

  /// Common headers for Instagram requests
  Map<String, String> get _instagramHeaders => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'X-IG-App-ID': '936619743392459',
    'X-Requested-With': 'XMLHttpRequest',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'Referer': 'https://www.instagram.com/',
  };

  /// Strategy 1: Use ?__a=1&__d=dis JSON endpoint
  Future<Map<String, dynamic>?> _tryInstagramJsonEndpoint(String shortcode) async {
    try {
      final url = 'https://www.instagram.com/reel/$shortcode/?__a=1&__d=dis';
      debugPrint('Instagram Strategy 1: Trying $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: _instagramHeaders,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('Strategy 1 failed: status ${response.statusCode}');
        return null;
      }

      Map<String, dynamic>? jsonData;
      if (response.data is Map) {
        jsonData = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          jsonData = json.decode(response.data as String) as Map<String, dynamic>;
        } catch (_) {
          debugPrint('Strategy 1: Response is not JSON');
          return null;
        }
      }

      if (jsonData == null) return null;

      String? videoUrl;
      String? thumbnailUrl;
      String? title;
      String? author;

      // Try graphql structure
      final graphql = jsonData['graphql'] as Map<String, dynamic>?;
      if (graphql != null) {
        final media = graphql['shortcode_media'] as Map<String, dynamic>?;
        if (media != null) {
          videoUrl = media['video_url'] as String?;
          thumbnailUrl = media['display_url'] as String?;
          final owner = media['owner'] as Map<String, dynamic>?;
          author = owner?['username'] as String? ?? 'Instagram';
          final caption = media['edge_media_to_caption'] as Map<String, dynamic>?;
          final edges = caption?['edges'] as List?;
          if (edges != null && edges.isNotEmpty) {
            final node = edges[0]['node'] as Map<String, dynamic>?;
            title = node?['text'] as String?;
          }
        }
      }

      // Try items structure (newer API)
      if (videoUrl == null) {
        final items = jsonData['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final item = items[0] as Map<String, dynamic>;
          final videoVersions = item['video_versions'] as List?;
          if (videoVersions != null && videoVersions.isNotEmpty) {
            videoUrl = videoVersions[0]['url'] as String?;
          }
          final imageVersions = item['image_versions2'] as Map<String, dynamic>?;
          if (imageVersions != null) {
            final candidates = imageVersions['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              thumbnailUrl = candidates[0]['url'] as String?;
            }
          }
          final user = item['user'] as Map<String, dynamic>?;
          author = user?['username'] as String?;
          final captionObj = item['caption'] as Map<String, dynamic>?;
          title = captionObj?['text'] as String?;
        }
      }

      if (videoUrl != null) {
        debugPrint('Strategy 1 SUCCESS: Found video URL');
        return _buildInstagramResult(
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          title: title,
          author: author,
          originalUrl: 'https://www.instagram.com/reel/$shortcode/',
        );
      }

      debugPrint('Strategy 1: No video URL in JSON response');
      return null;
    } catch (e) {
      debugPrint('Strategy 1 error: $e');
      return null;
    }
  }

  /// Strategy 2: Use GraphQL query endpoint
  Future<Map<String, dynamic>?> _tryInstagramGraphQL(String shortcode) async {
    try {
      final variables = json.encode({'shortcode': shortcode});
      final url = 'https://www.instagram.com/graphql/query/?query_hash=b3055c01b4b222b8a47dc12b090e4e64&variables=$variables';
      debugPrint('Instagram Strategy 2: Trying GraphQL');

      final response = await _dio.get(
        url,
        options: Options(
          headers: _instagramHeaders,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('Strategy 2 failed: status ${response.statusCode}');
        return null;
      }

      Map<String, dynamic>? jsonData;
      if (response.data is Map) {
        jsonData = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          jsonData = json.decode(response.data as String) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }

      if (jsonData == null) return null;

      final data = jsonData['data'] as Map<String, dynamic>?;
      final media = data?['shortcode_media'] as Map<String, dynamic>?;

      if (media != null) {
        final videoUrl = media['video_url'] as String?;
        final thumbnailUrl = media['display_url'] as String?;
        final owner = media['owner'] as Map<String, dynamic>?;
        final author = owner?['username'] as String?;
        String? title;
        final caption = media['edge_media_to_caption'] as Map<String, dynamic>?;
        final edges = caption?['edges'] as List?;
        if (edges != null && edges.isNotEmpty) {
          final node = edges[0]['node'] as Map<String, dynamic>?;
          title = node?['text'] as String?;
        }

        if (videoUrl != null) {
          debugPrint('Strategy 2 SUCCESS: Found video URL');
          return _buildInstagramResult(
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            title: title,
            author: author,
            originalUrl: 'https://www.instagram.com/reel/$shortcode/',
          );
        }
      }

      debugPrint('Strategy 2: No video URL in GraphQL response');
      return null;
    } catch (e) {
      debugPrint('Strategy 2 error: $e');
      return null;
    }
  }

  /// Strategy 3: Use /p/ URL format with ?__a=1&__d=dis
  Future<Map<String, dynamic>?> _tryInstagramPostEndpoint(String shortcode) async {
    try {
      final url = 'https://www.instagram.com/p/$shortcode/?__a=1&__d=dis';
      debugPrint('Instagram Strategy 3: Trying /p/ endpoint');

      final response = await _dio.get(
        url,
        options: Options(
          headers: _instagramHeaders,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('Strategy 3 failed: status ${response.statusCode}');
        return null;
      }

      Map<String, dynamic>? jsonData;
      if (response.data is Map) {
        jsonData = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          jsonData = json.decode(response.data as String) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }

      if (jsonData == null) return null;

      String? videoUrl;
      String? thumbnailUrl;
      String? title;
      String? author;

      final graphql = jsonData['graphql'] as Map<String, dynamic>?;
      if (graphql != null) {
        final media = graphql['shortcode_media'] as Map<String, dynamic>?;
        if (media != null) {
          videoUrl = media['video_url'] as String?;
          thumbnailUrl = media['display_url'] as String?;
          final owner = media['owner'] as Map<String, dynamic>?;
          author = owner?['username'] as String?;
          final caption = media['edge_media_to_caption'] as Map<String, dynamic>?;
          final edges = caption?['edges'] as List?;
          if (edges != null && edges.isNotEmpty) {
            final node = edges[0]['node'] as Map<String, dynamic>?;
            title = node?['text'] as String?;
          }
        }
      }

      final items = jsonData['items'] as List?;
      if (videoUrl == null && items != null && items.isNotEmpty) {
        final item = items[0] as Map<String, dynamic>;
        final videoVersions = item['video_versions'] as List?;
        if (videoVersions != null && videoVersions.isNotEmpty) {
          videoUrl = videoVersions[0]['url'] as String?;
        }
        final imageVersions = item['image_versions2'] as Map<String, dynamic>?;
        if (imageVersions != null) {
          final candidates = imageVersions['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            thumbnailUrl ??= candidates[0]['url'] as String?;
          }
        }
        final user = item['user'] as Map<String, dynamic>?;
        author ??= user?['username'] as String?;
        final captionObj = item['caption'] as Map<String, dynamic>?;
        title ??= captionObj?['text'] as String?;
      }

      if (videoUrl != null) {
        debugPrint('Strategy 3 SUCCESS: Found video URL');
        return _buildInstagramResult(
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          title: title,
          author: author,
          originalUrl: 'https://www.instagram.com/p/$shortcode/',
        );
      }

      debugPrint('Strategy 3: No video URL found');
      return null;
    } catch (e) {
      debugPrint('Strategy 3 error: $e');
      return null;
    }
  }

  /// Strategy 4: Scrape HTML page for embedded JSON (last resort)
  Future<Map<String, dynamic>?> _tryInstagramHtmlScrape(String shortcode) async {
    try {
      final url = 'https://www.instagram.com/reel/$shortcode/';
      debugPrint('Instagram Strategy 4: Trying HTML scrape');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) return null;

      final html = response.data.toString();
      String? videoUrl;
      String? thumbnailUrl;

      // Look for video_url in any embedded JSON
      final videoUrlRegex = RegExp(r'"video_url"\s*:\s*"(https?:[^"]+)"');
      final videoUrlMatch = videoUrlRegex.firstMatch(html);
      if (videoUrlMatch != null) {
        videoUrl = videoUrlMatch.group(1);
        videoUrl = videoUrl?.replaceAll(r'\u0026', '&');
        videoUrl = videoUrl?.replaceAll(r'\/', '/');
        videoUrl = videoUrl?.replaceAll('\\u0026', '&');
        videoUrl = videoUrl?.replaceAll('\\/', '/');
      }

      // Look for og:video meta tag
      if (videoUrl == null) {
        final ogVideoRegex = RegExp(r'<meta\s+(?:property|name)="og:video(?::secure_url)?"\s+content="([^"]+)"', caseSensitive: false);
        final ogVideoMatch = ogVideoRegex.firstMatch(html);
        if (ogVideoMatch != null) {
          videoUrl = ogVideoMatch.group(1)?.replaceAll('&amp;', '&');
        }
      }

      // Look for any CDN video URL pattern
      if (videoUrl == null) {
        final cdnRegex = RegExp(r'(https://(?:scontent|video)[^"\\]+\.mp4[^"\\]*)');
        final cdnMatch = cdnRegex.firstMatch(html);
        if (cdnMatch != null) {
          videoUrl = cdnMatch.group(1);
          videoUrl = videoUrl?.replaceAll(r'\u0026', '&');
          videoUrl = videoUrl?.replaceAll(r'\/', '/');
        }
      }

      // Get thumbnail
      final ogImageRegex = RegExp(r'<meta\s+(?:property|name)="og:image"\s+content="([^"]+)"', caseSensitive: false);
      final ogImageMatch = ogImageRegex.firstMatch(html);
      if (ogImageMatch != null) {
        thumbnailUrl = ogImageMatch.group(1)?.replaceAll('&amp;', '&');
      }

      if (videoUrl != null) {
        debugPrint('Strategy 4 SUCCESS: Found video URL from HTML');
        return _buildInstagramResult(
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          title: null,
          author: null,
          originalUrl: url,
        );
      }

      debugPrint('Strategy 4: No video URL found in HTML');
      return null;
    } catch (e) {
      debugPrint('Strategy 4 error: $e');
      return null;
    }
  }

  /// Build standardized result map from Instagram video info
  Future<Map<String, dynamic>?> _buildInstagramResult({
    required String videoUrl,
    String? thumbnailUrl,
    String? title,
    String? author,
    required String originalUrl,
  }) async {
    String displayTitle = title ?? 'Instagram Reel';
    if (displayTitle.length > 80) {
      displayTitle = '${displayTitle.substring(0, 77)}...';
    }

    int fileSize = 0;
    try {
      final headResponse = await _dio.head(
        videoUrl,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final contentLength = headResponse.headers.value('content-length');
      if (contentLength != null) {
        fileSize = int.tryParse(contentLength) ?? 0;
      }
    } catch (e) {
      debugPrint('Could not get file size: $e');
    }

    return {
      'title': displayTitle,
      'author': author ?? 'Instagram',
      'duration': 0,
      'thumbnail': thumbnailUrl ?? '',
      'views': 0,
      'videoUrl': originalUrl,
      'streams': [
        {
          'quality': '720p (Original)',
          'size': fileSize,
          'itag': -1,
          'url': videoUrl,
        }
      ],
    };
  }

  /// Main method: Get Instagram video info using multiple strategies
  Future<Map<String, dynamic>?> getInstagramVideoInfo(String url) async {
    debugPrint('Getting Instagram video info for: $url');

    final shortcode = _extractInstagramShortcode(url);
    if (shortcode == null || shortcode.isEmpty) {
      debugPrint('Could not extract shortcode from URL: $url');
      return null;
    }
    debugPrint('Extracted shortcode: $shortcode');

    // Try Strategy 1: ?__a=1&__d=dis JSON endpoint (reel URL)
    var result = await _tryInstagramJsonEndpoint(shortcode);
    if (result != null) return result;

    // Try Strategy 2: GraphQL query
    result = await _tryInstagramGraphQL(shortcode);
    if (result != null) return result;

    // Try Strategy 3: /p/ URL format with ?__a=1&__d=dis
    result = await _tryInstagramPostEndpoint(shortcode);
    if (result != null) return result;

    // Try Strategy 4: HTML page scrape (last resort)
    result = await _tryInstagramHtmlScrape(shortcode);
    if (result != null) return result;

    debugPrint('All Instagram strategies failed for shortcode: $shortcode');
    return null;
  }

  void dispose() {
    _disposed = true;
    _ytInstance?.close();
    _ytInstance = null;
  }
}
