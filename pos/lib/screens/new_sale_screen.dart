import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_line.dart';
import '../services/product_service.dart';
import 'checkout_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _productSvc = ProductService();
  final _searchCtrl = TextEditingController();

  // all inventory to search
  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];

  // cart lines keyed by product id
  final Map<int, CartLine> _cart = {};

  bool _loading = true;
  static const double _taxRate = 0.08; // 8%

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final list = await _productSvc.getAll();
    setState(() {
      _allProducts = list;
      _searchResults = list;
      _loading = false;
    });
  }

  void _onSearch(String q) {
    q = q.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _searchResults = List.from(_allProducts);
      } else {
        _searchResults = _allProducts.where((p) {
          return p.name.toLowerCase().contains(q) ||
              (p.category ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _addToCart(ProductModel p) {
    final key = p.id ?? p.hashCode;
    setState(() {
      final line = _cart[key];
      if (line == null) {
        _cart[key] = CartLine(product: p, qty: 1);
      } else {
        line.qty++;
      }
    });
  }

  void _incQty(int key) {
    setState(() => _cart[key]?.qty++);
  }

  void _decQty(int key) {
    setState(() {
      final line = _cart[key];
      if (line == null) return;
      if (line.qty > 1) {
        line.qty--;
      } else {
        _cart.remove(key);
      }
    });
  }

  void _removeLine(int key) {
    setState(() => _cart.remove(key));
  }

  double get _subtotal {
    double s = 0;
    for (final line in _cart.values) {
      s += (line.product.price * line.qty);
    }
    return s;
  }

  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6), // background-light
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32), // primary
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        title: const Text('New Sale', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      // Search + Cart
      body: Column(
        children: [
          // Search bar (green-tinted like your mock)
          Container(
            color: const Color(0xFFF6F8F6),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // cart-background
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
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search for products...',
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

          // Product suggestions (tap to add)
          if (!_loading)
            SizedBox(
              height: 86,
              child: _searchResults.isEmpty
                  ? const Center(child: Text('No products'))
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _searchResults.length > 20 ? 20 : _searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = _searchResults[i];
                  return _SuggestionChip(
                    product: p,
                    onTap: () => _addToCart(p),
                  );
                },
              ),
            )
          else
            const LinearProgressIndicator(minHeight: 2),

          // Cart list
          Expanded(
            child: Container(
              color: const Color(0xFFE8F5E9), // cart-background
              child: _cart.isEmpty
                  ? const _EmptyCart()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
                itemCount: _cart.length,
                itemBuilder: (_, idx) {
                  final key = _cart.keys.elementAt(idx);
                  final line = _cart[key]!;
                  return _CartTile(
                    line: line,
                    onInc: () => _incQty(key),
                    onDec: () => _decQty(key),
                    onRemove: () => _removeLine(key),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Totals + checkout (sticky)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Totals block (on green card like mock)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _row('Subtotal', _subtotal),
                  const SizedBox(height: 4),
                  _row('Taxes (8%)', _tax),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _row('Total', _total, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784), // button-color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _cart.isEmpty
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        lines: _cart.values.toList(growable: false),
                        subtotal: _subtotal,
                        tax: _tax,
                        total: _total,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
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

class _SuggestionChip extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const _SuggestionChip({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            _Thumb(imagePath: product.imagePath, name: product.name),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Rs ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  if ((product.category ?? '').isNotEmpty)
                    Text(product.category!,
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('+ Add',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
            )
          ],
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartLine line;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  const _CartTile({
    required this.line,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // card bg
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          _Thumb(imagePath: p.imagePath, name: p.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Rs ${p.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF638865))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _qtyBtn('-', onDec),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 26,
                  child: Text(
                    '${line.qty}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              _qtyBtn('+', onInc),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.black45),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final r = BorderRadius.circular(10);
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: r,
          child: Image.file(file, width: 56, height: 56, fit: BoxFit.cover),
        );
      } else if (imagePath!.startsWith('http')) {
        return ClipRRect(
          borderRadius: r,
          child: Image.network(imagePath!, width: 56, height: 56, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(name)),
        );
      }
    }
    return _fallback(name);
  }

  Widget _fallback(String name) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(initials,
          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_basket_outlined, size: 72, color: Colors.black38),
            SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Search and tap a product to add it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
