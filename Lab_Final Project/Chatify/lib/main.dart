// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import config
import 'config/supabase_config.dart';

// Import all your screens from the Screens folder
import 'Screens/splash_screen.dart';
import 'Screens/onboarding_screen.dart';
import 'Screens/onboarding_screen2.dart';
import 'Screens/onboarding_screen3.dart';
import 'Screens/login_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/profile_screen.dart';
import 'Screens/calls_screen.dart';
import 'Screens/users_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
  }

  runApp(const ChatiFyApp());
}

class ChatiFyApp extends StatefulWidget {
  const ChatiFyApp({super.key});

  @override
  State<ChatiFyApp> createState() => _ChatiFyAppState();
}

class _ChatiFyAppState extends State<ChatiFyApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  // Listen to auth state changes
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      print('Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn) {
        print('✅ User signed in: ${session?.user.email}');
      } else if (event == AuthChangeEvent.signedOut) {
        print('👋 User signed out');
      }
    });
  }

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

      // Initial route - starts with splash screen
      initialRoute: '/splash',

      // Routes configuration
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding1': (context) => const OnboardingScreen(),
        '/onboarding2': (context) => const ShareMomentsScreen(),
        '/onboarding3': (context) => const SecurityScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile-setup': (context) => const ProfileScreen(isFirstTime: true),
        '/calls': (context) => const CallsScreen(),
        '/users': (context) => const UsersScreen(),
      },

      // Handle routes that require arguments
      onGenerateRoute: (settings) {
        // Handle edit profile route
        if (settings.name == '/edit-profile') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(
              isFirstTime: false,
              initialName: args?['initialName'] ?? '',
              initialStatus: args?['initialStatus'] ?? 'Available',
              initialProfileImage: args?['initialProfileImage'] ?? '',
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

// Navigation helper class
class NavigationHelper {
  // Clear all and go to splash
  static void navigateToSplash(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
  }

  // Navigate to onboarding screens
  static void navigateToOnboarding1(BuildContext context) {
    Navigator.pushNamed(context, '/onboarding1');
  }

  static void navigateToOnboarding2(BuildContext context) {
    Navigator.pushNamed(context, '/onboarding2');
  }

  static void navigateToOnboarding3(BuildContext context) {
    Navigator.pushNamed(context, '/onboarding3');
  }

  // Clear all and go to login
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Navigate to profile setup (first time)
  static void navigateToProfileSetup(BuildContext context) {
    Navigator.pushNamed(context, '/profile-setup');
  }

  // Navigate to edit profile
  static void navigateToEditProfile(
      BuildContext context, {
        required String initialName,
        required String initialStatus,
        required String initialProfileImage,
      }) {
    Navigator.pushNamed(
      context,
      '/edit-profile',
      arguments: {
        'initialName': initialName,
        'initialStatus': initialStatus,
        'initialProfileImage': initialProfileImage,
      },
    );
  }

  // Clear all and go to home
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  // Navigate to calls screen
  static void navigateToCalls(BuildContext context) {
    Navigator.pushNamed(context, '/calls');
  }

  // Navigate to users screen
  static void navigateToUsers(BuildContext context) {
    Navigator.pushNamed(context, '/users');
  }

  // Go back
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}