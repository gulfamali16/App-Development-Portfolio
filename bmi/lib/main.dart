import 'package:flutter/material.dart';
import 'IconCard.dart';
import 'RepeatContainerCode.dart';
import 'constantfile.dart';
import 'resultfile.dart';

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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D9FF),
          secondary: const Color(0xFF7B61FF),
          surface: const Color(0xFF1E1E2E),
          background: const Color(0xFF0F0F1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
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
  // State variables
  Gender? selectedGender;
  int height = 180;
  int weight = 70;
  int age = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1E),
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F0F1E),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
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
                    // Top Row - Gender Selection
                    Expanded(
                      child: Row(
                        children: [
                          // Male Container
                          Expanded(
                            child: RepeatContainerCode(
                              colors: selectedGender == Gender.male
                                  ? kActiveCardColor
                                  : kInactiveCardColor,
                              cardWidget: IconCard(
                                icon: Icons.male_rounded,
                                label: 'MALE',
                              ),
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
                              colors: selectedGender == Gender.female
                                  ? kActiveCardColor
                                  : kInactiveCardColor,
                              cardWidget: IconCard(
                                icon: Icons.female_rounded,
                                label: 'FEMALE',
                              ),
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
                            const Text(
                              'HEIGHT',
                              style: kLabelTextStyle,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  height.toString(),
                                  style: kNumberTextStyle,
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'cm',
                                  style: kLabelTextStyle,
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.cyanAccent,
                                inactiveTrackColor: Colors.white30,
                                thumbColor: Colors.cyanAccent,
                                overlayColor: Colors.cyanAccent.withOpacity(0.3),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10.0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18.0,
                                ),
                              ),
                              child: Slider(
                                value: height.toDouble(),
                                min: 54,
                                max: 272,
                                onChanged: (double newValue) {
                                  setState(() {
                                    height = newValue.round();
                                  });
                                },
                              ),
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
                                  const Text('WEIGHT', style: kLabelTextStyle),
                                  Text(
                                    weight.toString(),
                                    style: kNumberTextStyle,
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Minus Button
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (weight > 1) weight--;
                                          });
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.white12,
                                          radius: 18,
                                          child: Icon(Icons.remove, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Plus Button
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            weight++;
                                          });
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.white12,
                                          radius: 18,
                                          child: Icon(Icons.add, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                  const Text('AGE', style: kLabelTextStyle),
                                  Text(
                                    age.toString(),
                                    style: kNumberTextStyle,
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Minus Button
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (age > 1) age--;
                                          });
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.white12,
                                          radius: 18,
                                          child: Icon(Icons.remove, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Plus Button
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            age++;
                                          });
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.white12,
                                          radius: 18,
                                          child: Icon(Icons.add, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ],
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

              // Bottom Calculate Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResultFile(),
                    ),
                  );
                },
                child: Container(
                  color: kBottomContainerColor,
                  margin: const EdgeInsets.only(top: 10.0),
                  width: double.infinity,
                  height: 80.0,
                  child: const Center(
                    child: Text(
                      'CALCULATE',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}