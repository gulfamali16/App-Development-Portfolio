import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/customer_service.dart';
import '../models/customer_model.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _svc = CustomerService();
  final _picker = ImagePicker();
  String? _imagePath;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    final x = await (camera
        ? _picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : _picker.pickImage(source: ImageSource.gallery, imageQuality: 85));
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await _svc.insert(CustomerModel(
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      balance: 0,          // always 0 initially
      imagePath: _imagePath,
    ));

    if (mounted) Navigator.pop(context, true); // go back to Customers list and refresh
  }

  @override
  Widget build(BuildContext context) {
    // AppBar matches your design: white background, dark text, back button to Customers
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: const Color(0xFF333333),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Add New Customer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar / Image picker card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFE8F5E9),
                  backgroundImage: (_imagePath != null && File(_imagePath!).existsSync())
                      ? FileImage(File(_imagePath!))
                      : null,
                  child: (_imagePath == null || !File(_imagePath!).existsSync())
                      ? const Icon(Icons.person, color: Color(0xFF2E7D32), size: 36)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pick(false),
                        icon: const Icon(Icons.photo),
                        label: const Text('Gallery'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pick(true),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Customer Name',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _name,
                    decoration: _decoration('Enter full name'),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Phone Number',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _decoration('Enter phone number'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bottom action (Save Customer)
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _save,
              child: const Text(
                'Save Customer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
    ),
  );
}
