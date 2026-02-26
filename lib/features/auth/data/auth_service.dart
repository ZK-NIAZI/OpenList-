import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/sync/sync_manager.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    print('🔄 Starting sign out process...');
    
    // IMPORTANT: Sync all pending changes to Supabase BEFORE clearing local data
    print('🔄 Syncing pending changes before sign out...');
    final syncManager = SyncManager.instance;
    
    // Force sync and wait for completion
    await syncManager.triggerSync();
    
    // Wait longer to ensure sync completes (increased from 2 to 5 seconds)
    print('⏳ Waiting for sync to complete...');
    await Future.delayed(const Duration(seconds: 5));
    
    print('✅ Sync completed, clearing local data...');
    
    // Clear local Isar database after syncing
    final isarService = IsarService.instance;
    await isarService.clearAllData();
    
    print('✅ Local data cleared, signing out from Supabase...');
    await _supabase.auth.signOut();
    
    print('✅ User signed out successfully');
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update user profile
  Future<UserResponse> updateProfile({
    String? displayName,
    Map<String, dynamic>? data,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) {
      updates['display_name'] = displayName;
    }
    if (data != null) {
      updates.addAll(data);
    }

    return await _supabase.auth.updateUser(
      UserAttributes(data: updates),
    );
  }
}
