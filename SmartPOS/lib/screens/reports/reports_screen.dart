import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/sales_service.dart';

/// Reports screen with KPI cards and detailed reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SalesService _salesService = SalesService();
  String _selectedPeriod = 'This Month';
  double _totalSales = 0.0;
  double _grossProfit = 0.0;
  int _totalOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get today's sales as sample data
      final todaySales = await _salesService.getTodaysSalesTotal();
      final todayOrders = await _salesService.getTodaysSales();
      
      setState(() {
        _totalSales = todaySales * 30; // Simulate monthly data
        _grossProfit = _totalSales * 0.3; // 30% profit margin
        _totalOrders = todayOrders.length * 30;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryGreen,
              backgroundColor: AppTheme.surfaceDark,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateFilter(),
                  const SizedBox(height: 20),
                  _buildKPICards(),
                  const SizedBox(height: 24),
                  _buildDetailedReportsList(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceDark,
      automaticallyImplyLeading: false,
      title: const Text(
        'Reports',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      elevation: 0,
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: () => _showPeriodSelector(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedPeriod,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildKPICard(
            title: 'Total Sales',
            value: '\$${_totalSales.toStringAsFixed(2)}',
            trend: '+12.5%',
            color: AppTheme.primaryBlue,
            chartData: _generateSampleData(),
          ),
          _buildKPICard(
            title: 'Gross Profit',
            value: '\$${_grossProfit.toStringAsFixed(2)}',
            trend: '+8.3%',
            color: AppTheme.primaryGreen,
            chartData: _generateSampleData(),
          ),
          _buildKPICard(
            title: 'Total Orders',
            value: _totalOrders.toString(),
            trend: '+15.2%',
            color: const Color(0xFF9C27B0),
            chartData: _generateSampleData(),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String trend,
    required Color color,
    required List<FlSpot> chartData,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildReportItem(
          icon: Icons.description,
          iconColor: AppTheme.primaryBlue,
          title: 'Daily Sales Report',
          subtitle: 'Revenue breakdown by hour',
          onTap: () {
            // Navigate to daily sales detail
          },
        ),
        _buildReportItem(
          icon: Icons.inventory_2,
          iconColor: AppTheme.primaryGreen,
          title: 'Stock & Inventory',
          subtitle: 'Low stock alerts: 3 items',
          onTap: () {
            // Navigate to inventory report
          },
        ),
        _buildReportItem(
          icon: Icons.group,
          iconColor: const Color(0xFF9C27B0),
          title: 'Customer Insights',
          subtitle: 'Top purchasing customers',
          onTap: () {
            // Navigate to customer report
          },
        ),
        _buildReportItem(
          icon: Icons.pie_chart,
          iconColor: const Color(0xFFFF9800),
          title: 'Profit & Loss',
          subtitle: 'Net income analysis',
          onTap: () {
            // Navigate to P&L report
          },
        ),
      ],
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.picture_as_pdf,
                label: 'Export PDF',
                onTap: () {
                  // Show coming soon message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export PDF - Coming Soon'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.email,
                label: 'Email Report',
                onTap: () {
                  // Show coming soon message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email Report - Coming Soon'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSampleData() {
    return [
      const FlSpot(0, 1),
      const FlSpot(1, 1.5),
      const FlSpot(2, 1.4),
      const FlSpot(3, 2.0),
      const FlSpot(4, 1.8),
      const FlSpot(5, 2.5),
      const FlSpot(6, 2.3),
    ];
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPeriodOption('Today'),
            _buildPeriodOption('This Week'),
            _buildPeriodOption('This Month'),
            _buildPeriodOption('This Year'),
            _buildPeriodOption('Custom Range'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String period) {
    final isSelected = _selectedPeriod == period;
    return ListTile(
      title: Text(
        period,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryGreen)
          : null,
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        Navigator.pop(context);
        _loadData();
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Filter Options', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Filter options coming soon',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
