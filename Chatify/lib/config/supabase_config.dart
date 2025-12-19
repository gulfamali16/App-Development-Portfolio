// lib/config/supabase_config.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Your Supabase credentials
  static const String supabaseUrl = 'https://vitbnkvpvuesjiwiqapq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpdGJua3ZwdnVlc2ppd2lxYXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1NDMwOTcsImV4cCI6MjA4MTExOTA5N30.1ind_mctnhR8L7W-JC7W5bSb-lbKUd2LMzWsylPrcw4';

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;
}