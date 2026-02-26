import 'package:isar/isar.dart';
import 'package:openlist/core/models/sync_status.dart';

part 'item_model.g.dart';

@collection
class ItemModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String itemId; // UUID for syncing with Supabase

  String? parentId; // For sub-tasks/sections

  @enumerated
  late ItemType type;

  late String title;
  String? content; // For notes/descriptions

  late bool isPinned;
  late bool isCompleted;

  DateTime? dueDate;
  DateTime? reminderAt;

  String? createdBy; // User ID
  late DateTime createdAt;
  late DateTime updatedAt;

  @enumerated
  late SyncStatus syncStatus;

  late int orderIndex;

  // Category for quick add
  String? category; // 'Personal', 'Work', 'Urgent'

  ItemModel({
    this.itemId = '',
    this.parentId,
    this.type = ItemType.task,
    this.title = '',
    this.content,
    this.isPinned = false,
    this.isCompleted = false,
    this.dueDate,
    this.reminderAt,
    this.createdBy,
    DateTime? createdAtParam,
    DateTime? updatedAtParam,
    this.syncStatus = SyncStatus.pending,
    this.orderIndex = 0,
    this.category,
  })  : createdAt = createdAtParam ?? DateTime.now(),
        updatedAt = updatedAtParam ?? DateTime.now();
}

enum ItemType {
  task,
  note,
  list,
  section,
}
