import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

/// Signup screen with email and password registration
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  String _currentPassword = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      Fluttertoast.showToast(
        msg: 'Please accept the terms and conditions',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (success && mounted) {
      Fluttertoast.showToast(
        msg: AppConstants.signupSuccess,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted) {
      final error = authProvider.errorMessage ?? AppConstants.authError;
      Fluttertoast.showToast(
        msg: error,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = Validators.checkPasswordStrength(_currentPassword);
    final strengthText = Validators.getPasswordStrengthText(strength);
    
    Color color;
    double progress;
    
    switch (strength) {
      case PasswordStrength.none:
        return const SizedBox.shrink();
      case PasswordStrength.weak:
        color = Colors.red;
        progress = 0.33;
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        progress = 0.66;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        progress = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $strengthText',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details below to create your account',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Name field
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: Validators.validateName,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email field
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: Validators.validateEmail,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: Validators.validatePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        setState(() {
                          _currentPassword = value;
                        });
                      },
                    ),
                    _buildPasswordStrengthIndicator(),
                    const SizedBox(height: 16),
                    
                    // Confirm password field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSignup(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Terms and conditions checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptTerms = !_acceptTerms;
                              });
                            },
                            child: const Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Sign up button
                    CustomButton(
                      text: 'Sign Up',
                      onPressed: _handleSignup,
                      isLoading: authProvider.isLoading,
                    ),
                    const SizedBox(height: 24),
                    
                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.login);
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
