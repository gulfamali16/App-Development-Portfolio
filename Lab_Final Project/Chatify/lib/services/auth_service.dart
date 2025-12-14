// lib/services/auth_service.dart (UPDATED VERSION)

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // SIGN UP with Email (IMPROVED)
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      // Step 1: Create auth user with metadata
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'display_name': fullName,
          'avatar_url': '',
          'status': 'Available',
          'about': 'Hey there! I am using ChatiFy.',
        },
      );

      // Step 2: Create user profile in database (with retry)
      if (response.user != null) {
        try {
          await _createUserProfileWithRetry(
            userId: response.user!.id,
            email: email,
            fullName: fullName,
            phone: phone,
          );
        } catch (e) {
          print('Error creating profile (will retry on login): $e');
          // Don't throw error - profile will be created on first login if missing
        }
      }

      return response;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  // CREATE USER PROFILE with retry logic
  Future<void> _createUserProfileWithRetry({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    int retries = 3,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        // Check if profile already exists
        final existing = await _supabase
            .from('users')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existing != null) {
          print('User profile already exists');
          return; // Profile exists, no need to create
        }

        // Create new profile
        await _supabase.from('users').insert({
          'id': userId,
          'email': email,
          'phone': phone,
          'username': email.split('@')[0],
          'display_name': fullName,
          'status': 'Available',
          'about': 'Hey there! I am using ChatiFy.',
          'avatar_url': '',
          'last_seen': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });

        print('User profile created successfully');
        return; // Success
      } catch (e) {
        print('Attempt ${i + 1} failed: $e');
        if (i == retries - 1) {
          rethrow; // Last attempt failed
        }
        await Future.delayed(Duration(seconds: i + 1)); // Wait before retry
      }
    }
  }

  // ENSURE USER PROFILE EXISTS (Call this after login)
  Future<void> ensureUserProfileExists() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Check if profile exists
      final profile = await getUserProfile(user.id);

      if (profile == null) {
        // Profile doesn't exist, create it
        final metadata = user.userMetadata;
        await _createUserProfileWithRetry(
          userId: user.id,
          email: user.email ?? '',
          fullName: metadata?['full_name'] ?? 'User',
          phone: metadata?['phone'] ?? '',
        );
      }
    } catch (e) {
      print('Error ensuring profile exists: $e');
    }
  }

  // LOGIN with Email
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Ensure user profile exists after login
      if (response.user != null) {
        await ensureUserProfileExists();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // SEND PASSWORD RESET EMAIL
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'chatify://reset-password',
      );
    } catch (e) {
      rethrow;
    }
  }

  // UPDATE PASSWORD
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // VERIFY EMAIL OTP
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      // Ensure profile exists after verification
      if (response.user != null) {
        await ensureUserProfileExists();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // RESEND EMAIL OTP
  Future<void> resendEmailOTP(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // GET USER PROFILE
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // UPDATE USER PROFILE
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? status,
    String? about,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (status != null) updates['status'] = status;
      if (about != null) updates['about'] = about;

      await _supabase.from('users').update(updates).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}