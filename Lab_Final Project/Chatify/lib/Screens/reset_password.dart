import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String userEmail;

  const ResetPasswordScreen({super.key, required this.userEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate password reset process
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Navigate to login screen
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF128C7E);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: SizedBox(
            width: 420,
            child: Column(
              children: [
                // Header Section
                Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111717),
                        fontFamily: 'Plus Jakarta Sans',
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Create a new, strong password for your account.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFF8BABA7) : const Color(0xFF648783),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Form Section
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Password Field
                      _buildPasswordField(
                        controller: _passwordController,
                        hintText: 'New Password',
                        isDark: isDark,
                        isVisible: _isPasswordVisible,
                        onToggleVisibility: _togglePasswordVisibility,
                        validator: _validatePassword,
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm New Password',
                        isDark: isDark,
                        isVisible: _isConfirmPasswordVisible,
                        onToggleVisibility: _toggleConfirmPasswordVisibility,
                        validator: _validateConfirmPassword,
                      ),

                      const SizedBox(height: 24),

                      // Reset Password Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: primaryColor.withOpacity(0.2),
                            animationDuration: const Duration(milliseconds: 300),
                          ).copyWith(
                            overlayColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return primaryColor.withOpacity(0.8);
                                } else if (states.contains(MaterialState.hovered)) {
                                  return primaryColor.withOpacity(0.9);
                                }
                                return null;
                              },
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2C2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D3B) : const Color(0xFFDCE5E4),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.lock,
            size: 24,
            color: isDark ? const Color(0xFF648783) : const Color(0xFF648783),
          ),
          suffixIcon: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              size: 20,
              color: isDark ? const Color(0xFF648783) : const Color(0xFF648783),
            ),
          ),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF648783) : const Color(0xFF648783),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'Plus Jakarta Sans',
          ),
          errorStyle: const TextStyle(
            fontSize: 12,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF111717),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Plus Jakarta Sans',
        ),
        validator: validator,
      ),
    );
  }
}
