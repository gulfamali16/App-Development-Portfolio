import 'dart:io';
import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../models/customer_model.dart';
import 'add_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _service = CustomerService();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<CustomerModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String? q]) async {
    setState(() => _loading = true);
    final rows = await _service.getAll(search: q);
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Color _amountColor(double bal) =>
      bal < 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32); // red if negative, else green

  // --------- Edit ----------
  void _openEdit(CustomerModel existing) async {
    final updated = await showModalBottomSheet<CustomerModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CustomerFormSheet(existing: existing),
    );

    if (updated != null) {
      await _service.update(updated.copyWith(
        id: existing.id,
        balance: existing.balance,      // keep same balance
        imagePath: existing.imagePath,  // keep same image
      ));
      _load(_searchCtrl.text);
    }
  }

  // --------- Delete ----------
  Future<void> _confirmDelete(CustomerModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to delete "${c.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.delete(c.id!);
      _load(_searchCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // 🔹 Green header with white back button & title (like other screens)
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: canPop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (canPop) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: const Text('Customers',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => _load(v),
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const _Empty()
                : RefreshIndicator(
              onRefresh: () => _load(_searchCtrl.text),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final c = _items[i];
                  return _CustomerCard(
                    customer: c,
                    onEdit: () => _openEdit(c),
                    onDelete: () => _confirmDelete(c),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Add Customer FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
          if (added == true) _load(_searchCtrl.text);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  Color _amountColor(double bal) =>
      bal < 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.white;
    final low = customer.balance < 0;
    final border = low ? const Color(0xFFD32F2F).withOpacity(.5) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: low ? const Color(0xFFFFEBEE) : cardColor, // light red for negative balance
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          _Avatar(imagePath: customer.imagePath, name: customer.name),
          const SizedBox(width: 12),

          /// LEFT/MIDDLE: Name + Phone (like product name/price area)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  customer.phone ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          /// RIGHT: Balance + vertical edit/delete (mirrors product list)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (low)
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 18),
                  if (low) const SizedBox(width: 4),
                  Text(
                    'Rs ${customer.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: low ? FontWeight.w700 : FontWeight.w600,
                      color: _amountColor(customer.balance),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                    tooltip: 'Edit',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black54),
                    tooltip: 'Delete',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  const _Avatar({required this.imagePath, required this.name});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync()) {
      return CircleAvatar(radius: 28, backgroundImage: FileImage(File(imagePath!)));
    }
    final initials = name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFE8F5E9),
      child: Text(initials,
          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.people_outline, size: 72, color: Colors.black38),
            SizedBox(height: 12),
            Text('No Customers Found', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Add a new customer to get started.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet form for **Edit only**
class _CustomerFormSheet extends StatefulWidget {
  final CustomerModel existing;
  const _CustomerFormSheet({required this.existing});

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = widget.existing.name;
    _phone.text = widget.existing.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = CustomerModel(
      id: widget.existing.id,
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      balance: widget.existing.balance,   // keep balance
      imagePath: widget.existing.imagePath, // keep image
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                const Text('Edit Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Customer Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
