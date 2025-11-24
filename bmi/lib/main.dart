import 'package:flutter/material.dart';

void main() {
  runApp(const BMICalculatorApp());
}

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Modern Color Scheme with gradient-inspired colors
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D9FF), // Bright Cyan
          secondary: const Color(0xFF7B61FF), // Purple
          surface: const Color(0xFF1E1E2E), // Dark Blue-Grey
          background: const Color(0xFF0F0F1E), // Very Dark Blue
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),

        // Scaffold Background with gradient
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),

        // AppBar Theme - Beautiful and Advanced
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF00D9FF),
            size: 28,
          ),
        ),

        // Card Theme for future use
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E2E),
          elevation: 8,
          shadowColor: const Color(0xFF00D9FF).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              width: 1,
            ),
          ),
        ),

        // Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00D9FF),
            letterSpacing: -2,
          ),
          displayMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.white60,
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: const Color(0xFF0F0F1E),
            elevation: 8,
            shadowColor: const Color(0xFF00D9FF).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Icon Theme
        iconTheme: const IconThemeData(
          color: Color(0xFF00D9FF),
          size: 32,
        ),
      ),
      home: const BMIHomeScreen(),
    );
  }
}

class BMIHomeScreen extends StatelessWidget {
  const BMIHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Advanced Gradient Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1E), // Dark blue
              const Color(0xFF1A1A2E), // Medium dark
              const Color(0xFF16213E), // Blue tint
              const Color(0xFF0F0F1E), // Dark blue
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Advanced Custom AppBar with Glassmorphism Effect
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E1E2E).withOpacity(0.8),
                      const Color(0xFF2A2A3E).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF00D9FF),
                          Color(0xFF7B61FF),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'BMI CALCULATOR',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body Content - Themed Containers
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Top Row - Two Containers
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            // Left Container
                            Expanded(
                              child: _buildThemedContainer(
                                icon: Icons.male_rounded,
                                label: 'MALE',
                                color: const Color(0xFF00D9FF),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Container
                            Expanded(
                              child: _buildThemedContainer(
                                icon: Icons.female_rounded,
                                label: 'FEMALE',
                                color: const Color(0xFFFF6B9D),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Middle Container - Full Width
                      Expanded(
                        flex: 2,
                        child: _buildThemedContainer(
                          icon: Icons.height_rounded,
                          label: 'HEIGHT',
                          color: const Color(0xFF7B61FF),
                          isFullWidth: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bottom Row - Two Containers
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            // Left Container
                            Expanded(
                              child: _buildThemedContainer(
                                icon: Icons.monitor_weight_rounded,
                                label: 'WEIGHT',
                                color: const Color(0xFF00D9FF),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Container
                            Expanded(
                              child: _buildThemedContainer(
                                icon: Icons.calendar_today_rounded,
                                label: 'AGE',
                                color: const Color(0xFF7B61FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Themed Container Widget
  static Widget _buildThemedContainer({
    required IconData icon,
    required String label,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2E),
            const Color(0xFF2A2A3E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: isFullWidth ? 60 : 50,
              color: color,
            ),
          ),

          const SizedBox(height: 16),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}