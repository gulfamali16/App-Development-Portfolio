// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Configuration
import 'config/supabase_config.dart';

// Import all screen files
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/onboarding_screen2.dart';
import 'screens/onboarding_screen3.dart';
import 'screens/login_screen.dart';
import 'screens/create_account.dart';
import 'screens/email_verification.dart';
import 'screens/home_screen.dart';
import 'screens/forget_password.dart';
import 'screens/reset_password.dart';
import 'screens/profile_screen.dart';
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const ChatiFyApp());
}

class ChatiFyApp extends StatelessWidget {
  const ChatiFyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatiFy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF128C7E),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF11211F),
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF128C7E),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,

      // Initial route
      initialRoute: '/splash',

      // Routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/onboarding2': (context) => const ShareMomentsScreen(),
        '/onboarding3': (context) => const SecurityScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile-setup': (context) => const ProfileScreen(isFirstTime: true),
      },

      // Handle routes that require arguments
      onGenerateRoute: (settings) {
        // Handle email verification route
        if (settings.name == '/email-verification') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              userEmail: args['userEmail'],
              isForgotPassword: args['isForgotPassword'] ?? false,
              title: args['title'] ?? 'Verify Your Email',
              subtitle: args['subtitle'] ?? 'Enter the code sent to',
            ),
          );
        }

        // Handle reset password route
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              userEmail: args['userEmail'],
            ),
          );
        }

        return null;
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
    );
  }
}