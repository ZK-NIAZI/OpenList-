import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/models/space_model.dart';

class SpaceRepository {
  final IsarService _isarService = IsarService.instance;
  final _uuid = const Uuid();

  // Create default spaces if none exist
  Future<void> initializeDefaultSpaces() async {
    final isar = await _isarService.db;
    final count = await isar.spaceModels.count();
    
    if (count == 0) {
      final defaultSpaces = [
        SpaceModel(
          spaceId: _uuid.v4(),
          name: 'Personal',
          color: '#6366F1', // Blue
        ),
        SpaceModel(
          spaceId: _uuid.v4(),
          name: 'Work',
          color: '#F59E0B', // Orange
        ),
      ];

      await isar.writeTxn(() async {
        for (final space in defaultSpaces) {
          await isar.spaceModels.put(space);
        }
      });

      print('✅ Default spaces created');
    }
  }

  Future<SpaceModel> createSpace({
    required String name,
    String color = '#6366F1',
    String? icon,
  }) async {
    final isar = await _isarService.db;
    
    final space = SpaceModel(
      spaceId: _uuid.v4(),
      name: name,
      color: color,
      icon: icon,
    );

    await isar.writeTxn(() async {
      await isar.spaceModels.put(space);
    });

    print('✅ Space created: $name');
    return space;
  }

  Future<void> updateSpace(SpaceModel space) async {
    final isar = await _isarService.db;
    
    space.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.spaceModels.put(space);
    });
  }

  Future<void> deleteSpace(int id) async {
    final isar = await _isarService.db;
    
    await isar.writeTxn(() async {
      await isar.spaceModels.delete(id);
    });
  }

  Stream<List<SpaceModel>> watchAllSpaces() async* {
    final isar = await _isarService.db;
    yield* isar.spaceModels
        .where()
        .sortByName()
        .watch(fireImmediately: true);
  }

  Future<List<SpaceModel>> getAllSpaces() async {
    final isar = await _isarService.db;
    return await isar.spaceModels.where().sortByName().findAll();
  }

  Future<SpaceModel?> getSpaceById(int id) async {
    final isar = await _isarService.db;
    return await isar.spaceModels.get(id);
  }

  Future<SpaceModel?> getSpaceBySpaceId(String spaceId) async {
    final isar = await _isarService.db;
    return await isar.spaceModels
        .filter()
        .spaceIdEqualTo(spaceId)
        .findFirst();
  }
}
