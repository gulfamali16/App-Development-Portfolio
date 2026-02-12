import 'dart:io';
import 'package:flutter/material.dart';

import '../services/customer_service.dart';
import '../services/database_service.dart';               // ✅ DB createSale()
import '../models/customer_model.dart';
import '../models/cart_line.dart';                       // ✅ shared CartLine model
import 'add_customer_screen.dart';
import 'receipt_screen.dart';                           // ✅ navigate after successful sale

class CheckoutScreen extends StatefulWidget {
  final List<CartLine> lines;
  final double subtotal;
  final double tax;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _svc = CustomerService();
  final _searchCtrl = TextEditingController();
  List<CustomerModel> _all = [];
  List<CustomerModel> _filtered = [];
  bool _loading = true;

  // UI state
  bool _existingTab = true; // true = existing customers view
  CustomerModel? _selected;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers([String? q]) async {
    setState(() => _loading = true);
    final list = await _svc.getAll(search: q);
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _onSearch(String q) {
    q = q.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_all);
      } else {
        _filtered = _all.where((c) {
          return c.name.toLowerCase().contains(q) ||
              (c.phone ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Color _balColor(double bal) =>
      bal < 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

  Future<void> _openAddCustomer() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );
    if (added == true) {
      await _loadCustomers(_searchCtrl.text);
      if (_all.isNotEmpty) {
        setState(() => _selected = _all.last);
      }
    }
    // stay here (checkout) as requested
  }

  /// ✅ Handle sale creation and navigation to ReceiptScreen
  Future<void> _handleSale({required bool payLater}) async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    try {
      // Ensure products have IDs (must be saved in inventory)
      for (final l in widget.lines) {
        if (l.product.id == null) {
          throw Exception('Product "${l.product.name}" has no ID. Save product to DB before sale.');
        }
      }

      final paymentMethod = payLater ? 'pay_later' : 'cash';
      final isPaid = !payLater;

      // Prepare items structure for DB
      final items = widget.lines.map((l) => {
        'productId': l.product.id!,
        'qty': l.qty,
        'price': l.product.price,
      }).toList();

      // Persist sale + items (also adjusts stock and, if pay_later, updates customer.balance)
      final saleId = await DatabaseService.createSale(
        customerId: _selected!.id,
        subtotal: widget.subtotal,
        tax: widget.tax,
        total: widget.total,
        paymentMethod: paymentMethod,
        isPaid: isPaid,
        items: items,
      );
      debugPrint('Sale created with ID: $saleId');

      // Navigate to Receipt (replace Checkout)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              customerName: _selected!.name,
              customerPhone: _selected!.phone,
              dateTime: DateTime.now(),
              lines: widget.lines,
              subtotal: widget.subtotal,
              tax: widget.tax,
              total: widget.total,
              isCredit: payLater,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete sale: $e')),
        );
      }
    }
  }

  void _buyNow() => _handleSale(payLater: false);
  void _payLater() => _handleSale(payLater: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // back to New Sale
          tooltip: 'Back to New Sale',
        ),
        title: const Text(
          'Customer Selection for Sale',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Toggle buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _existingTab ? const Color(0xFF2E7D32) : Colors.white,
                        foregroundColor:
                        _existingTab ? Colors.white : const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: _existingTab ? 1 : 0,
                      ),
                      onPressed: () => setState(() => _existingTab = true),
                      child: const Text(
                        'Select Existing Customer',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                        _existingTab ? Colors.white : const Color(0xFF2E7D32),
                        foregroundColor:
                        _existingTab ? const Color(0xFF2E7D32) : Colors.white,
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        setState(() => _existingTab = false);
                        await _openAddCustomer();
                        // After adding, return to existing list
                        setState(() => _existingTab = true);
                      },
                      child: const Text(
                        'Add New Customer',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search only in existing tab
          if (_existingTab)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Color(0xFF638865)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) {
                          _onSearch(v);
                          if (_selected != null) {
                            setState(() => _selected = null);
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by name or phone number',
                          hintStyle: TextStyle(color: Color(0xFF638865)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

          // Customer list
          Expanded(
            child: Container(
              color: Colors.white,
              child: _existingTab
                  ? (_loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? const _EmptyCustomers()
                  : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFE0E0E0),
                ),
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  final isSelected = _selected?.id == c.id;
                  final balText = 'Rs ${c.balance.toStringAsFixed(2)}';
                  final hasPending = c.balance < 0;
                  return InkWell(
                    onTap: () => setState(() => _selected = c),
                    child: Container(
                      color: isSelected
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _Avatar(
                            imagePath: c.imagePath,
                            name: c.name,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasPending
                                      ? 'Current Balance'
                                      : 'No outstanding balance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasPending
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            balText,
                            style: TextStyle(
                              color: _balColor(c.balance),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ))
                  : const SizedBox(),
            ),
          ),
        ],
      ),

      // Totals + actions
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Totals block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _row('Subtotal', widget.subtotal),
                  const SizedBox(height: 4),
                  _row('Taxes (8%)', widget.tax),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _row('Total', widget.total, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784), // Buy Now
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selected == null ? null : _buyNow,
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        foregroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selected == null ? null : _payLater,
                      child: const Text(
                        'Pay Later',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF638865), fontSize: 14)),
        Text('Rs ${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  const _Avatar({required this.imagePath, required this.name});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final f = File(imagePath!);
      if (f.existsSync()) {
        return CircleAvatar(radius: 28, backgroundImage: FileImage(f));
      } else if (imagePath!.startsWith('http')) {
        return CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE8F5E9),
          backgroundImage: NetworkImage(imagePath!),
        );
      }
    }
    final initials =
    name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFE8F5E9),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.people_outline, size: 64, color: Colors.black38),
            SizedBox(height: 10),
            Text('No customers found', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text(
              'Tap “Add New Customer” above to create one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
