// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_share_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetItemShareModelCollection on Isar {
  IsarCollection<ItemShareModel> get itemShareModels => this.collection();
}

const ItemShareModelSchema = CollectionSchema(
  name: r'ItemShareModel',
  id: 2464655271744923115,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'itemId': PropertySchema(
      id: 1,
      name: r'itemId',
      type: IsarType.string,
    ),
    r'permission': PropertySchema(
      id: 2,
      name: r'permission',
      type: IsarType.byte,
      enumMap: _ItemShareModelpermissionEnumValueMap,
    ),
    r'shareId': PropertySchema(
      id: 3,
      name: r'shareId',
      type: IsarType.string,
    ),
    r'sharedAt': PropertySchema(
      id: 4,
      name: r'sharedAt',
      type: IsarType.dateTime,
    ),
    r'sharedBy': PropertySchema(
      id: 5,
      name: r'sharedBy',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 6,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _ItemShareModelsyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userAvatar': PropertySchema(
      id: 8,
      name: r'userAvatar',
      type: IsarType.string,
    ),
    r'userEmail': PropertySchema(
      id: 9,
      name: r'userEmail',
      type: IsarType.string,
    ),
    r'userId': PropertySchema(
      id: 10,
      name: r'userId',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 11,
      name: r'userName',
      type: IsarType.string,
    )
  },
  estimateSize: _itemShareModelEstimateSize,
  serialize: _itemShareModelSerialize,
  deserialize: _itemShareModelDeserialize,
  deserializeProp: _itemShareModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'shareId': IndexSchema(
      id: 3531953376692712996,
      name: r'shareId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'shareId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'itemId': IndexSchema(
      id: -5342806140158601489,
      name: r'itemId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _itemShareModelGetId,
  getLinks: _itemShareModelGetLinks,
  attach: _itemShareModelAttach,
  version: '3.1.0+1',
);

int _itemShareModelEstimateSize(
  ItemShareModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.itemId.length * 3;
  bytesCount += 3 + object.shareId.length * 3;
  {
    final value = object.sharedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userAvatar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  {
    final value = object.userName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _itemShareModelSerialize(
  ItemShareModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.itemId);
  writer.writeByte(offsets[2], object.permission.index);
  writer.writeString(offsets[3], object.shareId);
  writer.writeDateTime(offsets[4], object.sharedAt);
  writer.writeString(offsets[5], object.sharedBy);
  writer.writeByte(offsets[6], object.syncStatus.index);
  writer.writeDateTime(offsets[7], object.updatedAt);
  writer.writeString(offsets[8], object.userAvatar);
  writer.writeString(offsets[9], object.userEmail);
  writer.writeString(offsets[10], object.userId);
  writer.writeString(offsets[11], object.userName);
}

ItemShareModel _itemShareModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ItemShareModel(
    itemId: reader.readStringOrNull(offsets[1]) ?? '',
    permission: _ItemShareModelpermissionValueEnumMap[
            reader.readByteOrNull(offsets[2])] ??
        SharePermission.view,
    shareId: reader.readStringOrNull(offsets[3]) ?? '',
    sharedAt: reader.readDateTimeOrNull(offsets[4]),
    sharedBy: reader.readStringOrNull(offsets[5]),
    syncStatus: _ItemShareModelsyncStatusValueEnumMap[
            reader.readByteOrNull(offsets[6])] ??
        SyncStatus.pending,
    userAvatar: reader.readStringOrNull(offsets[8]),
    userEmail: reader.readStringOrNull(offsets[9]),
    userId: reader.readStringOrNull(offsets[10]) ?? '',
    userName: reader.readStringOrNull(offsets[11]),
  );
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.updatedAt = reader.readDateTime(offsets[7]);
  return object;
}

P _itemShareModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 2:
      return (_ItemShareModelpermissionValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SharePermission.view) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (_ItemShareModelsyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ItemShareModelpermissionEnumValueMap = {
  'edit': 0,
  'view': 1,
};
const _ItemShareModelpermissionValueEnumMap = {
  0: SharePermission.edit,
  1: SharePermission.view,
};
const _ItemShareModelsyncStatusEnumValueMap = {
  'synced': 0,
  'pending': 1,
  'conflict': 2,
};
const _ItemShareModelsyncStatusValueEnumMap = {
  0: SyncStatus.synced,
  1: SyncStatus.pending,
  2: SyncStatus.conflict,
};

Id _itemShareModelGetId(ItemShareModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _itemShareModelGetLinks(ItemShareModel object) {
  return [];
}

void _itemShareModelAttach(
    IsarCollection<dynamic> col, Id id, ItemShareModel object) {
  object.id = id;
}

extension ItemShareModelQueryWhereSort
    on QueryBuilder<ItemShareModel, ItemShareModel, QWhere> {
  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ItemShareModelQueryWhere
    on QueryBuilder<ItemShareModel, ItemShareModel, QWhereClause> {
  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause>
      shareIdEqualTo(String shareId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'shareId',
        value: [shareId],
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause>
      shareIdNotEqualTo(String shareId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [],
              upper: [shareId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [shareId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [shareId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'shareId',
              lower: [],
              upper: [shareId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> itemIdEqualTo(
      String itemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'itemId',
        value: [itemId],
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause>
      itemIdNotEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [],
              upper: [itemId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [itemId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [itemId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'itemId',
              lower: [],
              upper: [itemId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause> userIdEqualTo(
      String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ItemShareModelQueryFilter
    on QueryBuilder<ItemShareModel, ItemShareModel, QFilterCondition> {
  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemId',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      permissionEqualTo(SharePermission value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'permission',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      permissionGreaterThan(
    SharePermission value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'permission',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      permissionLessThan(
    SharePermission value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'permission',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      permissionBetween(
    SharePermission lower,
    SharePermission upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'permission',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shareId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shareId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shareId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shareId',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      shareIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shareId',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sharedAt',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sharedAt',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sharedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sharedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sharedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sharedBy',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sharedBy',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sharedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sharedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sharedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sharedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sharedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sharedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sharedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      sharedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sharedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userAvatar',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userAvatar',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userAvatar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userAvatar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userAvatar',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userAvatarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userAvatar',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userEmail',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userEmail',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterFilterCondition>
      userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }
}

extension ItemShareModelQueryObject
    on QueryBuilder<ItemShareModel, ItemShareModel, QFilterCondition> {}

extension ItemShareModelQueryLinks
    on QueryBuilder<ItemShareModel, ItemShareModel, QFilterCondition> {}

extension ItemShareModelQuerySortBy
    on QueryBuilder<ItemShareModel, ItemShareModel, QSortBy> {
  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByPermission() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permission', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByPermissionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permission', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByShareId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByShareIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortBySharedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedAt', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortBySharedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedAt', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortBySharedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedBy', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortBySharedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedBy', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByUserAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByUserAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }
}

extension ItemShareModelQuerySortThenBy
    on QueryBuilder<ItemShareModel, ItemShareModel, QSortThenBy> {
  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByPermission() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permission', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByPermissionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'permission', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByShareId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByShareIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shareId', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenBySharedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedAt', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenBySharedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedAt', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenBySharedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedBy', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenBySharedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedBy', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByUserAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByUserAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy> thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QAfterSortBy>
      thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }
}

extension ItemShareModelQueryWhereDistinct
    on QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> {
  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctByItemId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct>
      distinctByPermission() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'permission');
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctByShareId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shareId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctBySharedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sharedAt');
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctBySharedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sharedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct>
      distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctByUserAvatar(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userAvatar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctByUserEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ItemShareModel, ItemShareModel, QDistinct> distinctByUserName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }
}

extension ItemShareModelQueryProperty
    on QueryBuilder<ItemShareModel, ItemShareModel, QQueryProperty> {
  QueryBuilder<ItemShareModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ItemShareModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ItemShareModel, String, QQueryOperations> itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemId');
    });
  }

  QueryBuilder<ItemShareModel, SharePermission, QQueryOperations>
      permissionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'permission');
    });
  }

  QueryBuilder<ItemShareModel, String, QQueryOperations> shareIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shareId');
    });
  }

  QueryBuilder<ItemShareModel, DateTime?, QQueryOperations> sharedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sharedAt');
    });
  }

  QueryBuilder<ItemShareModel, String?, QQueryOperations> sharedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sharedBy');
    });
  }

  QueryBuilder<ItemShareModel, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<ItemShareModel, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ItemShareModel, String?, QQueryOperations> userAvatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userAvatar');
    });
  }

  QueryBuilder<ItemShareModel, String?, QQueryOperations> userEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userEmail');
    });
  }

  QueryBuilder<ItemShareModel, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<ItemShareModel, String?, QQueryOperations> userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }
}
