import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatiFy - Share Moments',
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F8),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF11211F),
        brightness: Brightness.dark,
      ),
      home: const ShareMomentsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShareMomentsScreen extends StatefulWidget {
  const ShareMomentsScreen({super.key});

  @override
  State<ShareMomentsScreen> createState() => _ShareMomentsScreenState();
}

class _ShareMomentsScreenState extends State<ShareMomentsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for voice message waveform
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF16AC9A);

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11211F) : const Color(0xFFF6F8F8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  // Left Spacer
                  const SizedBox(width: 48),

                  // Page Indicators
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // First dot
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFDCE5E4),
                            ),
                          ),

                          // Active indicator (wider)
                          Container(
                            width: 32,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: primaryColor,
                            ),
                          ),

                          // Third dot
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFDCE5E4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Skip Button
                  SizedBox(
                    width: 48,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.015,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Hero Illustration
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: SizedBox(
                        width: 360,
                        child: AspectRatio(
                          aspectRatio: 4/3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  // Background Glow
                                  Positioned.fill(
                                    child: Center(
                                      child: Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.2),
                                              blurRadius: 60,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Chat Bubble 1: Incoming (Photo)
                                  Positioned(
                                    top: 20,
                                    left: 0,
                                    child: Container(
                                      width: 192,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E2E2C) : Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(24),
                                          bottomLeft: Radius.circular(24),
                                          bottomRight: Radius.circular(24),
                                        ),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Avatar/Thumbnail
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                              borderRadius: BorderRadius.circular(8),
                                              image: const DecorationImage(
                                                image: NetworkImage(
                                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC2Klz-dA1tDFTf1rkS75Rqo9LXraLxvkNksBI4l6x5eaBO7EXwe9IISOiazHyIpctPYJ_vh1lEa-ybjslfvEahVhR_Qe-xWrQ1ld-Oa4vXUV37UBZbGcPjVZsDCMWTe8SrWfsK3GAkPOWxCkv36pWAn07XRYFfq1jVfXF_DXNSKEgtpuUmRSVvT-7HdchuwKdabmiL2s-2daSVTGBWNbiNawuo3NtI5ldH-SePWo6-QTpHD0iHLy0X_WfM1i-cxqbU3sKmKJei-aw',
                                                ),
                                                fit: BoxFit.cover,
                                                opacity: 0.8,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // Message content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 80,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  width: 48,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Chat Bubble 2: Outgoing (Video Message)
                                  Positioned(
                                    top: constraints.maxHeight * 0.5,
                                    right: 0,
                                    child: Transform.translate(
                                      offset: const Offset(0, -40),
                                      child: Container(
                                        width: 208,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(4),
                                            bottomLeft: Radius.circular(24),
                                            bottomRight: Radius.circular(24),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                // Play button
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),

                                                const SizedBox(width: 12),

                                                // Waveform
                                                Expanded(
                                                  child: Container(
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        _buildWaveBar(1.0),
                                                        const SizedBox(width: 2),
                                                        _buildWaveBar(0.5),
                                                        const SizedBox(width: 2),
                                                        _buildWaveBar(0.75),
                                                        const SizedBox(width: 2),
                                                        _buildWaveBar(1.0),
                                                        const SizedBox(width: 2),
                                                        _buildWaveBar(0.5),
                                                        const SizedBox(width: 2),
                                                        _buildWaveBar(0.66),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            // Video info
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Video Message',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontFamily: 'Plus Jakarta Sans',
                                                    ),
                                                  ),
                                                  Text(
                                                    '0:15',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontFamily: 'Plus Jakarta Sans',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Chat Bubble 3: Incoming (Voice Note)
                                  Positioned(
                                    bottom: 0,
                                    left: 16,
                                    child: Transform.translate(
                                      offset: const Offset(0, -8),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E2E2C) : Colors.white,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                            bottomLeft: Radius.circular(4),
                                            bottomRight: Radius.circular(24),
                                          ),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Microphone icon
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.mic,
                                                color: primaryColor,
                                                size: 18,
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            // Animated waveform
                                            SizedBox(
                                              height: 16,
                                              child: Row(
                                                children: [
                                                  _buildAnimatedWaveBar(0.5),
                                                  const SizedBox(width: 2),
                                                  _buildAnimatedWaveBar(1.0),
                                                  const SizedBox(width: 2),
                                                  _buildAnimatedWaveBar(0.75),
                                                  const SizedBox(width: 2),
                                                  _buildAnimatedWaveBar(0.5),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Text Content
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 32),
                      child: Column(
                        children: [
                          Text(
                            'Share Moments',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF111717),
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Connect deeper by sharing your world. Send high-quality photos, videos, and voice messages with a single tap.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                fontFamily: 'Plus Jakarta Sans',
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.all(24).copyWith(bottom: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/onboarding3');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 8,
                  shadowColor: primaryColor.withOpacity(0.25),
                  minimumSize: const Size(double.infinity, 56),
                  animationDuration: const Duration(milliseconds: 200),
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return const Color(0xFF139686);
                      }
                      return null;
                    },
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(double heightMultiplier) {
    return Container(
      width: 1.5,
      height: 12 * heightMultiplier,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(0.75),
      ),
    );
  }

  Widget _buildAnimatedWaveBar(double maxHeightMultiplier) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        // Create pulsing effect
        final time = DateTime.now().millisecondsSinceEpoch / 1000;
        final pulse = (sin(time * 4 * pi) + 1) / 2; // 0 to 1

        return Container(
          width: 2,
          height: 16 * (maxHeightMultiplier * (0.5 + pulse * 0.5)),
          decoration: BoxDecoration(
            color: const Color(0xFF16AC9A),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }
}
