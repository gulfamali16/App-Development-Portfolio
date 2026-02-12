import 'package:flutter/material.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/add_customer_screen.dart';
import 'screens/new_sale_screen.dart';
import 'screens/products_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/receipt_screen.dart';

import 'models/cart_line.dart'; // used by ReceiptScreen args

void main() {
  runApp(const GreenFreshPOSApp());
}

class GreenFreshPOSApp extends StatelessWidget {
  const GreenFreshPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Fresh POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFF81C784),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        fontFamily: 'WorkSans',
        useMaterial3: true,
      ),

      // Start from the Login Screen
      initialRoute: '/login',

      // ✅ All named routes (exactly matching dashboard)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/newSale': (context) => const NewSaleScreen(),

        // ✅ Customer routes
        '/customers_screen': (context) => const CustomersScreen(),
        '/add_customer_screen': (context) => const AddCustomerScreen(),

        // ✅ Products
        '/products': (context) => const ProductsScreen(),
        '/add_product_screen': (context) => const AddProductScreen(),

        // ✅ Payments & Reports
        '/payments_screen': (context) => const PaymentsScreen(),

        // ✅ Settings
        '/settings': (context) => const SettingsScreen(),
      },

      // ✅ Dynamic route for Receipt Screen
      onGenerateRoute: (settings) {
        if (settings.name == '/receipt') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            try {
              final lines = (args['lines'] as List).cast<CartLine>();
              return MaterialPageRoute(
                builder: (_) => ReceiptScreen(
                  customerName: args['customerName'] as String,
                  customerPhone: args['customerPhone'] as String?,
                  dateTime: args['dateTime'] as DateTime,
                  lines: lines,
                  subtotal: args['subtotal'] as double,
                  tax: args['tax'] as double,
                  total: args['total'] as double,
                  isCredit: args['isCredit'] as bool,
                ),
              );
            } catch (e) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('⚠️ Invalid arguments passed to /receipt')),
                ),
              );
            }
          } else {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('⚠️ No arguments provided for /receipt')),
              ),
            );
          }
        }
        return null;
      },

      // ✅ Catch unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('❌ Route not found')),
        ),
      ),
    );
  }
}
