import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Grade Mapping (OSMSTAS/Typical 4.0 Scale)
Map<String, double> gradePointMap = {
  'A': 4.0,
  'A-': 3.7,
  'B+': 3.3,
  'B': 3.0,
  'B-': 2.7,
  'C+': 2.3,
  'C': 2.0,
  'C-': 1.7,
  'D+': 1.3,
  'D': 1.0,
  'F': 0.0,
};

class Course {
  String? grade;
  double? creditHours;
  // Controller to correctly handle the initial value for Credit Hours TextField
  final TextEditingController creditHoursController;

  Course({this.grade = 'A', double initialCreditHours = 3.0})
      : creditHours = initialCreditHours,
  // Initialize the controller with the default credit hours value
        creditHoursController = TextEditingController(text: initialCreditHours.toStringAsFixed(1));
}

class GPAScreen extends StatefulWidget {
  const GPAScreen({super.key});

  @override
  State<GPAScreen> createState() => _GPAScreenState();
}

class _GPAScreenState extends State<GPAScreen> {
  final List<Course> courses = [Course(initialCreditHours: 3.0)];
  double? finalGPA;

  void addCourse() {
    // Add new course with default values
    setState(() => courses.add(Course(initialCreditHours: 3.0)));
  }

  void removeCourse(int index) {
    // Dispose the controller before removing the course to prevent memory leaks
    courses[index].creditHoursController.dispose();
    setState(() => courses.removeAt(index));
  }

  @override
  void dispose() {
    // Dispose all controllers when the screen is disposed
    for (var course in courses) {
      course.creditHoursController.dispose();
    }
    super.dispose();
  }

  double calculateGPA() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (var c in courses) {
      double? gradePoint = c.grade != null ? gradePointMap[c.grade] : null;

      if (gradePoint != null && c.creditHours != null && c.creditHours! > 0) {
        totalPoints += gradePoint * c.creditHours!;
        totalCredits += c.creditHours!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select Grade and enter valid Credit Hours (>0) for all courses.')),
        );
        return -1.0;
      }
    }

    return totalCredits > 0 ? totalPoints / totalCredits : 0;
  }

  // Amazing Advanced Style Display Function
  void _showAdvancedGPADialog(double gpa) {
    String formattedGPA = gpa.toStringAsFixed(2);
    Color gpaColor = Colors.white;
    String message;

    if (gpa >= 3.5) {
      message = 'Excellent Performance! Keep it up. 🚀';
      gpaColor = const Color(0xFF00FF8C); // Bright Green/Teal
    } else if (gpa >= 3.0) {
      message = 'Great Work! You\'re doing well. 👍';
      gpaColor = const Color(0xFF33CCFF); // Bright Blue
    } else if (gpa >= 2.0) {
      message = 'Satisfactory Progress. You can improve! 💪';
      gpaColor = const Color(0xFFFFCC33); // Yellow/Gold
    } else {
      message = 'Needs Improvement. Focus on next semester. 📚';
      gpaColor = const Color(0xFFFF5757); // Red
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1F1231),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C00F0), width: 3),
            boxShadow: [
              BoxShadow(
                color: gpaColor.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 GPA Calculated 🎉',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const Divider(color: Color(0xFF6C00F0), height: 30, thickness: 2),
              Text(
                formattedGPA,
                style: TextStyle(
                  color: gpaColor,
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

  Future<void> saveGPA(double gpa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("lastGPA", gpa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPA Calculator", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C00F0),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1C0C2B), Color(0xFF2A1840)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final c = courses[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C00F0).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Course ${index + 1}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (courses.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      color: Colors.redAccent),
                                  onPressed: () => removeCourse(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Dropdown for Grade Selection
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white54),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: c.grade,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF2A1840),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                items: gradePointMap.keys.map((String grade) {
                                  return DropdownMenuItem<String>(
                                    value: grade,
                                    child: Text('$grade (${gradePointMap[grade]})'),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    c.grade = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // TextField for Credit Hours (now using controller)
                          TextField(
                            // Corrected: Use controller instead of initialValue
                            controller: c.creditHoursController,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              // Update the creditHours property when text changes
                              c.creditHours = double.tryParse(val);
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Credit Hours",
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color.fromRGBO(255, 255, 255, 0.07),
                              prefixIcon: const Icon(Icons.timelapse,
                                  color: Colors.white70),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Add Course Button with White Label
              ElevatedButton.icon(
                onPressed: addCourse,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add Course",
                    style: TextStyle(color: Colors.white)), // Label color is white
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C00F0),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              // Calculate GPA Button with White Label and Advanced Dialog Logic
              ElevatedButton.icon(
                onPressed: () async {
                  double calculatedGpa = calculateGPA();

                  if (calculatedGpa >= 0) {
                    setState(() {
                      finalGPA = calculatedGpa;
                    });
                    await saveGPA(finalGPA!);
                    _showAdvancedGPADialog(finalGPA!);
                  }
                },
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: const Text("Calculate GPA",
                    style: TextStyle(color: Colors.white)), // Label color is white
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}