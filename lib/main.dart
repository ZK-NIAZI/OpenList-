import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openlist/app.dart';
import 'package:openlist/core/config/supabase_config.dart';
import 'package:openlist/core/config/app_config.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:openlist/data/repositories/space_repository.dart';
import 'package:openlist/services/notification_service.dart';

final secureStorage = const FlutterSecureStorage();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool supabaseInitialized = false;
  bool isarInitialized = false;
  
  // Load config from assets FIRST
  await SupabaseConfig.loadConfig();
  
  // Initialize Supabase BEFORE showing the app (critical for release builds)
  try {
    final url = SupabaseConfig.supabaseUrl;
    final key = SupabaseConfig.supabaseAnonKey;
    
    // Debug logging to verify URL is correct
    if (AppConfig.enableDebugLogging) {
      debugPrint('🔧 Supabase URL length: ${url.length}');
      debugPrint('🔧 Supabase URL: $url');
      debugPrint('🔧 Supabase Key length: ${key.length}');
    }
    
    await Supabase.initialize(
      url: url,
      anonKey: key,
    );
    supabaseInitialized = true;
    if (AppConfig.enableDebugLogging) {
      debugPrint('✅ Supabase initialized');
    }
  } catch (e) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('❌ Supabase initialization error: $e');
    }
  }
  
  // Show app after Supabase is ready
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
  
  // Initialize other services after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Initialize Isar Database
    try {
      await IsarService.instance.db;
      isarInitialized = true;
      if (AppConfig.enableDebugLogging) {
        debugPrint('✅ Isar initialized');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('❌ Isar initialization error: $e');
      }
    }
    
    // Initialize default spaces
    if (isarInitialized) {
      try {
        final spaceRepository = SpaceRepository();
        await spaceRepository.initializeDefaultSpaces();
      } catch (e) {
        if (AppConfig.enableDebugLogging) {
          debugPrint('❌ Space initialization error: $e');
        }
      }
    }
    
    // Start Sync Manager (Supabase is already initialized)
    if (supabaseInitialized) {
      SyncManager.instance.start();
    }
    
    // Initialize notification service
    try {
      await NotificationService().initialize();
      await NotificationService().requestPermissions();
      
      // Set up notification tap handler
      NotificationService().onNotificationTapped = (taskId) {
        // Navigation will be handled by the router when app is opened
        print('📱 Task notification tapped: $taskId');
        // The router will handle navigation based on the current app state
      };
      
      if (AppConfig.enableDebugLogging) {
        debugPrint('✅ Notification service initialized');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('❌ Notification service initialization error: $e');
      }
    }
  });
}