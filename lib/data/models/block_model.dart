import 'package:isar/isar.dart';
import 'package:openlist/core/models/sync_status.dart';

part 'block_model.g.dart';

@collection
class BlockModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String blockId; // UUID for syncing

  @Index()
  late String itemId; // Parent item

  @enumerated
  late BlockType type;

  late String content;
  late bool isChecked; // For checklist/sub-task blocks

  late int orderIndex;
  late DateTime updatedAt;

  @enumerated
  late SyncStatus syncStatus;

  BlockModel({
    this.blockId = '',
    this.itemId = '',
    this.type = BlockType.text,
    this.content = '',
    this.isChecked = false,
    this.orderIndex = 0,
    DateTime? updatedAtParam,
    this.syncStatus = SyncStatus.pending,
  }) : updatedAt = updatedAtParam ?? DateTime.now();
}

enum BlockType {
  text,
  heading,
  checklist,
  image,
  bullet,
  subTask,
}
