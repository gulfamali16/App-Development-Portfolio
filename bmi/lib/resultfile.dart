import 'package:flutter/material.dart';
import 'constantfile.dart';

class ResultFile extends StatelessWidget {
  final String bmiResult;
  final String resultText;
  final String interpretation;
  final Color resultColor;

  const ResultFile({
    super.key,
    required this.bmiResult,
    required this.resultText,
    required this.interpretation,
    required this.resultColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),

      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ removes back button
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "BMI Calculator",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),

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

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your Result',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // RESULT CARD
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kActiveCardColor,
                  borderRadius: BorderRadius.circular(kContainerBorderRadius),
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      resultText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                        letterSpacing: 1.5,
                      ),
                    ),

                    Text(
                      bmiResult,
                      style: const TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        interpretation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // RECALCULATE BUTTON
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                color: kBottomContainerColor,
                width: double.infinity,
                height: 80,
                child: const Center(
                  child: Text(
                    'ReCALCULATE',
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
    );
  }
}
