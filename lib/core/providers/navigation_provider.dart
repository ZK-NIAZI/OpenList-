import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to control the bottom navigation tab
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Tab indices:
// 0 = Dashboard
// 1 = Tasks
// 2 = Notes
// 3 = Alerts
