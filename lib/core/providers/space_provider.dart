import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global state for selected space filter with persistence
class SelectedSpaceNotifier extends StateNotifier<String?> {
  SelectedSpaceNotifier() : super(null) {
    _loadSelectedSpace();
  }

  Future<void> _loadSelectedSpace() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSpace = prefs.getString('selected_space_name');
    
    // Default to null (show all) if no saved space
    state = savedSpace;
  }

  Future<void> setSpace(String? spaceName) async {
    state = spaceName;
    final prefs = await SharedPreferences.getInstance();
    
    if (spaceName == null) {
      await prefs.remove('selected_space_name');
    } else {
      await prefs.setString('selected_space_name', spaceName);
    }
  }
}

final selectedSpaceProvider = StateNotifierProvider<SelectedSpaceNotifier, String?>((ref) {
  return SelectedSpaceNotifier();
});

// null = All items (no filter)
// 'personal' = Only personal items (not shared)
// 'shared' = Only shared items (items you shared or received)
