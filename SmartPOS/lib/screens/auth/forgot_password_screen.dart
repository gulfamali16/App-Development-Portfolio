import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

/// Forgot password screen for password reset
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
      Fluttertoast.showToast(
        msg: AppConstants.resetPasswordSuccess,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else if (mounted) {
      final error = authProvider.errorMessage ?? 'Failed to send reset email';
      Fluttertoast.showToast(
        msg: error,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
                    
                    // Icon
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      _emailSent ? 'Email Sent!' : 'Reset Password',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      _emailSent
                          ? 'We have sent a password reset link to your email. Please check your inbox and follow the instructions.'
                          : 'Enter your email address and we will send you a link to reset your password.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    if (!_emailSent) ...[
                      // Email field
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: Validators.validateEmail,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleResetPassword(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Reset password button
                      CustomButton(
                        text: 'Send Reset Link',
                        onPressed: _handleResetPassword,
                        isLoading: authProvider.isLoading,
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Resend button
                      CustomButton(
                        text: 'Resend Email',
                        onPressed: () {
                          setState(() {
                            _emailSent = false;
                          });
                        },
                        isLoading: authProvider.isLoading,
                      ),
                      const SizedBox(height: 16),
                      
                      // Back to login button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          ),
                        ),
                        child: const Text('Back to Login'),
                      ),
                    ],
                    
                    if (!_emailSent) ...[
                      // Back to login link
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Remember your password? '),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
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
