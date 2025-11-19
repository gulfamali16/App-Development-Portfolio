import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'pending'; // all | pending | settled
  String _filterDate = 'all';       // all | today | week | month

  bool _loading = true;
  double _totalOutstanding = 0;
  List<Map<String, dynamic>> _rows = [];

  // TextEditingControllers for inline amount entry per customer
  final Map<int, TextEditingController> _amountCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrls.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final total = await DatabaseService.totalOutstanding();
    final customers = await DatabaseService.listCustomersWithBalances(
      search: _searchCtrl.text,
      status: _filterStatus,
    );

    setState(() {
      _totalOutstanding = total;
      _rows = customers;
      _loading = false;

      // maintain amount controllers
      for (final r in _rows) {
        final id = r['id'] as int;
        _amountCtrls.putIfAbsent(id, () => TextEditingController());
      }
    });
  }

  Future<void> _addPayment(int customerId) async {
    final ctrl = _amountCtrls[customerId];
    if (ctrl == null) return;

    final amount = double.tryParse(ctrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount')),
      );
      return;
    }

    await DatabaseService.addCustomerPayment(customerId: customerId, amount: amount);

    // Clear input and reload
    ctrl.clear();
    if (mounted) await _load();
  }

  void _openHistory(int customerId, String customerName) async {
    final ledger = await DatabaseService.customerLedgerHistory(customerId);
    // Show in a simple bottom sheet
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _LedgerSheet(name: customerName, ledger: ledger),
    );
  }

  Color _amountColor(num balance) =>
      balance < 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Payment Record', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.description, color: Colors.white),
            tooltip: 'Export',
          )
        ],
      ),

      body: Column(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Outstanding Balance',
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Rs ${_totalOutstanding.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by customer name or phone',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),

          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(
              children: [
                _chipFilter(
                  label: 'Date: ${_filterDate.toUpperCase()}',
                  onTap: () => _pickDateFilter(),
                  selected: true,
                ),
                const SizedBox(width: 8),
                _chipFilter(
                  label: 'Status: ${_filterStatus.toUpperCase()}',
                  onTap: () => _pickStatusFilter(),
                  selected: false,
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final r = _rows[i];
                  final id = r['id'] as int;
                  final name = (r['name'] as String?) ?? '—';
                  final balance = (r['balance'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  const Text('Credit', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  // Could also show: updatedAt
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  balance < 0 ? '-${balance.abs().toStringAsFixed(2)}' : balance.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: _amountColor(balance),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('Balance: Rs ${balance.abs().toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 36,
                              child: TextField(
                                controller: _amountCtrls[id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Amount',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _addPayment(id),
                                child: const Text('Update', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _openHistory(id, name),
                                child: const Text('History'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _chipFilter({
    required String label,
    required VoidCallback onTap,
    required bool selected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF2E7D32)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : const Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _pickStatusFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                onTap: () => Navigator.pop(context, 'all'),
              ),
              ListTile(
                title: const Text('Pending'),
                onTap: () => Navigator.pop(context, 'pending'),
              ),
              ListTile(
                title: const Text('Settled'),
                onTap: () => Navigator.pop(context, 'settled'),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != _filterStatus) {
      setState(() => _filterStatus = selected);
      _load();
    }
  }

  void _pickDateFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                onTap: () => Navigator.pop(context, 'all'),
              ),
              ListTile(
                title: const Text('Today'),
                onTap: () => Navigator.pop(context, 'today'),
              ),
              ListTile(
                title: const Text('This Week'),
                onTap: () => Navigator.pop(context, 'week'),
              ),
              ListTile(
                title: const Text('This Month'),
                onTap: () => Navigator.pop(context, 'month'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      // You can wire this into filters later by modifying DB queries as needed
      setState(() => _filterDate = selected);
      // Optional: no DB filter applied yet — future enhancement
    }
  }
}

class _LedgerSheet extends StatelessWidget {
  final String name;
  final List<Map<String, dynamic>> ledger;

  const _LedgerSheet({required this.name, required this.ledger});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: ledger.isEmpty
            ? const Center(child: Text('No ledger history found'))
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$name — Ledger', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            ...ledger.map((e) {
              final date = (e['date'] as String?) ?? '';
              final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
              final label = (e['label'] as String?) ?? '—';
              final color = amount < 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label)),
                      Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(width: 12),
                      Text(
                        (amount < 0 ? '-' : '+') + amount.abs().toStringAsFixed(2),
                        style: TextStyle(color: color, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
