import 'package:flutter/material.dart';
// Assuming these imports lead to the files you've created/modified
import 'screens/home_screen.dart';
import 'screens/gpa_screen.dart';
import 'screens/cgpa_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/predictor_screen.dart';

void main() {
  runApp(const CGPACalculatorApp());
}

class CGPACalculatorApp extends StatelessWidget {
  const CGPACalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COMSATS CGPA Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C00F0),
          secondary: const Color(0xFFE8EAF6),
          surface: const Color(0xFF180F23),
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF180F23),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodySmall: TextStyle(color: Colors.white70),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // FIX: Start on the Home screen (index 0)
  int _selectedIndex = 0;

  // List of screens: PredictorScreen is at index 3
  final List<Widget> _screens = const [
    HomeScreen(),
    GPAScreen(),
    CGPAScreen(),
    PredictorScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF180F23),
        selectedItemColor: const Color(0xFF6C00F0),
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'GPA'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'CGPA'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_alt), label: 'Predictor'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}