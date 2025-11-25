import 'package:flutter/material.dart';
import 'IconCard.dart';
import 'RepeatContainerCode.dart';
import 'constantfile.dart';


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
      home: const InputPage(),
    );
  }
}

// Enum for Gender
enum Gender {
  male,
  female,
}

// Input Page - StatefulWidget
class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  // Gender selection using enum
  Gender? selectedGender;
  int height = 180;

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
              // Advanced Custom AppBar
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
                child: Center(
                  child: ShaderMask(
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
                ),
              ),

              // Body Content
              Expanded(
                child: Column(
                  children: [
                    // Top Row - Gender Selection with GestureDetector
                    Expanded(
                      child: Row(
                        children: [
                          // Male Container
                          Expanded(
                            child: RepeatContainerCode(
                              // Ternary Operator: condition ? true : false
                              colors: selectedGender == Gender.male
                                  ? kActiveCardColor
                                  : kInactiveCardColor,
                              cardWidget: IconCard(
                                icon: Icons.male_rounded,
                                label: 'MALE',
                              ),
                              // Function object - onPress returns GestureDetector action
                              onPress: () {
                                setState(() {
                                  selectedGender = Gender.male;
                                });
                              },
                            ),
                          ),
                          // Female Container
                          Expanded(
                            child: RepeatContainerCode(
                              // Ternary Operator: condition ? true : false
                              colors: selectedGender == Gender.female
                                  ? kActiveCardColor
                                  : kInactiveCardColor,
                              cardWidget: IconCard(
                                icon: Icons.female_rounded,
                                label: 'FEMALE',
                              ),
                              // Function object - onPress returns GestureDetector action
                              onPress: () {
                                setState(() {
                                  selectedGender = Gender.female;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Middle Container - Height
                    Expanded(
                      child: RepeatContainerCode(
                        colors: kActiveCardColor,
                        cardWidget: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Title
                            Text(
                              'HEIGHT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Value + cm
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  height.toString(),
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'cm',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),

                            // Slider
                            Slider(
                              value: height.toDouble(),
                              min: 54,
                              max: 272,
                              activeColor: Colors.cyanAccent,
                              inactiveColor: Colors.white30,
                              onChanged: (value) {
                                setState(() {
                                  height = value.toInt();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),


                    // Bottom Row - Weight & Age
                    Expanded(
                      child: Row(
                        children: [
                          // Weight Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: kActiveCardColor,
                              cardWidget: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'WEIGHT',
                                    style: kLabelTextStyle,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          // Age Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: kActiveCardColor,
                              cardWidget: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'AGE',
                                    style: kLabelTextStyle,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
                child: Center(
                  child: ShaderMask(
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
                ),
              ),

              // Body Content - Themed Containers
              Expanded(
                child: Column(
                  children: [
                    // Top Row - Two Containers
                    Expanded(
                      child: Row(
                        children: [
                          // Male Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: const Color(0xFF1E1E2E),
                              cardWidget: IconCard(
                                icon: Icons.male_rounded,
                                label: 'MALE',
                              ),
                            ),
                          ),
                          // Female Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: const Color(0xFF1E1E2E),
                              cardWidget: IconCard(
                                icon: Icons.female_rounded,
                                label: 'FEMALE',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Middle Container - Full Width
                    Expanded(
                      child: RepeatContainerCode(
                        colors: const Color(0xFF1E1E2E),
                        cardWidget: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'HEIGHT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '180',
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'cm',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Row - Two Containers
                    Expanded(
                      child: Row(
                        children: [
                          // Weight Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: const Color(0xFF1E1E2E),
                              cardWidget: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'WEIGHT',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '70',
                                    style: TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Age Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: const Color(0xFF1E1E2E),
                              cardWidget: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'AGE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '25',
                                    style: TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



