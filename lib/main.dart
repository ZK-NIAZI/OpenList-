import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:openlist/app.dart';
import 'package:openlist/core/config/supabase_config.dart';
import 'package:openlist/core/config/app_config.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:openlist/data/repositories/space_repository.dart';

final secureStorage = const FlutterSecureStorage();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize critical services only - defer heavy operations
  bool isarInitialized = false;
  bool supabaseInitialized = false;
  
  // Initialize Isar Database (critical for app to work)
  try {
    await IsarService.instance.db;
    isarInitialized = true;
  } catch (e) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('❌ Isar initialization error: $e');
    }
  }
  
  // Initialize Supabase (critical for sync)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    supabaseInitialized = true;
  } catch (e) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('❌ Supabase initialization error: $e');
    }
  }
  
  // Show app immediately
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
  
  // Defer non-critical initialization to after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Initialize default spaces (deferred)
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
    
    // Start Sync Manager (deferred)
    if (supabaseInitialized) {
      SyncManager.instance.start();
    }
    
    // Initialize local notifications (deferred)
    await initializeNotifications();
  });
}

Future<void> initializeNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(settings);
}