import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncState {
  idle,
  syncing,
  success,
  error,
}

class SyncStatus {
  final SyncState state;
  final String? message;

  SyncStatus({
    required this.state,
    this.message,
  });
}

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier() : super(SyncStatus(state: SyncState.idle));

  void startSync() {
    state = SyncStatus(state: SyncState.syncing, message: 'Syncing...');
  }

  void syncSuccess() {
    state = SyncStatus(state: SyncState.success, message: 'Synced');
    // Auto-hide after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (state.state == SyncState.success) {
        state = SyncStatus(state: SyncState.idle);
      }
    });
  }

  void syncError(String error) {
    state = SyncStatus(state: SyncState.error, message: 'Sync failed');
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (state.state == SyncState.error) {
        state = SyncStatus(state: SyncState.idle);
      }
    });
  }

  void reset() {
    state = SyncStatus(state: SyncState.idle);
  }
}

final syncStatusProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier();
});
