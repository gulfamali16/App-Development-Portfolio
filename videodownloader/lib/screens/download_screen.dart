import 'package:flutter/material.dart';
import 'dart:io';
import '../models/download_item.dart';
import '../services/database_service.dart';
import '../services/video_downloader_service.dart';

class DownloadScreen extends StatefulWidget {
  final Map<String, dynamic> videoInfo;
  final String platform;
  final String url;

  const DownloadScreen({
    super.key,
    required this.videoInfo,
    required this.platform,
    required this.url,
  });

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  int selectedQualityIndex = 0;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  int downloadedBytes = 0;
  int totalBytes = 0;
  String downloadSpeed = '0 MB/s';
  final VideoDownloaderService _downloaderService = VideoDownloaderService();

  List<Map<String, dynamic>> get streams =>
      List<Map<String, dynamic>>.from(widget.videoInfo['streams'] ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.grey.shade800),
              ),
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildVideoPreview(),
                        _buildQualitySelection(),
                        if (isDownloading) _buildDownloadProgress(),
                      ],
                    ),
                  ),
                ),

                // Bottom Actions
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            color: const Color(0xFFf20d0d),
          ),
          const Expanded(
            child: Text(
              'Download Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    final duration = widget.videoInfo['duration'] ?? 0;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF271b1b),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            // Video Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(widget.videoInfo['thumbnail'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Video Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf20d0d),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.platform.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.videoInfo['title'] ?? 'Video',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.videoInfo['author'] ?? 'Unknown'} • ${_formatViews(widget.videoInfo['views'])} views',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Quality',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred resolution for download',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            streams.length,
            (index) => _buildQualityOption(index),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(int index) {
    final stream = streams[index];
    final isSelected = selectedQualityIndex == index;
    final isBest = index == 0;

    return GestureDetector(
      onTap: () => setState(() => selectedQualityIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF271b1b)
              : const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFf20d0d)
                : Colors.grey.shade800,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stream['quality'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf20d0d).withOpacity(0.2),
                            border: Border.all(
                              color: const Color(0xFFf20d0d).withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFf20d0d),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '~${_formatFileSize(stream['size'])}${index == 1 ? ' • Recommended' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFf20d0d)
                      : Colors.grey.shade700,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFf20d0d) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF271b1b),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFf20d0d),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Downloading...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(downloadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf20d0d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: downloadProgress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFf20d0d),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatFileSize(downloadedBytes)} / ${_formatFileSize(totalBytes)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  downloadSpeed,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isDownloading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade700),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close),
                  SizedBox(width: 8),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isDownloading ? null : _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf20d0d),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFf20d0d).withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isDownloading ? Icons.downloading : Icons.save),
                  const SizedBox(width: 8),
                  Text(
                    isDownloading ? 'Downloading...' : 'Save to Gallery',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    final selectedStream = streams[selectedQualityIndex];
    final fileName =
        '${widget.videoInfo['title']}_${DateTime.now().millisecondsSinceEpoch}';

    DateTime lastUpdate = DateTime.now();
    int lastBytes = 0;

    final filePath = await _downloaderService.downloadVideo(
      url: selectedStream['url'],
      fileName: fileName,
      onProgress: (received, total) {
        final now = DateTime.now();
        final timeDiff = now.difference(lastUpdate).inMilliseconds;

        if (timeDiff > 500) {
          // Update every 500ms
          final bytesDiff = received - lastBytes;
          final speed = (bytesDiff / timeDiff) * 1000; // bytes per second

          setState(() {
            downloadProgress = received / total;
            downloadedBytes = received;
            totalBytes = total;
            downloadSpeed = '${(speed / 1024 / 1024).toStringAsFixed(1)} MB/s';
          });

          lastUpdate = now;
          lastBytes = received;
        }
      },
    );

    if (filePath != null) {
      // Save to database
      final downloadItem = DownloadItem(
        title: widget.videoInfo['title'],
        url: widget.url,
        platform: widget.platform,
        thumbnail: widget.videoInfo['thumbnail'],
        fileSize: _formatFileSize(selectedStream['size']),
        filePath: filePath,
        downloadDate: DateTime.now(),
        isCompleted: true,
      );

      await DatabaseService.instance.insertDownload(downloadItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } else {
      setState(() {
        isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Please try again.'),
            backgroundColor: Color(0xFFf20d0d),
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _formatViews(int? views) {
    if (views == null) return '0';
    if (views < 1000) return views.toString();
    if (views < 1000000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '${(views / 1000000).toStringAsFixed(1)}M';
  }
}
