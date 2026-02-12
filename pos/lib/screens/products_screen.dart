import 'dart:io';
import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../screens/add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _service = ProductService();
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  bool _loading = true;
  List<ProductModel> _all = [];
  List<ProductModel> _filtered = [];
  static const int _lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.getAll();
    setState(() {
      _all = items;
      _filtered = items;
      _loading = false;
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _filtered = List.from(_all);
      }
    });
  }

  void _onSearch(String q) {
    q = q.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.category ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  /// EDIT in a bottom sheet (quick changes)
  void _openEdit(ProductModel existing) async {
    final saved = await showModalBottomSheet<ProductModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ProductFormSheet(existing: existing),
    );
    if (saved != null) {
      await _service.update(saved.copyWith(id: existing.id, imagePath: existing.imagePath));
      _load();
    }
  }

  Future<void> _confirmDelete(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
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
      await _service.delete(p.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: canPop,
        title: const Text('Products', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Search',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (toggle)
          AnimatedCrossFade(
            crossFadeState: _showSearch ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search by name or category',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ),
            secondChild: const SizedBox(height: 0),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const _EmptyProductsMessage()
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = _filtered[i];
                  final low = p.stock < _lowStockThreshold;
                  return _ProductCard(
                    product: p,
                    lowStock: low,
                    onEdit: () => _openEdit(p),
                    onDelete: () => _confirmDelete(p),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Bottom “Add Product” button — opens AddProductScreen properly
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
              if (added == true) _load();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Product',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ... [rest of your _ProductCard, _Thumb, _EmptyProductsMessage, and _ProductFormSheet remain unchanged]

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool lowStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.lowStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.white;
    final border = lowStock ? const Color(0xFFD32F2F).withOpacity(.5) : const Color(0xFFE5E7EB);
    final priceColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: lowStock ? const Color(0xFFFFEBEE) : cardColor, // light red for low stock
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Thumb(imagePath: product.imagePath, name: product.name),
          const SizedBox(width: 12),

          /// LEFT: Name + Price (ONLY — no category)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Rs ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: priceColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          /// RIGHT: Qty + vertical edit/delete (like your HTML)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lowStock)
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 18),
                  if (lowStock) const SizedBox(width: 4),
                  Text(
                    '${product.stock}',
                    style: TextStyle(
                      fontWeight: lowStock ? FontWeight.w700 : FontWeight.w500,
                      color: lowStock ? const Color(0xFFD32F2F) : Colors.black87,
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

class _Thumb extends StatelessWidget {
  final String? imagePath;
  final String name;
  const _Thumb({required this.imagePath, required this.name});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    if (imagePath != null && imagePath!.trim().isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.file(
            file,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    // fallback initials box
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // light green
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2E7D32)),
      ),
    );
  }
}

/// Empty state (message only)
class _EmptyProductsMessage extends StatelessWidget {
  const _EmptyProductsMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_outlined, size: 72, color: Colors.black38),
            SizedBox(height: 12),
            Text('No Products Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            SizedBox(height: 6),
            Text(
              'Tap the “Add Product” button below to add your first item.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet form for **Edit only**
class _ProductFormSheet extends StatefulWidget {
  final ProductModel existing;
  const _ProductFormSheet({required this.existing});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _category = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name.text = e.name;
    _price.text = e.price.toStringAsFixed(2);
    _stock.text = e.stock.toString();
    _category.text = e.category ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _category.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = ProductModel(
      id: widget.existing.id,
      name: _name.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? widget.existing.price,
      stock: int.tryParse(_stock.text.trim()) ?? widget.existing.stock,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      imagePath: widget.existing.imagePath, // keep current image
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
                const Text('Edit Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (Rs)'),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter valid price' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Qty'),
                    validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter valid qty' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category (optional)'),
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


