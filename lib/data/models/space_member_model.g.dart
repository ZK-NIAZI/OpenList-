// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_member_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSpaceMemberModelCollection on Isar {
  IsarCollection<SpaceMemberModel> get spaceMemberModels => this.collection();
}

const SpaceMemberModelSchema = CollectionSchema(
  name: r'SpaceMemberModel',
  id: 5766857448296343378,
  properties: {
    r'acceptedAt': PropertySchema(
      id: 0,
      name: r'acceptedAt',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'invitedAt': PropertySchema(
      id: 2,
      name: r'invitedAt',
      type: IsarType.dateTime,
    ),
    r'invitedBy': PropertySchema(
      id: 3,
      name: r'invitedBy',
      type: IsarType.string,
    ),
    r'memberId': PropertySchema(
      id: 4,
      name: r'memberId',
      type: IsarType.string,
    ),
    r'role': PropertySchema(
      id: 5,
      name: r'role',
      type: IsarType.byte,
      enumMap: _SpaceMemberModelroleEnumValueMap,
    ),
    r'spaceId': PropertySchema(
      id: 6,
      name: r'spaceId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 7,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _SpaceMemberModelsyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userAvatar': PropertySchema(
      id: 9,
      name: r'userAvatar',
      type: IsarType.string,
    ),
    r'userEmail': PropertySchema(
      id: 10,
      name: r'userEmail',
      type: IsarType.string,
    ),
    r'userId': PropertySchema(
      id: 11,
      name: r'userId',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 12,
      name: r'userName',
      type: IsarType.string,
    )
  },
  estimateSize: _spaceMemberModelEstimateSize,
  serialize: _spaceMemberModelSerialize,
  deserialize: _spaceMemberModelDeserialize,
  deserializeProp: _spaceMemberModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'memberId': IndexSchema(
      id: 5707689632932325803,
      name: r'memberId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'memberId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'spaceId': IndexSchema(
      id: -1779888219436521473,
      name: r'spaceId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'spaceId',
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
  getId: _spaceMemberModelGetId,
  getLinks: _spaceMemberModelGetLinks,
  attach: _spaceMemberModelAttach,
  version: '3.1.0+1',
);

int _spaceMemberModelEstimateSize(
  SpaceMemberModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.invitedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.memberId.length * 3;
  bytesCount += 3 + object.spaceId.length * 3;
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

void _spaceMemberModelSerialize(
  SpaceMemberModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.acceptedAt);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.invitedAt);
  writer.writeString(offsets[3], object.invitedBy);
  writer.writeString(offsets[4], object.memberId);
  writer.writeByte(offsets[5], object.role.index);
  writer.writeString(offsets[6], object.spaceId);
  writer.writeByte(offsets[7], object.syncStatus.index);
  writer.writeDateTime(offsets[8], object.updatedAt);
  writer.writeString(offsets[9], object.userAvatar);
  writer.writeString(offsets[10], object.userEmail);
  writer.writeString(offsets[11], object.userId);
  writer.writeString(offsets[12], object.userName);
}

SpaceMemberModel _spaceMemberModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SpaceMemberModel(
    acceptedAt: reader.readDateTimeOrNull(offsets[0]),
    invitedAt: reader.readDateTimeOrNull(offsets[2]),
    invitedBy: reader.readStringOrNull(offsets[3]),
    memberId: reader.readStringOrNull(offsets[4]) ?? '',
    role:
        _SpaceMemberModelroleValueEnumMap[reader.readByteOrNull(offsets[5])] ??
            MemberRole.viewer,
    spaceId: reader.readStringOrNull(offsets[6]) ?? '',
    syncStatus: _SpaceMemberModelsyncStatusValueEnumMap[
            reader.readByteOrNull(offsets[7])] ??
        SyncStatus.pending,
    userAvatar: reader.readStringOrNull(offsets[9]),
    userEmail: reader.readStringOrNull(offsets[10]),
    userId: reader.readStringOrNull(offsets[11]) ?? '',
    userName: reader.readStringOrNull(offsets[12]),
  );
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _spaceMemberModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 5:
      return (_SpaceMemberModelroleValueEnumMap[
              reader.readByteOrNull(offset)] ??
          MemberRole.viewer) as P;
    case 6:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 7:
      return (_SpaceMemberModelsyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SpaceMemberModelroleEnumValueMap = {
  'owner': 0,
  'editor': 1,
  'viewer': 2,
};
const _SpaceMemberModelroleValueEnumMap = {
  0: MemberRole.owner,
  1: MemberRole.editor,
  2: MemberRole.viewer,
};
const _SpaceMemberModelsyncStatusEnumValueMap = {
  'synced': 0,
  'pending': 1,
  'conflict': 2,
};
const _SpaceMemberModelsyncStatusValueEnumMap = {
  0: SyncStatus.synced,
  1: SyncStatus.pending,
  2: SyncStatus.conflict,
};

Id _spaceMemberModelGetId(SpaceMemberModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _spaceMemberModelGetLinks(SpaceMemberModel object) {
  return [];
}

void _spaceMemberModelAttach(
    IsarCollection<dynamic> col, Id id, SpaceMemberModel object) {
  object.id = id;
}

extension SpaceMemberModelQueryWhereSort
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QWhere> {
  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SpaceMemberModelQueryWhere
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QWhereClause> {
  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      memberIdEqualTo(String memberId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'memberId',
        value: [memberId],
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      memberIdNotEqualTo(String memberId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memberId',
              lower: [],
              upper: [memberId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memberId',
              lower: [memberId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memberId',
              lower: [memberId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memberId',
              lower: [],
              upper: [memberId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      spaceIdEqualTo(String spaceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'spaceId',
        value: [spaceId],
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      spaceIdNotEqualTo(String spaceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spaceId',
              lower: [],
              upper: [spaceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spaceId',
              lower: [spaceId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spaceId',
              lower: [spaceId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'spaceId',
              lower: [],
              upper: [spaceId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterWhereClause>
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

extension SpaceMemberModelQueryFilter
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QFilterCondition> {
  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      acceptedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'acceptedAt',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      acceptedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'acceptedAt',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      acceptedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'acceptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      acceptedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'acceptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      acceptedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'acceptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      acceptedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'acceptedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invitedAt',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invitedAt',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invitedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invitedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invitedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invitedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invitedBy',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invitedBy',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invitedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invitedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invitedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invitedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invitedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invitedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invitedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invitedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invitedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      invitedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invitedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memberId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memberId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memberId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memberId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'memberId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'memberId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'memberId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'memberId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memberId',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      memberIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'memberId',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      roleEqualTo(MemberRole value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      roleGreaterThan(
    MemberRole value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'role',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      roleLessThan(
    MemberRole value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'role',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      roleBetween(
    MemberRole lower,
    MemberRole upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'role',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spaceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'spaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'spaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'spaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'spaceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      spaceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'spaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userAvatarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userAvatar',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userAvatarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userAvatar',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userAvatarContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userAvatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userAvatarMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userAvatar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userAvatarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userAvatar',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userAvatarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userAvatar',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userEmail',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userEmail',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
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

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterFilterCondition>
      userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }
}

extension SpaceMemberModelQueryObject
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QFilterCondition> {}

extension SpaceMemberModelQueryLinks
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QFilterCondition> {}

extension SpaceMemberModelQuerySortBy
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QSortBy> {
  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByAcceptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByAcceptedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByInvitedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByInvitedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByInvitedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedBy', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByInvitedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedBy', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByMemberId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memberId', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByMemberIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memberId', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy> sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortBySpaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spaceId', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortBySpaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spaceId', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }
}

extension SpaceMemberModelQuerySortThenBy
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QSortThenBy> {
  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByAcceptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByAcceptedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptedAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByInvitedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByInvitedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByInvitedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedBy', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByInvitedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invitedBy', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByMemberId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memberId', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByMemberIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memberId', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy> thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenBySpaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spaceId', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenBySpaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spaceId', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAvatar', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userEmail', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QAfterSortBy>
      thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }
}

extension SpaceMemberModelQueryWhereDistinct
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct> {
  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByAcceptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'acceptedAt');
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByInvitedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invitedAt');
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByInvitedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invitedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByMemberId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memberId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct> distinctByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role');
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct> distinctBySpaceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spaceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByUserAvatar({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userAvatar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByUserEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpaceMemberModel, SpaceMemberModel, QDistinct>
      distinctByUserName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }
}

extension SpaceMemberModelQueryProperty
    on QueryBuilder<SpaceMemberModel, SpaceMemberModel, QQueryProperty> {
  QueryBuilder<SpaceMemberModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SpaceMemberModel, DateTime?, QQueryOperations>
      acceptedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'acceptedAt');
    });
  }

  QueryBuilder<SpaceMemberModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SpaceMemberModel, DateTime?, QQueryOperations>
      invitedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invitedAt');
    });
  }

  QueryBuilder<SpaceMemberModel, String?, QQueryOperations>
      invitedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invitedBy');
    });
  }

  QueryBuilder<SpaceMemberModel, String, QQueryOperations> memberIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memberId');
    });
  }

  QueryBuilder<SpaceMemberModel, MemberRole, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<SpaceMemberModel, String, QQueryOperations> spaceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spaceId');
    });
  }

  QueryBuilder<SpaceMemberModel, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<SpaceMemberModel, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<SpaceMemberModel, String?, QQueryOperations>
      userAvatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userAvatar');
    });
  }

  QueryBuilder<SpaceMemberModel, String?, QQueryOperations>
      userEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userEmail');
    });
  }

  QueryBuilder<SpaceMemberModel, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<SpaceMemberModel, String?, QQueryOperations> userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }
}
