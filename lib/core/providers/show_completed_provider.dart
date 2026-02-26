import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to persist show completed state across tab switches
final showCompletedProvider = StateProvider<bool>((ref) => false);
