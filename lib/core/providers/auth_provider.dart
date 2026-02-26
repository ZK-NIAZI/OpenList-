import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple in-memory auth flag for development/demo purposes.
/// Replace with real Supabase session checks when ready.
final isLoggedInProvider = StateProvider<bool>((ref) => false);
