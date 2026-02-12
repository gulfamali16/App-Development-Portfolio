import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --- Data Model for a single course in the simulation ---
class SimulationCourse {
  String name;
  double creditHours;
  double gradePoint; // chosen/assigned grade point (0.0..4.0)

  SimulationCourse({
    required this.name,
    required this.creditHours,
    this.gradePoint = 0.0,
  });
}

class PredictorScreen extends StatefulWidget {
  const PredictorScreen({super.key});

  @override
  State<PredictorScreen> createState() => _PredictorScreenState();
}

class _PredictorScreenState extends State<PredictorScreen> {
  /// --- Controllers for inputs on this screen ---
  final TextEditingController _currentCGPAController = TextEditingController(); // from SharedPreferences if available
  final TextEditingController _pastCrdHrsController = TextEditingController();
  final TextEditingController _targetCGPAAfterNextSemController = TextEditingController();

  /// --- Core State ---
  List<SimulationCourse> _nextSemesterCourses = [];
  double _crdHrsNextSemester = 0.0;
  double _simulatedSGPA = 0.0;
  double? _requiredSGPAForTarget;
  bool _planComputed = false;
  String? _feasibilityMessage; // shows when target impossible/edge cases

  /// Correct COMSATS Grade Scale (highest -> lowest)
  /// NOTE: labels kept for dropdown; map value is the GPA
  final Map<String, double> _gradePoints = const {
    'A (4.00)': 4.00,
    'A- (3.67)': 3.67,
    'B+ (3.33)': 3.33,
    'B (3.00)': 3.00,
    'B- (2.67)': 2.67,
    'C+ (2.33)': 2.33,
    'C (2.00)': 2.00,
    'D (1.00)': 1.00,
    'F (0.00)': 0.00,
  };

