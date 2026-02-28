import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import '../models/download_item.dart';
import '../services/database_service.dart';
import '../services/video_downloader_service.dart';
import 'download_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedPlatform = 'YouTube';
  final TextEditingController _urlController = TextEditingController();
  final VideoDownloaderService _downloaderService = VideoDownloaderService();
  List<DownloadItem> recentDownloads = [];
  bool isLoading = false;
  bool _databaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await DatabaseService.instance.database;
      if (!mounted) return;
      setState(() {
        _databaseInitialized = true;
      });
      _loadRecentDownloads();
    } catch (e) {
      debugPrint('Database initialization error: $e');
      if (!mounted) return;
      setState(() {
        _databaseInitialized = false;
      });
    }
  }

  Future<void> _loadRecentDownloads() async {
    if (!_databaseInitialized) return;

    try {
      final downloads = await DatabaseService.instance.getRecentDownloads(limit: 2);
      if (!mounted) return;
      setState(() {
        recentDownloads = downloads;
      });
    } catch (e) {
      debugPrint('Error loading downloads: $e');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _urlController.text = data!.text!;
      });
    }
  }

  Future<void> _analyzeLink() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('Please enter a valid URL');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic>? videoInfo;

      if (selectedPlatform == 'YouTube') {
        videoInfo = await _downloaderService.getYouTubeVideoInfo(url);
      } else {
        videoInfo = await _downloaderService.getInstagramVideoInfo(url);
      }

      setState(() {
        isLoading = false;
      });

      if (videoInfo != null && mounted) {
        // Navigate to download screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DownloadScreen(
              videoInfo: videoInfo!,
              platform: selectedPlatform,
              url: url,
            ),
          ),
        ).then((_) => _loadRecentDownloads());
      } else {
        _showSnackBar('Failed to analyze video. Please check the URL.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFf20d0d),
      ),
    );
  }

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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                  child: const Text(
                    'Video Downloader',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Platform Selector
                        _buildPlatformSelector(),

                        // Title Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Save your favorite moments',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Paste the video URL below to start processing',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Input Card
                        _buildInputCard(),

                        // Recent Downloads
                        if (_databaseInitialized) _buildRecentDownloads(),
                      ],
                    ),
                  ),
                ),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildPlatformButton('YouTube', Icons.play_circle_outline),
            _buildPlatformButton('Instagram', Icons.camera_alt_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton(String platform, IconData icon) {
    final isSelected = selectedPlatform == platform;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPlatform = platform),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF121212) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFFf20d0d)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                platform,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFf20d0d)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFf20d0d).withOpacity(0.2),
              blurRadius: 15,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VIDEO LINK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf20d0d).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Auto-detected',
                    style: TextStyle(
                      color: Color(0xFFf20d0d),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade700,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'https://www.youtube.com/watch?v=...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _pasteFromClipboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf20d0d).withOpacity(0.1),
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade700),
                        ),
                      ),
                      height: 56,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.content_paste,
                            size: 20,
                            color: Color(0xFFf20d0d),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PASTE',
                            style: TextStyle(
                              color: Color(0xFFf20d0d),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _analyzeLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf20d0d),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFf20d0d).withOpacity(0.3),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Analyze Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.bolt, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDownloads() {
    if (recentDownloads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Downloads',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: Color(0xFFf20d0d),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentDownloads.map((item) => _buildDownloadItem(item)),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(DownloadItem item) {
    final isYouTube = item.platform == 'YouTube';
    final platformIcon = isYouTube ? Icons.play_circle : Icons.camera_alt;
    final platformColor = isYouTube ? const Color(0xFFf20d0d) : const Color(0xFF833AB4);

    return InkWell(
      onTap: () async {
        if (item.filePath != null && File(item.filePath!).existsSync()) {
          try {
            await OpenFile.open(item.filePath!);
          } catch (e) {
            _showSnackBar('Could not open file. No compatible app found.');
          }
        } else {
          _showSnackBar('File not found. It may have been deleted.');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(platformIcon, color: platformColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.platform} • ${item.fileSize}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              item.isCompleted ? Icons.check_circle : Icons.download,
              color: item.isCompleted ? Colors.green : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Downloads are saved to your phone\'s Gallery.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Color(0xFFf20d0d),
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            width: 128,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}