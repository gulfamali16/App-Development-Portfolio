import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoDownloaderService {
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        final status2 = await Permission.manageExternalStorage.request();
        return status2.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  // Get YouTube video info
  Future<Map<String, dynamic>?> getYouTubeVideoInfo(String url) async {
    try {
      final videoId = VideoId(url);
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      return {
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inSeconds ?? 0,
        'thumbnail': video.thumbnails.mediumResUrl,
        'views': video.engagement.viewCount,
        'streams': manifest.muxed.map((stream) => {
          'quality': stream.qualityLabel,
          'size': stream.size.totalBytes,
          'url': stream.url.toString(),
        }).toList(),
      };
    } catch (e) {
      print('Error getting YouTube video info: $e');
      return null;
    }
  }

  // Download video
  Future<String?> downloadVideo({
    required String url,
    required String fileName,
    required Function(int, int) onProgress,
  }) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download/VideoDownloader');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/$fileName.mp4';

      // Download the video
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
      print('Error downloading video: $e');
      return null;
    }
  }

  // Parse Instagram URL (simplified - real implementation would need Instagram API)
  Future<Map<String, dynamic>?> getInstagramVideoInfo(String url) async {
    // Note: Instagram requires authentication and proper API access
    // This is a placeholder for the structure
    return {
      'title': 'Instagram Video',
      'author': 'Instagram User',
      'duration': 0,
      'thumbnail': 'https://via.placeholder.com/320x180',
      'views': 0,
      'streams': [
        {
          'quality': '720p',
          'size': 8500000,
          'url': url,
        }
      ],
    };
  }

  void dispose() {
    _yt.close();
  }
}
