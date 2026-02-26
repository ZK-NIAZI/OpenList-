import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/features/task/data/models/note_model.dart';

class NoteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all notes for current user
  Future<List<NoteModel>> getNotes({String? spaceId}) async {
    var query = _supabase
        .from('notes')
        .select()
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .order('updated_at', ascending: false);

    if (spaceId != null) {
      query = query.eq('space_id', spaceId);
    }

    final response = await query;
    return (response as List)
        .map((json) => NoteModel.fromJson(json))
        .toList();
  }

  // Get single note
  Future<NoteModel?> getNote(String id) async {
    final response = await _supabase
        .from('notes')
        .select()
        .eq('id', id)
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .maybeSingle();

    if (response == null) return null;
    return NoteModel.fromJson(response);
  }

  // Create note
  Future<NoteModel> createNote({
    required String title,
    String? content,
    String? spaceId,
  }) async {
    final response = await _supabase.from('notes').insert({
      'title': title,
      'content': content,
      'space_id': spaceId,
      'owner_id': _supabase.auth.currentUser!.id,
    }).select().single();

    return NoteModel.fromJson(response);
  }

  // Update note
  Future<NoteModel> updateNote(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('notes')
        .update(updates)
        .eq('id', id)
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .select()
        .single();

    return NoteModel.fromJson(response);
  }

  // Delete note
  Future<void> deleteNote(String id) async {
    await _supabase
        .from('notes')
        .delete()
        .eq('id', id)
        .eq('owner_id', _supabase.auth.currentUser!.id);
  }
}
