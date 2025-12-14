import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatiFy - Security',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF112115),
        brightness: Brightness.dark,
      ),
      home: const SecurityScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF30E85E);

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
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
                          _buildIndicator(isActive: false, isDark: isDark),
                          const SizedBox(width: 8),
                          _buildIndicator(isActive: false, isDark: isDark),
                          const SizedBox(width: 8),
                          _buildIndicator(isActive: true, primaryColor: primaryColor),
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
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Illustration Container
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: SizedBox(
                        width: 288, // 72 * 4 for @[360px] size
                        height: 288,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Abstract Background Blob
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(isDark ? 0.3 : 0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Main Shield Illustration
                            Center(
                              child: Container(
                                width: 256,
                                height: 256,
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCh1mwir-75B4mf-SdBXVzlbOLdzBnuOKuUmOtjJqMOEkDFpMy7eecHyN9PElNjoh-9eCS5F3vKTMROVw5Z1VnW6s1hH14YfxiZiIpY4kKsaKhYmZw2gNh1DSs1SSdpsYUwULRrt7OvKXgbREZgtdZaTRbK9p_TI0XvV2nXx93vOSM-g836TjsMAjMlACr8fjaCSDwi4meT4X8O_MamAziV2vf97-AJljaBzzmcdlGC20FFuOHf9VaG9dXMZW6pyx2u4sYOiQ0ykWg',
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                  borderRadius: BorderRadius.circular(128),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.6,
                                      colors: [
                                        Colors.black,
                                        Colors.transparent,
                                      ],
                                      stops: const [0.6, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(128),
                                      image: const DecorationImage(
                                        image: NetworkImage(
                                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCh1mwir-75B4mf-SdBXVzlbOLdzBnuOKuUmOtjJqMOEkDFpMy7eecHyN9PElNjoh-9eCS5F3vKTMROVw5Z1VnW6s1hH14YfxiZiIpY4kKsaKhYmZw2gNh1DSs1SSdpsYUwULRrt7OvKXgbREZgtdZaTRbK9p_TI0XvV2nXx93vOSM-g836TjsMAjMlACr8fjaCSDwi4meT4X8O_MamAziV2vf97-AJljaBzzmcdlGC20FFuOHf9VaG9dXMZW6pyx2u4sYOiQ0ykWg',
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Floating Lock Icon
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A3320) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.lock,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Text Content
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          Text(
                            'Secure & Private',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF111813),
                              fontFamily: 'Inter',
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Your messages are encrypted end-to-end. No one else can read them.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                                fontFamily: 'Inter',
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // Action Buttons Area
            Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 0),
              child: Column(
                children: [
                  // Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: const Color(0xFF112115),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: primaryColor.withOpacity(0.39),
                      minimumSize: const Size(double.infinity, 56),
                      animationDuration: const Duration(milliseconds: 200),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return const Color(0xFF28C450);
                          }
                          return null;
                        },
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 24),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Link
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontFamily: 'Inter',
                          ),
                        ),
                        WidgetSpan(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Spacer for Safe Area
            SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator({
    required bool isActive,
    bool isDark = false,
    Color? primaryColor,
  }) {
    return Container(
      width: isActive ? 32 : 16,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: isActive
            ? primaryColor ?? const Color(0xFF30E85E)
            : isDark
            ? const Color(0xFF374151)
            : const Color(0xFFD1D5DB),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: (primaryColor ?? const Color(0xFF30E85E)).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ]
            : null,
      ),
    );
  }
}
