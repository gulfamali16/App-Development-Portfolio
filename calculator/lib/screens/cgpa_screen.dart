import 'package:flutter/material.dart';
// 1. ADD THIS IMPORT for SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';

class CGPAScreen extends StatefulWidget {
  const CGPAScreen({super.key});

  @override
  State<CGPAScreen> createState() => _CGPAScreenState();
}

class _CGPAScreenState extends State<CGPAScreen> {
  final List<Map<String, dynamic>> semesters = [];

  // 2. ADD THIS FUNCTION to save the CGPA
  Future<void> _saveCGPA(double cgpa) async {
    final prefs = await SharedPreferences.getInstance();
    // This key MUST match the key used in your HomeScreen ("lastCGPA")
    await prefs.setDouble("lastCGPA", cgpa);
  }

  void _addSemester() {
    if (semesters.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 12 semesters allowed')),
      );
      return;
    }
    setState(() {
      semesters.add({
        'semester': 'Semester ${semesters.length + 1}',
        'gpa': '',
        'creditHours': '',
      });
    });
  }

  void _calculateCGPA() {
    double totalQualityPoints = 0;
    double totalCreditHours = 0;

    for (var s in semesters) {
      double? gpa = double.tryParse(s['gpa']);
      double? creditHours = double.tryParse(s['creditHours']);

      if (gpa == null || creditHours == null || gpa > 4.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Enter valid GPA (<=4.0) and Credit Hours')),
        );
        return;
      }

      totalQualityPoints += gpa * creditHours;
      totalCreditHours += creditHours;
    }

    if (totalCreditHours == 0) return;

    double cgpa = totalQualityPoints / totalCreditHours;

    // 3. CALL THE SAVE FUNCTION HERE
    _saveCGPA(cgpa);

    String formattedCGPA = cgpa.toStringAsFixed(2);
    Color cgpaColor = Colors.white; // Default color
    String message;

    // Determine message and color based on CGPA value
    if (cgpa >= 3.5) {
      message = 'Excellent Performance! Keep it up. 🚀';
      cgpaColor = const Color(0xFF00FF8C); // Bright Green/Teal
    } else if (cgpa >= 3.0) {
      message = 'Great Work! You\'re doing well. 👍';
      cgpaColor = const Color(0xFF33CCFF); // Bright Blue
    } else if (cgpa >= 2.0) {
      message = 'Satisfactory Progress. You can improve! 💪';
      cgpaColor = const Color(0xFFFFCC33); // Yellow/Gold
    } else {
      message = 'Needs Improvement. Focus on next semester. 📚';
      cgpaColor = const Color(0xFFFF5757); // Red
    }

    showDialog(
      context: context,
      builder: (_) => Dialog( // Using Dialog for more custom look
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1F1231), // Darker background for contrast
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C00F0), width: 3),
            boxShadow: [
              BoxShadow(
                color: cgpaColor.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 CGPA Achieved 🎉',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const Divider(color: Color(0xFF6C00F0), height: 30, thickness: 2),
              Text(
                formattedCGPA,
                style: TextStyle(
                  color: cgpaColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 50,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C00F0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('AWESOME!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF180F23),
      appBar: AppBar(
        title: const Text(
          'CGPA Calculator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6C00F0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Semester Button with white label
            ElevatedButton(
              onPressed: _addSemester,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C00F0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Add Semester',
                style: TextStyle(color: Colors.white), // Set label color to white
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: semesters.length,
                itemBuilder: (context, index) {
                  final semester = semesters[index];
                  return Card(
                    // Changed Card color for visibility against the dark background
                    color: const Color(0xFF2E1C40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            semester['semester'],
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF), // Text color is white
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            style: const TextStyle(color: Color(0xFFFFFFFF)), // Input text is white
                            keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'GPA',
                              labelStyle: TextStyle(color: Colors.white70), // Label color adjusted for Card background
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF6C00F0), width: 2),
                              ),
                            ),
                            onChanged: (val) => semester['gpa'] = val,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            style: const TextStyle(color: Color(0xFFFFFFFF)), // Input text is white
                            keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Credit Hours',
                              labelStyle: TextStyle(color: Colors.white70), // Label color adjusted for Card background
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF6C00F0), width: 2),
                              ),
                            ),
                            onChanged: (val) => semester['creditHours'] = val,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Calculate CGPA Button with white label
            ElevatedButton(
              onPressed: _calculateCGPA,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF), // Button color is white
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Calculate CGPA',
                style: TextStyle(
                    color: Color(0xFF180F23), // Set label color to a dark color for contrast against white button
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}