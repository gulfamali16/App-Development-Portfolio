import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventory/products_screen.dart';
import '../screens/inventory/add_product_screen.dart';
import '../screens/inventory/edit_product_screen.dart';
import '../screens/inventory/product_detail_screen.dart';
import '../screens/inventory/stock_in_screen.dart';
import '../screens/inventory/stock_out_screen.dart';
import '../screens/inventory/add_category_screen.dart';
import '../screens/inventory/categories_screen.dart';
import '../screens/customers/add_customer_screen.dart';
import '../screens/payments/outstanding_balances_screen.dart';
import '../screens/payments/ledger_adjustment_screen.dart';
import '../screens/sales/sales_history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../models/product_model.dart';

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
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String addCustomer = '/add-customer';
  static const String outstandingBalances = '/outstanding-balances';
  static const String ledgerAdjustment = '/ledger-adjustment';
  static const String salesHistory = '/sales-history';

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
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case products:
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductScreen());
      case editProduct:
        final product = settings.arguments as ProductModel?;
        if (product == null) {
          return _errorRoute('Product data is required');
        }
        return MaterialPageRoute(builder: (_) => EditProductScreen(product: product));
      case productDetail:
        final product = settings.arguments as ProductModel?;
        if (product == null) {
          return _errorRoute('Product data is required');
        }
        return MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product));
      case stockIn:
        return MaterialPageRoute(builder: (_) => const StockInScreen());
      case stockOut:
        return MaterialPageRoute(builder: (_) => const StockOutScreen());
      case addCategory:
        return MaterialPageRoute(builder: (_) => const AddCategoryScreen());
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case addCustomer:
        return MaterialPageRoute(builder: (_) => const AddCustomerScreen());
      case outstandingBalances:
        return MaterialPageRoute(builder: (_) => const OutstandingBalancesScreen());
      case ledgerAdjustment:
        final customerId = settings.arguments as String?;
        if (customerId == null) {
          return _errorRoute('Customer ID is required');
        }
        return MaterialPageRoute(builder: (_) => LedgerAdjustmentScreen(customerId: customerId));
      case salesHistory:
        return MaterialPageRoute(builder: (_) => const SalesHistoryScreen());
      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }
}
