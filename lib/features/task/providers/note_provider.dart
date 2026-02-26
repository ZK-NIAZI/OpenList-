import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlist/features/task/data/models/note_model.dart';
import 'package:openlist/features/task/data/services/note_service.dart';

// Note service provider
final noteServiceProvider = Provider<NoteService>((ref) {
  return NoteService();
});

// Notes list provider
final notesProvider = FutureProvider.family<List<NoteModel>, String?>((ref, spaceId) async {
  final noteService = ref.read(noteServiceProvider);
  return await noteService.getNotes(spaceId: spaceId);
});

// Single note provider
final noteProvider = FutureProvider.family<NoteModel?, String>((ref, noteId) async {
  final noteService = ref.read(noteServiceProvider);
  return await noteService.getNote(noteId);
});
