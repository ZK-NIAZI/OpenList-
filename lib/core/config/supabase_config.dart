import 'dart:convert';
import 'package:flutter/services.dart';

class SupabaseConfig {
  static String? _supabaseUrl;
  static String? _supabaseAnonKey;
  
  // Load config from assets file (can't be obfuscated)
  static Future<void> loadConfig() async {
    try {
      final configString = await rootBundle.loadString('assets/config.json');
      final config = json.decode(configString) as Map<String, dynamic>;
      _supabaseUrl = config['supabase_url'] as String;
      _supabaseAnonKey = config['supabase_anon_key'] as String;
      print('✅ Config loaded from assets');
    } catch (e) {
      print('❌ Failed to load config from assets: $e');
      // Fallback to hardcoded values
      _supabaseUrl = 'https://zbmkkrzwkacukdnorfgk.supabase.co';
      _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibWtrcnp3a2FjdWtkbm9yZmdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1ODEwNzcsImV4cCI6MjA4NzE1NzA3N30.X4X4PTQvIiBPpMOMk7Y_BuIfxL7CI4GRbUwLniaUZU8';
    }
  }
  
  static String get supabaseUrl {
    if (_supabaseUrl == null) {
      throw Exception('Config not loaded. Call loadConfig() first.');
    }
    return _supabaseUrl!;
  }
  
  static String get supabaseAnonKey {
    if (_supabaseAnonKey == null) {
      throw Exception('Config not loaded. Call loadConfig() first.');
    }
    return _supabaseAnonKey!;
  }
}
