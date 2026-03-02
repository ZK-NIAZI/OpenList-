import 'package:openlist/core/config/supabase_config.dart';

class AppConfig {
  // Set to true to use mock authentication for development
  static const bool useMockAuth = false;
  
  // Set to true to enable debug logging
  static const bool enableDebugLogging = true;
  
  // Gemini API key for AI text extraction (loaded from config or use your own)
  static String get geminiApiKey => SupabaseConfig.geminiApiKey ?? 'YOUR_GEMINI_API_KEY_HERE';
}
