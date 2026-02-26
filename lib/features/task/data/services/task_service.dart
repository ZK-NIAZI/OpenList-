import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/features/task/data/models/task_model.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all tasks for current user
  Future<List<TaskModel>> getTasks({String? spaceId}) async {
    var query = _supabase
        .from('tasks')
        .select()
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .order('position', ascending: true);

    if (spaceId != null) {
      query = query.eq('space_id', spaceId);
    }

    final response = await query;
    return (response as List)
        .map((json) => TaskModel.fromJson(json))
        .toList();
  }

  // Get single task
  Future<TaskModel?> getTask(String id) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('id', id)
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .maybeSingle();

    if (response == null) return null;
    return TaskModel.fromJson(response);
  }

  // Create task
  Future<TaskModel> createTask({
    required String title,
    String? description,
    String? priority,
    DateTime? dueDate,
    String? spaceId,
    String? parentTaskId,
  }) async {
    final response = await _supabase.from('tasks').insert({
      'title': title,
      'description': description,
      'priority': priority ?? 'medium',
      'due_date': dueDate?.toIso8601String(),
      'space_id': spaceId,
      'parent_task_id': parentTaskId,
      'owner_id': _supabase.auth.currentUser!.id,
    }).select().single();

    return TaskModel.fromJson(response);
  }

  // Update task
  Future<TaskModel> updateTask(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('tasks')
        .update(updates)
        .eq('id', id)
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  // Toggle task completion
  Future<TaskModel> toggleTaskCompletion(String id, bool isCompleted) async {
    return updateTask(id, {'is_completed': isCompleted});
  }

  // Delete task
  Future<void> deleteTask(String id) async {
    await _supabase
        .from('tasks')
        .delete()
        .eq('id', id)
        .eq('owner_id', _supabase.auth.currentUser!.id);
  }

  // Get subtasks
  Future<List<TaskModel>> getSubtasks(String parentTaskId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('parent_task_id', parentTaskId)
        .eq('owner_id', _supabase.auth.currentUser!.id)
        .order('position', ascending: true);

    return (response as List)
        .map((json) => TaskModel.fromJson(json))
        .toList();
  }
}
