import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Global helper function to determine card style based on score ---
Map<String, dynamic> _getScoreStyle(double? score, String type) {
  if (score == null) {
    return {
      'message': 'Calculate your $type to see the status.',
      'color': Colors.grey.shade600,
      'emoji': '🤷‍♂️',
    };
  } else if (score >= 3.5) {
    return {
      'message': 'Excellent Performance! Keep it up. 🚀',
      'color': const Color(0xFF00FF8C), // Bright Green/Teal
      'emoji': '🚀',
    };
  } else if (score >= 3.0) {
    return {
      'message': 'Great Work! You\'re doing well. 👍',
      'color': const Color(0xFF33CCFF), // Bright Blue
      'emoji': '👍',
    };
  } else if (score >= 2.0) {
    return {
      'message': 'Satisfactory Progress. You can improve! 💪',
      'color': const Color(0xFFFFCC33), // Yellow/Gold
      'emoji': '💪',
    };
  } else {
    return {
      'message': 'Needs Improvement. Focus on next semester. 📚',
      'color': const Color(0xFFFF5757), // Red
      'emoji': '📚',
    };
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? lastGPA;
  double? lastCGPA;

  // UPDATED: The exact COMSATS Grading Scale data provided by the user
  final List<Map<String, String>> gradingScale = [
    {'marks': '85% and above', 'grade': 'A', 'gpa': '4.00'},
    {'marks': '80 – 84%', 'grade': 'A-', 'gpa': '3.66'},
    {'marks': '75 – 79%', 'grade': 'B+', 'gpa': '3.33'},
    {'marks': '71 – 74%', 'grade': 'B', 'gpa': '3.00'},
    {'marks': '68 – 70%', 'grade': 'B-', 'gpa': '2.66'},
    {'marks': '64 – 67%', 'grade': 'C+', 'gpa': '2.33'},
    {'marks': '61 – 63%', 'grade': 'C', 'gpa': '2.00'},
    {'marks': '58 – 60%', 'grade': 'C-', 'gpa': '1.66'},
    {'marks': '54 – 57%', 'grade': 'D+', 'gpa': '1.30'},
    {'marks': '50 – 53%', 'grade': 'D', 'gpa': '1.00'},
    {'marks': 'Below 50%', 'grade': 'F', 'gpa': '0.00'},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Key must be correct to load data saved from CGPA screen
      lastGPA = prefs.getDouble("lastGPA");
      lastCGPA = prefs.getDouble("lastCGPA");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B021B),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "COMSATS Academic Tracker",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // --- CGPA Card (Stylized Display) ---
            _advancedScoreCard(
              title: "Cumulative GPA (CGPA)",
              score: lastCGPA,
              icon: Icons.auto_graph,
            ),
            const SizedBox(height: 20),

            // --- GPA Card (Stylized Display) ---
            _advancedScoreCard(
              title: "Last Semester GPA (SGPA)",
              score: lastGPA,
              icon: Icons.timeline,
            ),
            const SizedBox(height: 30),

            // --- COMSATS Grading System Card (UPDATED) ---
            _gradingSystemCard(),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Navigate to calculation screen using your app's navigation."),
                    ),
                  );
                },
                icon: const Icon(Icons.calculate, color: Colors.white),
                label: const Text(
                  "Start New Calculation",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C00F0),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stylized card widget for GPA/CGPA display
  Widget _advancedScoreCard({required String title, required double? score, required IconData icon}) {
    final style = _getScoreStyle(score, title);
    final formattedScore = score?.toStringAsFixed(2) ?? "0.00";
    final isCalculated = score != null;
    final color = isCalculated ? style['color'] : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1033),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Colors.white12),
          Center(
            child: Text(
              formattedScore,
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Center(
            child: Text(
              isCalculated ? "${style['emoji']} ${style['message']}" : style['message'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Card to display the COMSATS Grading System
  Widget _gradingSystemCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1033),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurpleAccent, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.gavel, color: Colors.deepPurpleAccent, size: 24),
              SizedBox(width: 8),
              Text(
                "COMSATS Official Grading Scale",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(color: Colors.deepPurple, height: 16),
          // Table to show the grades
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5), // Marks
                1: FlexColumnWidth(1.5), // Grade
                2: FlexColumnWidth(2.0), // GPA
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
                  children: const [
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("Marks (%)", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("Grade", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("GPA", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                  ],
                ),
                // Data Rows
                ...gradingScale.map((item) {
                  return TableRow(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(item['marks']!, style: const TextStyle(color: Colors.white60))),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(item['grade']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(item['gpa']!, style: const TextStyle(color: Colors.white))),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "*Note: This scale is provided by the user and should be verified with the official university handbook.",
            style: TextStyle(color: Colors.redAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}