import 'package:isar/isar.dart';

part 'space_model.g.dart';

@collection
class SpaceModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String spaceId; // UUID for syncing

  late String name;
  late String color; // Hex color code
  late String? icon;
  
  late DateTime createdAt;
  late DateTime updatedAt;

  SpaceModel({
    this.spaceId = '',
    this.name = '',
    this.color = '#6366F1', // Default blue
    this.icon,
    DateTime? createdAtParam,
    DateTime? updatedAtParam,
  }) : createdAt = createdAtParam ?? DateTime.now(),
       updatedAt = updatedAtParam ?? DateTime.now();
}
