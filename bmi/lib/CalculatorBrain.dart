// ============================================
// CalculatorBrain.dart - BMI CALCULATION LOGIC
// ============================================
import 'package:flutter/material.dart';
import 'constantfile.dart';


class CalculatorBrain {
  final int height;
  final int weight;
  final Gender? gender;
  final int age;

  CalculatorBrain({
    required this.height,
    required this.weight,
    required this.gender,
    required this.age,
  });

  double _bmi = 0.0;

  // Calculate BMI using formula: weight(kg) / (height(m))^2
  String calculateBMI() {
    _bmi = weight / ((height / 100) * (height / 100));

    // Adjust BMI based on gender
    if (gender == Gender.male) {
      // Males typically have more muscle mass
      _bmi = _bmi * 1.02;
    } else if (gender == Gender.female) {
      // Females typically have different body composition
      _bmi = _bmi * 0.98;
    }

    // Age adjustment (metabolism changes with age)
    if (age > 50) {
      _bmi = _bmi * 1.01; // Older adults
    } else if (age < 20) {
      _bmi = _bmi * 0.99; // Younger people
    }

    return _bmi.toStringAsFixed(1);
  }

  // Get result category
  String getResult() {
    if (_bmi >= 25) {
      return 'Overweight';
    } else if (_bmi > 18.5) {
      return 'Normal';
    } else {
      return 'Underweight';
    }
  }

  // Get interpretation message
  String getInterpretation() {
    if (_bmi >= 30) {
      return 'You have obesity. Consult a healthcare provider for guidance on achieving a healthier weight.';
    } else if (_bmi >= 25) {
      return 'You are overweight. Try to exercise more and maintain a balanced diet.';
    } else if (_bmi >= 18.5) {
      return 'You have a normal body weight. Good job! Keep maintaining your healthy lifestyle.';
    } else if (_bmi >= 17) {
      return 'You are slightly underweight. Try to eat more nutritious food and consider consulting a nutritionist.';
    } else {
      return 'You are significantly underweight. Please consult a healthcare provider for proper guidance.';
    }
  }

  // Get result color based on BMI
  Color getResultColor() {
    if (_bmi >= 25) {
      return const Color(0xFFFF6B6B); // Red for overweight
    } else if (_bmi >= 18.5) {
      return const Color(0xFF24D876); // Green for normal
    } else {
      return const Color(0xFFFFA726); // Orange for underweight
    }
  }
}