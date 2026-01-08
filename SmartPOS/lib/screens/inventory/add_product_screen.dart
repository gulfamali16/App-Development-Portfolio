import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product_model.dart';
import '../../utils/validators.dart';

/// Add Product screen
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '10');
  final _imageUrlController = TextEditingController();
  
  String? _selectedCategoryId;
  String _selectedUnitType = 'item';
  double? _projectedMargin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    _priceController.addListener(_calculateMargin);
    _costPriceController.addListener(_calculateMargin);
    _imageUrlController.addListener(() {
      // Rebuild to show/hide image preview
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _calculateMargin() {
    final price = double.tryParse(_priceController.text);
    final costPrice = double.tryParse(_costPriceController.text);
    if (price != null && costPrice != null && price > 0) {
      setState(() {
        _projectedMargin = ((price - costPrice) / price * 100);
      });
    } else {
      setState(() {
        _projectedMargin = null;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final imageUrl = _imageUrlController.text.trim();
      final product = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: _costPriceController.text.isEmpty ? null : double.tryParse(_costPriceController.text),
        quantity: int.parse(_quantityController.text),
        minStock: int.parse(_minStockController.text),
        unitType: _selectedUnitType,
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);
      final success = await provider.createProduct(product);

      if (success && mounted) {
        Fluttertoast.showToast(
          msg: 'Product added successfully',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // Navigate back to products screen with success flag
        Navigator.pop(context, true);
      } else if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to add product',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImageUrlSection(),
            const SizedBox(height: 24),
            _buildSection(
              'Product Details',
              Icons.info_outline,
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Product Name *',
                  hint: 'Enter product name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _skuController,
                  label: 'SKU/Barcode',
                  hint: 'Enter SKU',
                  suffixIcon: Icons.qr_code_scanner,
                ),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter product description',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Category',
              Icons.category_outlined,
              [
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'Select a category',
                      ),
                      dropdownColor: AppTheme.surfaceDark,
                      style: const TextStyle(color: Colors.white),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Category'),
                        ),
                        ...categoryProvider.categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Pricing',
              Icons.attach_money,
              [
                _buildTextField(
                  controller: _priceController,
                  label: 'Selling Price *',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter selling price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _costPriceController,
                  label: 'Cost Price',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
                if (_projectedMargin != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Projected Margin:',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${_projectedMargin!.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Inventory',
              Icons.inventory_2_outlined,
              [
                _buildTextField(
                  controller: _quantityController,
                  label: 'Stock Quantity *',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _minStockController,
                  label: 'Minimum Stock Level *',
                  hint: '10',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter minimum stock level';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedUnitType,
                  decoration: const InputDecoration(
                    labelText: 'Unit Type',
                  ),
                  dropdownColor: AppTheme.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'item', child: Text('Item')),
                    DropdownMenuItem(value: 'weight', child: Text('Weight')),
                    DropdownMenuItem(value: 'volume', child: Text('Volume')),
                    DropdownMenuItem(value: 'box', child: Text('Box')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnitType = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: AppTheme.textSecondary) : null,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildImageUrlSection() {
    final imageUrl = _imageUrlController.text.trim();
    final hasValidUrl = Validators.isValidImageUrl(imageUrl);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image_outlined, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Product Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Image URL Text Field
        TextFormField(
          controller: _imageUrlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Image URL (Optional)',
            hintText: 'https://example.com/image.jpg',
            prefixIcon: Icon(Icons.link, color: AppTheme.textSecondary),
            helperText: 'Enter a valid image URL to display product image',
            helperMaxLines: 2,
          ),
          keyboardType: TextInputType.url,
          maxLines: 2,
        ),
        
        // Image Preview
        if (hasValidUrl) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderDark.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryGreen,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
