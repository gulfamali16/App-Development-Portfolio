import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../config/theme.dart';

class BulkImportProductsScreen extends StatefulWidget {
  const BulkImportProductsScreen({super.key});

  @override
  State<BulkImportProductsScreen> createState() => _BulkImportProductsScreenState();
}

class _BulkImportProductsScreenState extends State<BulkImportProductsScreen> {
  bool _isLoading = false;
  int _importedCount = 0;
  final ProductService _productService = ProductService();

  // ✅ Export Template Excel
  Future<void> _exportTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Products'];
      
      // Add headers
      sheet.appendRow([
        TextCellValue('Name*'),
        TextCellValue('Category'),
        TextCellValue('Barcode/SKU'),
        TextCellValue('Purchase Price'),
        TextCellValue('Selling Price*'),
        TextCellValue('Stock Quantity*'),
        TextCellValue('Min Stock Level'),
        TextCellValue('Description'),
        TextCellValue('Image URL'),
      ]);
      
      // Add example row
      sheet.appendRow([
        TextCellValue('Product Name'),
        TextCellValue('Electronics'),
        TextCellValue('SKU123'),
        TextCellValue('100'),
        TextCellValue('150'),
        TextCellValue('50'),
        TextCellValue('10'),
        TextCellValue('Product description'),
        TextCellValue('https://example.com/image.jpg'),
      ]);
      
      // Save file
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/product_template.xlsx';
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template saved to: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Import Excel File
  Future<void> _importExcel() async {
    setState(() => _isLoading = true);
    _importedCount = 0;
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      
      if (result != null) {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          
          // Skip header row (index 0)
          for (int i = 1; i < sheet.maxRows; i++) {
            try {
              var row = sheet.row(i);
              
              // Validate required fields (Name, Selling Price, Quantity)
              if (row.isEmpty || row[0]?.value == null || row[4]?.value == null || row[5]?.value == null) {
                continue; // Skip invalid rows
              }
              
              final product = ProductModel(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                name: row[0]?.value?.toString() ?? '',
                categoryId: row[1]?.value?.toString(),
                barcode: row[2]?.value?.toString(),
                costPrice: double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0,
                price: double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0,
                quantity: int.tryParse(row[5]?.value?.toString() ?? '0') ?? 0,
                minStock: int.tryParse(row[6]?.value?.toString() ?? '5') ?? 5,
                description: row[7]?.value?.toString(),
                imageUrl: row[8]?.value?.toString(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await _productService.createProduct(product);
              _importedCount++;
            } catch (e) {
              debugPrint('Error importing row $i: $e');
            }
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $_importedCount products!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context, true); // Refresh parent
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Bulk Import Products'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppTheme.primaryGreen)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file, size: 100, color: Colors.blue),
                    const SizedBox(height: 32),
                    const Text(
                      'Bulk Import Products',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1. Export Excel template\n2. Fill product details\n3. Import filled Excel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _exportTemplate,
                        icon: const Icon(Icons.download),
                        label: const Text('1. Export Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _importExcel,
                        icon: const Icon(Icons.upload),
                        label: const Text('2. Import Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
