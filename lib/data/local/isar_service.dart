import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/data/models/space_model.dart';
import 'package:openlist/data/models/item_share_model.dart';
import 'package:openlist/data/models/space_member_model.dart';
import 'package:openlist/data/models/notification_model.dart';
import 'package:openlist/data/models/friendship_model.dart';
import 'package:openlist/data/models/user_model.dart';

class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  Future<Isar> get db async {
    if (_isar != null) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }

  Isar get isar {
    if (_isar == null) {
      throw Exception('Isar not initialized. Call IsarService.instance.db first.');
    }
    return _isar!;
  }

  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    
    return await Isar.open(
      [
        ItemModelSchema,
        BlockModelSchema,
        SpaceModelSchema,
        ItemShareModelSchema,
        SpaceMemberModelSchema,
        NotificationModelSchema,
        FriendshipModelSchema,
        UserModelSchema,
      ],
      directory: dir.path,
      name: 'openlist_db',
    );
  }

  // Close database
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  // Clear all data (used when switching users)
  Future<void> clearAllData() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
    print('✅ All local data cleared');
  }
}
