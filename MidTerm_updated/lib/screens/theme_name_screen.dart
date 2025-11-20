import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';
import '../utils/database_helper.dart';

class ThemeNameScreen extends StatefulWidget {
  const ThemeNameScreen({super.key});

  @override
  State<ThemeNameScreen> createState() => _ThemeNameScreenState();
}

class _ThemeNameScreenState extends State<ThemeNameScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  String _selectedTheme = 'light';
  late AnimationController _logoController;
  late Animation<double> _logoAnim;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _logoAnim = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _setTheme(String mode) async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    await themeManager.toggleTheme(mode == 'dark');
    setState(() {
      _selectedTheme = mode;
    });
  }

  void _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    // Mark setup as completed before navigating
    await _dbHelper.markSetupCompleted();

    Navigator.pushReplacementNamed(
      context,
      '/dashboard',
      arguments: name,
    );
  }

  // ... rest of the build method remains the same ...
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF112211) : Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),

            // Animated Logo
            ScaleTransition(
              scale: _logoAnim,
              child: SizedBox(
                height: 120,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Name & Theme Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Enter your name',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF93C893) : Colors.grey,
                      ),
                      filled: true,
                      fillColor:
                      isDark ? const Color(0xFF244724) : const Color(0xFFF0F0F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Theme toggle buttons
                  Row(
                    children: [
                      Expanded(
                        child: _themeOption(
                          'Light Mode',
                          'light',
                          isSelected: _selectedTheme == 'light',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _themeOption(
                          'Dark Mode',
                          'dark',
                          isSelected: _selectedTheme == 'dark',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19E619),
                    foregroundColor:
                    isDark ? const Color(0xFF112211) : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(String label, String value,
      {required bool isSelected, required bool isDark}) {
    return GestureDetector(
      onTap: () => _setTheme(value),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF244724) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF19E619) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}