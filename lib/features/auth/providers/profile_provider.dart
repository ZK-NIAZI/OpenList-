import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlist/data/repositories/profile_repository.dart';
import 'package:openlist/data/models/user_model.dart';

// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// Current user profile provider
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getCurrentUserProfile();
});

// Profile notifier for managing profile state
class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    try {
      final updatedProfile = await _repository.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(updatedProfile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}

// Profile notifier provider
final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});
