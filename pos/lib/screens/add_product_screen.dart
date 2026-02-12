import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String? _category;
  String? _imagePath;

  final _picker = ImagePicker();
  final _service = ProductService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final XFile? img = await (fromCamera
        ? _picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : _picker.pickImage(source: ImageSource.gallery, imageQuality: 85));
    if (img != null) {
      setState(() => _imagePath = img.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      name: _nameCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      stock: int.parse(_qtyCtrl.text.trim()),
      category: _category,
      imagePath: _imagePath,
    );

    await _service.insert(product);
    if (context.mounted) Navigator.pop(context, true); // return true to refresh list
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC), // background-light
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: const Color(0xFF111812),
        elevation: 1,
        title: const Text(
          'Add New Product',
          style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // IMAGE PICKER
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imagePath == null
                          ? const Icon(Icons.image_outlined, size: 36, color: Color(0xFF2E7D32))
                          : Image.file(File(_imagePath!), fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Product Image',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(false),
                                icon: const Icon(Icons.photo),
                                label: const Text('Gallery'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(true),
                                icon: const Icon(Icons.photo_camera),
                                label: const Text('Camera'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Optional — JPG/PNG',
                              style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NAME
              _LabeledField(
                label: 'Product Name',
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: _decoration(),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter product name' : null,
                ),
              ),
              const SizedBox(height: 16),

              // PRICE + QTY
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Price',
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _decoration(hint: '0.00'),
                        validator: (v) =>
                        (double.tryParse((v ?? '').trim()) == null) ? 'Invalid price' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Quantity',
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration(hint: '0'),
                        validator: (v) =>
                        (int.tryParse((v ?? '').trim()) == null) ? 'Invalid qty' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CATEGORY
              _LabeledField(
                label: 'Category',
                child: DropdownButtonFormField<String>(
                  value: _category,
                  items: const [
                    DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                    DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                    DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                    DropdownMenuItem(value: 'Bakery', child: Text('Bakery')),
                    DropdownMenuItem(value: 'Meat', child: Text('Meat')),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                  decoration: _decoration(hint: 'Select category'),
                ),
              ),

              const SizedBox(height: 24),

              // SAVE
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _save,
                  child: const Text(
                    'Save Product',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111812))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