  /// ladder array for optimization (index 0 is highest)
  late final List<double> _ladder = _gradePoints.values.toList()..sort((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _loadSavedGPAQuietly(); // no dialogs on start
  }

  Future<void> _loadSavedGPAQuietly() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Prefer whatever you saved earlier; keep the key names you're using in GPA screen
      // Try both, fallback to null
      final savedCGPA = prefs.getDouble("lastCGPA") ?? prefs.getDouble("currentCGPA");
      if (savedCGPA != null && savedCGPA >= 0 && savedCGPA <= 4.0) {
        _currentCGPAController.text = savedCGPA.toStringAsFixed(2);
      }
    } catch (_) {
      // ignore errors silently — screen stays empty by default
    }
    _recomputeSGPA();
  }

  @override
  void dispose() {
    _currentCGPAController.dispose();
    _pastCrdHrsController.dispose();
    _targetCGPAAfterNextSemController.dispose();
    super.dispose();
  }

  /// --- GPA Helpers ---

  void _recomputeSGPA() {
    double totalQP = 0.0;
    _crdHrsNextSemester = 0.0;
    for (final c in _nextSemesterCourses) {
      totalQP += c.gradePoint * c.creditHours;
      _crdHrsNextSemester += c.creditHours;
    }
    setState(() {
      _simulatedSGPA = _crdHrsNextSemester > 0 ? totalQP / _crdHrsNextSemester : 0.0;
    });
  }

  double? _calcRequiredSGPA() {
    final currentCGPA = double.tryParse(_currentCGPAController.text.trim());
    final pastCrdHrs = double.tryParse(_pastCrdHrsController.text.trim());
    final targetCGPA = double.tryParse(_targetCGPAAfterNextSemController.text.trim());

    // inputs validation
    if (currentCGPA == null ||
        pastCrdHrs == null ||
        targetCGPA == null ||
        currentCGPA < 0 || currentCGPA > 4 ||
        targetCGPA < 0 || targetCGPA > 4 ||
        pastCrdHrs < 0 ||
        _crdHrsNextSemester <= 0) {
      setState(() {
        _feasibilityMessage = 'Please check all inputs (CGPA 0–4, past credits ≥ 0) and add courses.';
        _requiredSGPAForTarget = null;
      });
      return null;
    }

    final totalAfter = pastCrdHrs + _crdHrsNextSemester;
    final reqTotalQP = targetCGPA * totalAfter;
    final currentQP = currentCGPA * pastCrdHrs;
    final needNextQP = reqTotalQP - currentQP;
    final requiredSGPA = needNextQP / _crdHrsNextSemester;

    setState(() {
      _requiredSGPAForTarget = requiredSGPA;
      _feasibilityMessage = null;
    });
    return requiredSGPA;
  }

  /// --- Best-fit grade distribution:
  /// Start with all A (4.0). If currentQP > requiredQP, downgrade the course
  /// that minimally reduces QP until we are just >= requiredQP (or closest).
  void _makePlan() {
    FocusScope.of(context).unfocus();

    final requiredSGPA = _calcRequiredSGPA();
    if (requiredSGPA == null) {
      setState(() {
        _planComputed = false;
      });
      return;
    }

    // If impossible in one semester:
    if (requiredSGPA > 4.0 + 1e-9) {
      // set best possible (all As) so user sees "closest"
      setState(() {
        for (final c in _nextSemesterCourses) {
          c.gradePoint = 4.0;
        }
        _planComputed = true;
        _feasibilityMessage = 'Target not possible in one semester (required SGPA ${requiredSGPA.toStringAsFixed(2)} > 4.00). '
            'Below is the closest best you can do with highest grades.';
      });
      _recomputeSGPA();
      return;
    }

    // Else feasible: build plan to hit requiredQP
    final double requiredQP = (requiredSGPA.clamp(0.0, 4.0)) * _crdHrsNextSemester;

    // 1) set all to highest grade first
    for (final c in _nextSemesterCourses) {
      c.gradePoint = _ladder.first; // 4.0
    }

    // Sort courses by credit hours desc to keep big ones as high as possible
    _nextSemesterCourses.sort((a, b) => b.creditHours.compareTo(a.creditHours));

    double currentQP = _nextSemesterCourses.fold(0.0, (s, c) => s + c.gradePoint * c.creditHours);

    // If we are already under (shouldn't happen since all A) — just accept
    if (currentQP <= requiredQP + 1e-6) {
      setState(() {
        _planComputed = true;
        _feasibilityMessage = null;
      });
      _recomputeSGPA();
      return;
    }

    // 2) While we’re above the needed QP, lower grades in the gentlest steps
    // Greedy: in each iteration, choose the downgrade that reduces QP just enough.
    const double eps = 1e-6;
    int safety = 10000; // safety to avoid infinite loops

    // Track each course index in ladder
    final Map<SimulationCourse, int> ladderIndex = {
      for (final c in _nextSemesterCourses) c: 0, // all at 4.0 initially (index 0)
    };

    while (currentQP - requiredQP > eps && safety-- > 0) {
      double gap = currentQP - requiredQP;

      // Find the smallest downgrade (deltaQP) that is >= gap OR the minimal overall if none cover gap
      SimulationCourse? bestCourse;
      double bestDelta = double.infinity;
      int bestNextIdx = -1;

      for (final c in _nextSemesterCourses) {
        final idx = ladderIndex[c]!;
        if (idx >= _ladder.length - 1) continue; // already at lowest

        final nextIdx = idx + 1;
        final from = _ladder[idx];
        final to = _ladder[nextIdx];
        final deltaQP = (from - to) * c.creditHours; // QP reduction if we drop one step

        // Prefer the smallest delta that still clears the gap
        if (deltaQP >= gap - eps) {
          if (deltaQP < bestDelta) {
            bestDelta = deltaQP;
            bestCourse = c;
            bestNextIdx = nextIdx;
          }
        } else {
          // Keep track of the smallest delta overall in case nothing clears the whole gap
          if (bestCourse == null && deltaQP < bestDelta) {
            bestDelta = deltaQP;
            bestCourse = c;
            bestNextIdx = nextIdx;
          }
        }
      }

      if (bestCourse == null) {
        // no further downgrades possible
        break;
      }

      // Apply downgrade
      ladderIndex[bestCourse] = bestNextIdx;
      bestCourse.gradePoint = _ladder[bestNextIdx];
      currentQP -= bestDelta;
    }

    setState(() {
      _planComputed = true;
      _feasibilityMessage = null;
    });
    _recomputeSGPA();
  }

  /// Helpers
  String _labelForGpa(double g) {
    // find closest label by exact value; if not found (floating issues), choose nearest
    for (final e in _gradePoints.entries) {
      if ((e.value - g).abs() < 1e-9) return e.key;
    }
    // nearest fallback
    final closest = _gradePoints.entries.reduce((a, b) =>
    (a.value - g).abs() <= (b.value - g).abs() ? a : b);
    return closest.key;
  }

  /// --- UI ---

  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: const Color(0xFF6C00F0)),
            filled: true,
            fillColor: const Color(0xFF1E1033),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          onChanged: (_) {
            // whenever inputs change, clear old plan
            setState(() {
              _planComputed = false;
              _feasibilityMessage = null;
              _requiredSGPAForTarget = null;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildCourseTile(SimulationCourse course, int index) {
    return Card(
      color: const Color(0xFF1E1033),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: course.name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => course.name = v,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
              onPressed: () {
                setState(() {
                  _nextSemesterCourses.removeAt(index);
                  _planComputed = false;
                  _feasibilityMessage = null;
                  _requiredSGPAForTarget = null;
                  _recomputeSGPA();
                });
              },
            ),
          ]),
          const Divider(color: Colors.white10, height: 10),
          Row(children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller:
                TextEditingController(text: course.creditHours.toStringAsFixed(1)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'CrdHrs',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onChanged: (v) {
                  final val = double.tryParse(v) ?? 0.0;
                  course.creditHours = val.clamp(0.0, 30.0);
                  _planComputed = false;
                  _feasibilityMessage = null;
                  _requiredSGPAForTarget = null;
                  _recomputeSGPA();
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gradePoints.entries
                    .firstWhere(
                      (e) => (e.value - course.gradePoint).abs() < 1e-9,
                  orElse: () => const MapEntry('F (0.00)', 0.0),
                )
                    .key,
                decoration: const InputDecoration(
                  labelText: 'Target Grade (optional)',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                dropdownColor: const Color(0xFF1E1033),
                style: const TextStyle(color: Colors.white),
                items: _gradePoints.keys
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  course.gradePoint = _gradePoints[val]!;
                  _planComputed = false;
                  _feasibilityMessage = null;
                  _requiredSGPAForTarget = null;
                  _recomputeSGPA();
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _sgpaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1033),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C00F0), width: 2),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("SGPA (Simulated)",
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text(_simulatedSGPA.toStringAsFixed(2),
            style: const TextStyle(
                color: Color(0xFF00FF8C), fontSize: 28, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _resultPanel() {
    if (!_planComputed && _requiredSGPAForTarget == null && _feasibilityMessage == null) {
      return const SizedBox.shrink();
    }

    final required = _requiredSGPAForTarget;
    final bool feasible = required != null && required <= 4.0 + 1e-9;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1033),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: feasible ? const Color(0xFF00FF8C) : Colors.amber,
          width: 1.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          feasible ? 'Plan Summary' : 'Best Possible (One Semester)',
          style: TextStyle(
            color: feasible ? const Color(0xFF00FF8C) : Colors.amber,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (required != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Required SGPA this semester:',
                  style: TextStyle(color: Colors.white70)),
              Text(required.clamp(0, 4.0).toStringAsFixed(2),
                  style: const TextStyle(
                      color: Color(0xFF33CCFF),
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Suggested plan SGPA:',
                style: TextStyle(color: Colors.white70)),
            Text(_simulatedSGPA.toStringAsFixed(2),
                style: TextStyle(
                    color: feasible ? const Color(0xFF00FF8C) : Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        if (_feasibilityMessage != null) ...[
          const SizedBox(height: 10),
          Text(_feasibilityMessage!,
              style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 12),
        const Text('Suggested Grades:',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ..._nextSemesterCourses.map((c) => Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${c.name} (${c.creditHours.toStringAsFixed(1)} CrH): ${_labelForGpa(c.gradePoint)}',
            style: const TextStyle(color: Colors.white70),
          ),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool essentialMissing = _currentCGPAController.text.isEmpty ||
        _pastCrdHrsController.text.isEmpty ||
        _targetCGPAAfterNextSemController.text.isEmpty;
    final bool coursesMissing = _nextSemesterCourses.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0B021B),
      appBar: AppBar(
        title: const Text("CGPA Planner & Predictor", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C00F0),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Current Academic Status",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 10),

          _buildInputField(
            title: "Your Current CGPA",
            controller: _currentCGPAController,
            hint: "e.g., 3.25",
            icon: Icons.school,
            description: "Your overall CGPA before this semester (prefilled if saved).",
          ),
          const SizedBox(height: 16),

          _buildInputField(
            title: "Total Past Credit Hours",
            controller: _pastCrdHrsController,
            hint: "e.g., 48.0",
            icon: Icons.history_edu,
            description: "Credit hours already completed that formed your current CGPA.",
          ),

          const SizedBox(height: 22),

          const Text("Next Semester Goal",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 10),

          _buildInputField(
            title: "Target CGPA After Next Semester",
            controller: _targetCGPAAfterNextSemController,
            hint: "e.g., 3.60",
            icon: Icons.flag,
            description: "Overall CGPA you want right after this one semester.",
          ),

          const SizedBox(height: 30),

          const Text("Courses for Next Semester",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 10),

          _sgpaCard(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 10),
            child: Text(
              'Total planned credits: ${_crdHrsNextSemester.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),

          ..._nextSemesterCourses.asMap().entries
              .map((e) => _buildCourseTile(e.value, e.key))
              .toList(),

          Center(
            child: Column(children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _nextSemesterCourses.add(SimulationCourse(name: 'Subject', creditHours: 3.0));
                    _planComputed = false;
                    _recomputeSGPA();
                  });
                },
                icon: const Icon(Icons.add_circle, color: Color(0xFF6C00F0)),
                label: const Text('Add Course (3 CrH)',
                    style: TextStyle(color: Color(0xFF6C00F0), fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _nextSemesterCourses.add(SimulationCourse(name: 'Major Subject', creditHours: 4.0));
                    _planComputed = false;
                    _recomputeSGPA();
                  });
                },
                icon: const Icon(Icons.add_circle, color: Color(0xFF6C00F0)),
                label: const Text('Add Major (4 CrH)',
                    style: TextStyle(color: Color(0xFF6C00F0), fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton.icon(
              onPressed: (essentialMissing || coursesMissing) ? null : _makePlan,
              icon: const Icon(Icons.auto_fix_high, color: Colors.white),
              label: const Text("Plan Grades to Hit Target",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C00F0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: Colors.grey.shade700,
              ),
            ),
          ),

          if (essentialMissing || coursesMissing) ...[
            const SizedBox(height: 12),
            const Text(
              "❗️ Please enter Current CGPA, Past Credit Hours, Target CGPA, and add at least one course.",
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],

          _resultPanel(),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
