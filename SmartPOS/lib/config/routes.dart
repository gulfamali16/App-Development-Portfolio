import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';

/// App routes configuration
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String addProduct = '/add-product';
  static const String editProduct = '/edit-product';
  static const String categories = '/categories';
  static const String addCategory = '/add-category';
  static const String stockIn = '/stock-in';
  static const String stockOut = '/stock-out';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case products:
      case productDetail:
      case addProduct:
      case editProduct:
      case categories:
      case addCategory:
      case stockIn:
      case stockOut:
        // Placeholder for screens not yet implemented
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? 'Screen')),
            body: Center(
              child: Text('${settings.name} - Coming Soon'),
            ),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
