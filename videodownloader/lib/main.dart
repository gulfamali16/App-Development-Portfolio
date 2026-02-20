import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Ensure native bindings are initialized before calling native code (sqflite, path_provider, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors and prevent silent crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Lock orientation to portrait for stability (must be awaited)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Wrap runApp with runZonedGuarded to catch unhandled async errors
  runZonedGuarded(
    () => runApp(const MyApp()),
    (Object error, StackTrace stack) {
      debugPrint('Unhandled error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFf20d0d),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFf20d0d),
          secondary: Color(0xFFf20d0d),
          surface: Color(0xFF1e1e1e),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}