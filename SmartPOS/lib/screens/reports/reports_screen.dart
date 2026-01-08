import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/sales_service.dart';
import '../../services/export_service.dart';
import '../../services/report_service.dart';
import '../../utils/format_helper.dart';

/// Reports screen with KPI cards and detailed reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SalesService _salesService = SalesService();
  final ExportService _exportService = ExportService();
  final ReportService _reportService = ReportService();
  String _selectedPeriod = 'This Month';
  double _totalSales = 0.0;
  double _grossProfit = 0.0;
  int _totalOrders = 0;
  double _salesChange = 0.0;
  double _profitChange = 0.0;
  double _ordersChange = 0.0;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
      
      // This month's data
      final thisMonthSales = await _salesService.getSalesTotal(_startDate, _endDate);
      final thisMonthProfit = await _salesService.getGrossProfit(_startDate, _endDate);
      final thisMonthOrders = await _salesService.getOrderCount(_startDate, _endDate);
      
      // Last month's data for comparison
      final lastMonthSales = await _salesService.getSalesTotal(startOfLastMonth, endOfLastMonth);
      final lastMonthProfit = await _salesService.getGrossProfit(startOfLastMonth, endOfLastMonth);
      final lastMonthOrders = await _salesService.getOrderCount(startOfLastMonth, endOfLastMonth);
      
      // Calculate percentage changes - Handle zero case properly
      double salesChange = 0;
      if (lastMonthSales > 0) {
        salesChange = ((thisMonthSales - lastMonthSales) / lastMonthSales) * 100;
      } else if (thisMonthSales > 0) {
        salesChange = 100; // 100% increase if last month was 0
      }
      
      double profitChange = 0;
      if (lastMonthProfit > 0) {
        profitChange = ((thisMonthProfit - lastMonthProfit) / lastMonthProfit) * 100;
      } else if (thisMonthProfit > 0) {
        profitChange = 100;
      }
      
      double ordersChange = 0;
      if (lastMonthOrders > 0) {
        ordersChange = ((thisMonthOrders - lastMonthOrders) / lastMonthOrders.toDouble()) * 100;
      } else if (thisMonthOrders > 0) {
        ordersChange = 100;
      }
      
      setState(() {
        _totalSales = thisMonthSales;
        _grossProfit = thisMonthProfit;
        _totalOrders = thisMonthOrders;
        _salesChange = salesChange;
        _profitChange = profitChange;
        _ordersChange = ordersChange;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: 'Error loading report data: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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
      centerTitle: true,
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
            value: FormatHelper.formatMoney(_totalSales),
            trend: FormatHelper.formatPercentage(_salesChange),
            color: AppTheme.primaryBlue,
            chartData: _generateSampleData(),
            isPositive: _salesChange >= 0,
          ),
          _buildKPICard(
            title: 'Gross Profit',
            value: FormatHelper.formatMoney(_grossProfit),
            trend: FormatHelper.formatPercentage(_profitChange),
            color: AppTheme.primaryGreen,
            chartData: _generateSampleData(),
            isPositive: _profitChange >= 0,
          ),
          _buildKPICard(
            title: 'Total Orders',
            value: _totalOrders.toString(),
            trend: FormatHelper.formatPercentage(_ordersChange),
            color: const Color(0xFF9C27B0),
            chartData: _generateSampleData(),
            isPositive: _ordersChange >= 0,
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
    required bool isPositive,
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
                  color: (isPositive ? AppTheme.primaryGreen : AppTheme.alertRed).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? AppTheme.primaryGreen : AppTheme.alertRed,
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                label: 'Export CSV',
                onTap: () async {
                  try {
                    setState(() => _isLoading = true);
                    final csvData = await _reportService.exportReportToCSV(_startDate, _endDate);
                    
                    // Show CSV data in a dialog or save it
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.surfaceDark,
                          title: const Text('CSV Export', style: TextStyle(color: Colors.white)),
                          content: SingleChildScrollView(
                            child: Text(
                              csvData,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close', style: TextStyle(color: AppTheme.primaryGreen)),
                            ),
                          ],
                        ),
                      );
                      Fluttertoast.showToast(
                        msg: 'CSV exported successfully!',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Fluttertoast.showToast(
                        msg: 'Error: $e',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.email,
                label: 'Email Report',
                onTap: () async {
                  // Show email input dialog
                  final email = await _showEmailDialog();
                  if (email == null || email.isEmpty) return;
                  
                  try {
                    setState(() => _isLoading = true);
                    await _reportService.emailReport(email, _startDate, _endDate);
                    if (mounted) {
                      Fluttertoast.showToast(
                        msg: 'Report ready to email!',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Fluttertoast.showToast(
                        msg: 'Error: $e',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
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

  Future<String?> _showEmailDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Email Report', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter email address',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
