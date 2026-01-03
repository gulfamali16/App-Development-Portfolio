import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/constants.dart';
import '../main_screen.dart';

/// Home screen dashboard for authenticated users (used when navigating directly)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    await Future.wait([
      inventoryProvider.loadDashboardStats(),
      productProvider.loadProducts(),
    ]);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (mounted) {
        Fluttertoast.showToast(
          msg: AppConstants.logoutSuccess,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: const HomeScreenContent(),
    );
  }
}

/// Home screen content widget (used in MainScreen's IndexedStack)
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    await Future.wait([
      inventoryProvider.loadDashboardStats(),
      productProvider.loadProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer3<AuthProvider, InventoryProvider, ProductProvider>(
        builder: (context, authProvider, inventoryProvider, productProvider, child) {
          final user = authProvider.user;
          final stats = inventoryProvider.dashboardStats;
          final lowStockProducts = productProvider.lowStockProducts;

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryGreen,
            backgroundColor: AppTheme.surfaceDark,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, user?.name ?? 'User'),
                  _buildOverviewSection(stats),
                  _buildQuickActions(),
                  if (lowStockProducts.isNotEmpty) _buildLowStockAlert(lowStockProducts.length),
                  _buildRecentActivity(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.alertRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> stats) {
    final todaysSales = stats['todaysSales'] ?? 0.0;
    final totalProducts = stats['totalProducts'] ?? 0;
    final lowStockCount = stats['lowStockCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatCard(
                  'Today\'s Sales',
                  '\$${todaysSales.toStringAsFixed(2)}',
                  Icons.payments,
                  AppTheme.primaryBlue,
                  isGradient: true,
                ),
                _buildStatCard(
                  'Total Products',
                  totalProducts.toString(),
                  Icons.inventory_2,
                  AppTheme.surfaceDark,
                ),
                _buildStatCard(
                  'Low Stock',
                  lowStockCount.toString(),
                  Icons.warning_amber,
                  AppTheme.surfaceDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, {bool isGradient = false}) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGradient ? null : bgColor,
        gradient: isGradient
            ? LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildActionButton(
                'New Sale',
                Icons.point_of_sale,
                AppTheme.primaryGreen,
                isLarge: true,
                onTap: () {
                  // Switch to POS tab (index 2)
                  final mainState = context.findAncestorStateOfType<_MainScreenState>();
                  mainState?.switchTab(2);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Add Product',
                      Icons.add_shopping_cart,
                      AppTheme.surfaceDark,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.addProduct),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Stock In',
                      Icons.add_box,
                      AppTheme.surfaceDark,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.stockIn),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Add Customer',
                      Icons.person_add,
                      AppTheme.surfaceDark,
                      onTap: () => Navigator.pushNamed(context, '/add-customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Payment',
                      Icons.payment,
                      AppTheme.surfaceDark,
                      onTap: () => Navigator.pushNamed(context, '/outstanding-balances'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Orders',
                Icons.receipt_long,
                AppTheme.surfaceDark,
                onTap: () => Navigator.pushNamed(context, '/sales-history'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color bgColor, {bool isLarge = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: isLarge ? 80 : 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bgColor == AppTheme.primaryGreen 
                ? AppTheme.primaryGreen 
                : AppTheme.borderDark.withOpacity(0.5),
            width: bgColor == AppTheme.primaryGreen ? 2 : 1,
          ),
        ),
        child: isLarge
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.backgroundDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: AppTheme.primaryGreen, size: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLowStockAlert(int count) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.products),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.alertRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.alertRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.alertRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: AppTheme.alertRed, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Low Stock Alert',
                    style: TextStyle(
                      color: AppTheme.alertRed,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$count products below minimum stock level',
                    style: TextStyle(
                      color: AppTheme.alertRed.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.alertRed, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Sales',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showComingSoon('View All'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                'No recent sales',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    Fluttertoast.showToast(
      msg: '$feature feature coming soon',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }
}
