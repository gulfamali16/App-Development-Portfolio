import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double todaySales = 0;
  int totalCustomers = 0;
  int pendingPayments = 0;
  int lowStock = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final data = await DatabaseService.getDashboardData();
    setState(() {
      todaySales = data['todaySales'];
      totalCustomers = data['totalCustomers'];
      pendingPayments = data['pendingPayments'];
      lowStock = data['lowStock'];
      isLoading = false;
    });
  }

  String _formatNumber(num value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}K";
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toStringAsFixed(0);
      } else {
        return value.toStringAsFixed(2);
      }
    }
    return value.toString();
  }

  Widget statCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget navTile(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black12)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green[700], size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primary,
        title: const Text("Green Fresh POS"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                statCard("Today's Sales", "Rs ${_formatNumber(todaySales)}"),
                statCard("Total Customers", _formatNumber(totalCustomers)),
              ],
            ),
            Row(
              children: [
                statCard("Pending Payments", _formatNumber(pendingPayments)),
                statCard("Low Stock Alerts", _formatNumber(lowStock)),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Quick Navigation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                navTile(Icons.point_of_sale, "New Sale", () {
                  Navigator.pushNamed(context, '/newSale');
                }),
                navTile(Icons.inventory_2, "Inventory", () {
                  Navigator.pushNamed(context, '/products');
                }),
                navTile(Icons.group, "Customers", () {
                  Navigator.pushNamed(context, '/customers_screen');
                }),
                // Reports button removed
                navTile(Icons.payments, "Payments", () {
                  Navigator.pushNamed(context, '/payments_screen');
                }),
                navTile(Icons.settings, "Settings", () {
                  Navigator.pushNamed(context, '/settings');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
