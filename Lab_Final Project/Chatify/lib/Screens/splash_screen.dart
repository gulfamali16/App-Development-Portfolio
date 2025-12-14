import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushReplacementNamed(context, '/onboarding'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF128C7E), // #128C7E
              Color(0xFF075E54), // #075E54
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDxZwtDm9Lf_ASKSzRFO8kyplMy6Ra3qHfRqoqZpaCZ-RO5HegAMrweZBU0R2qjUHcG9H79cgU8kHo9RWuwMd81-Wj0Pl_urCYwaE6W6a_8GBCX2wqTyGeVlwpOq8a90bn5UCBisYVlpXff0fEUhsT-Flxziil7DmlET0kNejpNitwbKCdvCLTcEEyoEiF3lXu37ZJohDABEczFXJ1YoqLWEy3CQgW3KESepa71azFt2WF34_RhKuAf860NXHgTUWeiEbxiuF66UGM',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                  colorBlendMode: BlendMode.overlay,
                ),
              ),
            ),

            // Main Content
            Column(
              children: [
                // Top Spacer
                const Expanded(flex: 1, child: SizedBox()),

                // Logo and Brand Section
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow Effect
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          // Logo Box
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Chat Icon
                                const Center(
                                  child: Icon(
                                    Icons.chat_bubble,
                                    color: Color(0xFF128C7E),
                                    size: 80,
                                  ),
                                ),

                                // Sheen Effect Overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.black.withOpacity(0.05),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Text Group
                      Column(
                        children: [
                          // Main Title
                          Text(
                            'ChatiFy',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.2,
                              shadows: const [
                                Shadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tagline
                          Text(
                            'Connect Instantly',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Section with Spinner and Version
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Loading Spinner
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withOpacity(0.7),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),

                      // Version Text
                      Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Plus Jakarta Sans',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
