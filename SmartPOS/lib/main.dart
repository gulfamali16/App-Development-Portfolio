import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/sales_provider.dart';
import 'services/firestore_sync_service.dart';
import 'utils/constants.dart';

/// Main entry point of the Smart POS application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: Firebase initialization requires google-services.json for Android
  // and GoogleService-Info.plist for iOS. See README.md for setup instructions.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue app execution even if Firebase fails (for development without Firebase config)
  }
  
  // Check remember me preference
  final prefs = await SharedPreferences.getInstance();
  final isRemembered = prefs.getBool('remember_me') ?? false;
  final userId = prefs.getString('user_id');
  
  String initialRoute = AppRoutes.splash;
  
  if (isRemembered && userId != null) {
    initialRoute = AppRoutes.home;
    
    // Start auto-sync when app opens with remembered login
    FirestoreSyncService().startAutoSync();
    
    // Download latest data from cloud
    try {
      await FirestoreSyncService().downloadAllFromCloud();
    } catch (e) {
      debugPrint('Error downloading data from cloud: $e');
    }
  }
  
  runApp(MyApp(initialRoute: initialRoute));
}

/// Root widget of the application
class MyApp extends StatelessWidget {
  final String initialRoute;
  
  const MyApp({super.key, this.initialRoute = AppRoutes.splash});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
