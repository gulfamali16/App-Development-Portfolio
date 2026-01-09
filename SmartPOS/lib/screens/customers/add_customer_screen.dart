import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';

/// Screen for adding a new customer
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  String _countryCode = '+1';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final customer = CustomerModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : '$_countryCode ${_phoneController.text.trim()}',
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        dateOfBirth: _dateOfBirth?.toIso8601String(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Provider.of<CustomerProvider>(context, listen: false).addCustomer(customer);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Customer added successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to add customer: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getNameInitials() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Customer', style: TextStyle(color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Avatar with Name Initials
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  _getNameInitials(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Customer Name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
              ),
              onChanged: (value) {
                // Update avatar as name is typed
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number with Country Code
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country code dropdown
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _countryCode,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                      DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                      DropdownMenuItem(value: '+92', child: Text('🇵🇰 +92')),
                      DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                      DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                      DropdownMenuItem(value: '+966', child: Text('🇸🇦 +966')),
                      DropdownMenuItem(value: '+86', child: Text('🇨🇳 +86')),
                      DropdownMenuItem(value: '+81', child: Text('🇯🇵 +81')),
                      DropdownMenuItem(value: '+82', child: Text('🇰🇷 +82')),
                      DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _countryCode = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Phone number field
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(Icons.phone, color: AppTheme.textSecondary),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email Address
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Street Address
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.home, color: AppTheme.textSecondary),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // City and Pincode
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'City',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(Icons.location_city, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(Icons.pin_drop, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date of Birth
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primaryGreen,
                          surface: AppTheme.surfaceDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    _dateOfBirth = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: Icon(Icons.cake, color: AppTheme.textSecondary),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Save Customer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
