// lib/screens/email_verification.dart (UPDATED WITH OTP)

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String userEmail;
  final bool isForgotPassword;
  final String title;
  final String subtitle;

  const EmailVerificationScreen({
    super.key,
    required this.userEmail,
    this.isForgotPassword = false,
    this.title = 'Verify Email Address',
    this.subtitle = 'Enter the code sent to',
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  int _resendTimer = 60; // Changed to 60 seconds
  late Timer _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Set up focus node listeners
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < _otpControllers.length - 1) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
      });

      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _otpControllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[i].text.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    String otpCode = '';
    for (var controller in _otpControllers) {
      otpCode += controller.text;
    }

    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP with Supabase
      final response = await _authService.verifyEmailOTP(
        email: widget.userEmail,
        otp: otpCode,
      );

      if (response.user != null) {
        // OTP verified successfully!
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (widget.isForgotPassword) {
            // Navigate to reset password
            Navigator.pushReplacementNamed(
              context,
              '/reset-password',
              arguments: {
                'userEmail': widget.userEmail,
              },
            );
          } else {
            // Navigate to PROFILE SETUP (not home!)
            Navigator.pushReplacementNamed(
              context,
              '/profile-setup',
              arguments: {
                'userId': response.user!.id,
                'userEmail': widget.userEmail,
                'isFirstTime': true,
              },
            );
          }
        }
      }
    } catch (e) {
      // Handle verification error
      setState(() {
        _isLoading = false;
        if (e.toString().contains('expired')) {
          _errorMessage = 'Code has expired. Please request a new one.';
        } else if (e.toString().contains('invalid')) {
          _errorMessage = 'Invalid code. Please check and try again.';
        } else {
          _errorMessage = 'Verification failed. Please try again.';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_resendTimer == 0) {
      try {
        await _authService.resendEmailOTP(widget.userEmail);

        setState(() {
          _resendTimer = 60;
        });
        _startTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification code sent to ${widget.userEmail}'),
              backgroundColor: const Color(0xFF128C7E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to resend code. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleChangeEmail() {
    Navigator.pop(context);
  }

  String _formatTimer() {
    final minutes = (_resendTimer ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendTimer % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF128C7E);

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11211F) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Navigation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF11211F) : Colors.white).withOpacity(0.9),
              ),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    onPressed: _isLoading ? null : _handleBack,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF111717),
                    ),
                  ),
                ],
              ),
            ),

            // Hero Illustration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isDark ? 0.05 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: primaryColor,
                ),
              ),
            ),

            // Text Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111717),
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.subtitle}\n',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: widget.userEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontFamily: 'Plus Jakarta Sans',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // OTP Inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 56,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111717),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1A2C2A) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Timer
            TextButton(
              onPressed: _resendTimer == 0 && !_isLoading ? _handleResendCode : null,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _resendTimer > 0 ? 'Resend code in ' : 'Didn\'t receive the code? ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    if (_resendTimer > 0)
                      TextSpan(
                        text: _formatTimer(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    if (_resendTimer == 0)
                      TextSpan(
                        text: 'Resend Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Spacer
            const Expanded(child: SizedBox()),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 0),
              child: Column(
                children: [
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: primaryColor.withOpacity(0.2),
                        animationDuration: const Duration(milliseconds: 200),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return const Color(0xFF0E7569);
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
                          : Text(
                        widget.isForgotPassword ? 'Continue' : 'Verify Email',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Change Email Button
                  TextButton(
                    onPressed: _isLoading ? null : _handleChangeEmail,
                    child: Text(
                      'Change Email Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom spacing for safe area
            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}