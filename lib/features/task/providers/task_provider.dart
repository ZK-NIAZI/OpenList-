import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlist/features/task/data/models/task_model.dart';
import 'package:openlist/features/task/data/services/task_service.dart';

// Task service provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// Tasks list provider
final tasksProvider = FutureProvider.family<List<TaskModel>, String?>((ref, spaceId) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getTasks(spaceId: spaceId);
});

// Single task provider
final taskProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getTask(taskId);
});

// Subtasks provider
final subtasksProvider = FutureProvider.family<List<TaskModel>, String>((ref, parentTaskId) async {
  final taskService = ref.read(taskServiceProvider);
  return await taskService.getSubtasks(parentTaskId);
});
