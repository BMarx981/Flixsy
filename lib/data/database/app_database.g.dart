// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PreferencesTableTable extends PreferencesTable
    with TableInfo<$PreferencesTableTable, PreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PreferencesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferencesTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTableTable createAlias(String alias) {
    return $PreferencesTableTable(attachedDatabase, alias);
  }
}

class PreferencesTableData extends DataClass
    implements Insertable<PreferencesTableData> {
  final String key;
  final String value;
  const PreferencesTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return PreferencesTableCompanion(key: Value(key), value: Value(value));
  }

  factory PreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferencesTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PreferencesTableData copyWith({String? key, String? value}) =>
      PreferencesTableData(key: key ?? this.key, value: value ?? this.value);
  PreferencesTableData copyWithCompanion(PreferencesTableCompanion data) {
    return PreferencesTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferencesTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesTableCompanion extends UpdateCompanion<PreferencesTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PreferencesTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomLayoutsTableTable extends CustomLayoutsTable
    with TableInfo<$CustomLayoutsTableTable, CustomLayoutsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomLayoutsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blocksJsonMeta = const VerificationMeta(
    'blocksJson',
  );
  @override
  late final GeneratedColumn<String> blocksJson = GeneratedColumn<String>(
    'blocks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    blocksJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_layouts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomLayoutsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('blocks_json')) {
      context.handle(
        _blocksJsonMeta,
        blocksJson.isAcceptableOrUnknown(data['blocks_json']!, _blocksJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_blocksJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomLayoutsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomLayoutsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      blocksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomLayoutsTableTable createAlias(String alias) {
    return $CustomLayoutsTableTable(attachedDatabase, alias);
  }
}

class CustomLayoutsTableData extends DataClass
    implements Insertable<CustomLayoutsTableData> {
  /// Stable layout id (a uuid). Built-in ids never reach this table.
  final String id;
  final String name;

  /// The layout's whole block tree, JSON-encoded — layouts are small, so the
  /// blocks are not normalised into their own rows.
  final String blocksJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomLayoutsTableData({
    required this.id,
    required this.name,
    required this.blocksJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['blocks_json'] = Variable<String>(blocksJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomLayoutsTableCompanion toCompanion(bool nullToAbsent) {
    return CustomLayoutsTableCompanion(
      id: Value(id),
      name: Value(name),
      blocksJson: Value(blocksJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomLayoutsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomLayoutsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      blocksJson: serializer.fromJson<String>(json['blocksJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'blocksJson': serializer.toJson<String>(blocksJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomLayoutsTableData copyWith({
    String? id,
    String? name,
    String? blocksJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomLayoutsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    blocksJson: blocksJson ?? this.blocksJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomLayoutsTableData copyWithCompanion(CustomLayoutsTableCompanion data) {
    return CustomLayoutsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      blocksJson: data.blocksJson.present
          ? data.blocksJson.value
          : this.blocksJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomLayoutsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('blocksJson: $blocksJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, blocksJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomLayoutsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.blocksJson == this.blocksJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomLayoutsTableCompanion
    extends UpdateCompanion<CustomLayoutsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> blocksJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomLayoutsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.blocksJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomLayoutsTableCompanion.insert({
    required String id,
    required String name,
    required String blocksJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       blocksJson = Value(blocksJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomLayoutsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? blocksJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (blocksJson != null) 'blocks_json': blocksJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomLayoutsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? blocksJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomLayoutsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      blocksJson: blocksJson ?? this.blocksJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (blocksJson.present) {
      map['blocks_json'] = Variable<String>(blocksJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomLayoutsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('blocksJson: $blocksJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomImagesTableTable extends CustomImagesTable
    with TableInfo<$CustomImagesTableTable, CustomImagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomImagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fileName, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_images_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomImagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomImagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomImagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomImagesTableTable createAlias(String alias) {
    return $CustomImagesTableTable(attachedDatabase, alias);
  }
}

class CustomImagesTableData extends DataClass
    implements Insertable<CustomImagesTableData> {
  /// Stable image id (a uuid). Referenced by `CustomImage` button appearances.
  final String id;

  /// Name of the backing file inside the `remote_images/` directory.
  final String fileName;
  final DateTime createdAt;
  const CustomImagesTableData({
    required this.id,
    required this.fileName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_name'] = Variable<String>(fileName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomImagesTableCompanion toCompanion(bool nullToAbsent) {
    return CustomImagesTableCompanion(
      id: Value(id),
      fileName: Value(fileName),
      createdAt: Value(createdAt),
    );
  }

  factory CustomImagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomImagesTableData(
      id: serializer.fromJson<String>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileName': serializer.toJson<String>(fileName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomImagesTableData copyWith({
    String? id,
    String? fileName,
    DateTime? createdAt,
  }) => CustomImagesTableData(
    id: id ?? this.id,
    fileName: fileName ?? this.fileName,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomImagesTableData copyWithCompanion(CustomImagesTableCompanion data) {
    return CustomImagesTableData(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomImagesTableData(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fileName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomImagesTableData &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.createdAt == this.createdAt);
}

class CustomImagesTableCompanion
    extends UpdateCompanion<CustomImagesTableData> {
  final Value<String> id;
  final Value<String> fileName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomImagesTableCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomImagesTableCompanion.insert({
    required String id,
    required String fileName,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fileName = Value(fileName),
       createdAt = Value(createdAt);
  static Insertable<CustomImagesTableData> custom({
    Expression<String>? id,
    Expression<String>? fileName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomImagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? fileName,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomImagesTableCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomImagesTableCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceNamesTableTable extends DeviceNamesTable
    with TableInfo<$DeviceNamesTableTable, DeviceNamesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceNamesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, nickname, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_names_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceNamesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  DeviceNamesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceNamesTableData(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeviceNamesTableTable createAlias(String alias) {
    return $DeviceNamesTableTable(attachedDatabase, alias);
  }
}

class DeviceNamesTableData extends DataClass
    implements Insertable<DeviceNamesTableData> {
  final String deviceId;
  final String nickname;
  final DateTime updatedAt;
  const DeviceNamesTableData({
    required this.deviceId,
    required this.nickname,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['nickname'] = Variable<String>(nickname);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeviceNamesTableCompanion toCompanion(bool nullToAbsent) {
    return DeviceNamesTableCompanion(
      deviceId: Value(deviceId),
      nickname: Value(nickname),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeviceNamesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceNamesTableData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'nickname': serializer.toJson<String>(nickname),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeviceNamesTableData copyWith({
    String? deviceId,
    String? nickname,
    DateTime? updatedAt,
  }) => DeviceNamesTableData(
    deviceId: deviceId ?? this.deviceId,
    nickname: nickname ?? this.nickname,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeviceNamesTableData copyWithCompanion(DeviceNamesTableCompanion data) {
    return DeviceNamesTableData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceNamesTableData(')
          ..write('deviceId: $deviceId, ')
          ..write('nickname: $nickname, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, nickname, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceNamesTableData &&
          other.deviceId == this.deviceId &&
          other.nickname == this.nickname &&
          other.updatedAt == this.updatedAt);
}

class DeviceNamesTableCompanion extends UpdateCompanion<DeviceNamesTableData> {
  final Value<String> deviceId;
  final Value<String> nickname;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DeviceNamesTableCompanion({
    this.deviceId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceNamesTableCompanion.insert({
    required String deviceId,
    required String nickname,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       nickname = Value(nickname),
       updatedAt = Value(updatedAt);
  static Insertable<DeviceNamesTableData> custom({
    Expression<String>? deviceId,
    Expression<String>? nickname,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (nickname != null) 'nickname': nickname,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceNamesTableCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? nickname,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DeviceNamesTableCompanion(
      deviceId: deviceId ?? this.deviceId,
      nickname: nickname ?? this.nickname,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceNamesTableCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('nickname: $nickname, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PreferencesTableTable preferencesTable = $PreferencesTableTable(
    this,
  );
  late final $CustomLayoutsTableTable customLayoutsTable =
      $CustomLayoutsTableTable(this);
  late final $CustomImagesTableTable customImagesTable =
      $CustomImagesTableTable(this);
  late final $DeviceNamesTableTable deviceNamesTable = $DeviceNamesTableTable(
    this,
  );
  late final PreferencesDao preferencesDao = PreferencesDao(
    this as AppDatabase,
  );
  late final LayoutsDao layoutsDao = LayoutsDao(this as AppDatabase);
  late final CustomImagesDao customImagesDao = CustomImagesDao(
    this as AppDatabase,
  );
  late final DeviceNamesDao deviceNamesDao = DeviceNamesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    preferencesTable,
    customLayoutsTable,
    customImagesTable,
    deviceNamesTable,
  ];
}

typedef $$PreferencesTableTableCreateCompanionBuilder =
    PreferencesTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableTableUpdateCompanionBuilder =
    PreferencesTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTableTable> {
  $$PreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTableTable> {
  $$PreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTableTable> {
  $$PreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTableTable,
          PreferencesTableData,
          $$PreferencesTableTableFilterComposer,
          $$PreferencesTableTableOrderingComposer,
          $$PreferencesTableTableAnnotationComposer,
          $$PreferencesTableTableCreateCompanionBuilder,
          $$PreferencesTableTableUpdateCompanionBuilder,
          (
            PreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $PreferencesTableTable,
              PreferencesTableData
            >,
          ),
          PreferencesTableData,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableTableManager(
    _$AppDatabase db,
    $PreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesTableCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTableTable,
      PreferencesTableData,
      $$PreferencesTableTableFilterComposer,
      $$PreferencesTableTableOrderingComposer,
      $$PreferencesTableTableAnnotationComposer,
      $$PreferencesTableTableCreateCompanionBuilder,
      $$PreferencesTableTableUpdateCompanionBuilder,
      (
        PreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $PreferencesTableTable,
          PreferencesTableData
        >,
      ),
      PreferencesTableData,
      PrefetchHooks Function()
    >;
typedef $$CustomLayoutsTableTableCreateCompanionBuilder =
    CustomLayoutsTableCompanion Function({
      required String id,
      required String name,
      required String blocksJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CustomLayoutsTableTableUpdateCompanionBuilder =
    CustomLayoutsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> blocksJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CustomLayoutsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomLayoutsTableTable> {
  $$CustomLayoutsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomLayoutsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomLayoutsTableTable> {
  $$CustomLayoutsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomLayoutsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomLayoutsTableTable> {
  $$CustomLayoutsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomLayoutsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomLayoutsTableTable,
          CustomLayoutsTableData,
          $$CustomLayoutsTableTableFilterComposer,
          $$CustomLayoutsTableTableOrderingComposer,
          $$CustomLayoutsTableTableAnnotationComposer,
          $$CustomLayoutsTableTableCreateCompanionBuilder,
          $$CustomLayoutsTableTableUpdateCompanionBuilder,
          (
            CustomLayoutsTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomLayoutsTableTable,
              CustomLayoutsTableData
            >,
          ),
          CustomLayoutsTableData,
          PrefetchHooks Function()
        > {
  $$CustomLayoutsTableTableTableManager(
    _$AppDatabase db,
    $CustomLayoutsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomLayoutsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomLayoutsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomLayoutsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> blocksJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomLayoutsTableCompanion(
                id: id,
                name: name,
                blocksJson: blocksJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String blocksJson,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomLayoutsTableCompanion.insert(
                id: id,
                name: name,
                blocksJson: blocksJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomLayoutsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomLayoutsTableTable,
      CustomLayoutsTableData,
      $$CustomLayoutsTableTableFilterComposer,
      $$CustomLayoutsTableTableOrderingComposer,
      $$CustomLayoutsTableTableAnnotationComposer,
      $$CustomLayoutsTableTableCreateCompanionBuilder,
      $$CustomLayoutsTableTableUpdateCompanionBuilder,
      (
        CustomLayoutsTableData,
        BaseReferences<
          _$AppDatabase,
          $CustomLayoutsTableTable,
          CustomLayoutsTableData
        >,
      ),
      CustomLayoutsTableData,
      PrefetchHooks Function()
    >;
typedef $$CustomImagesTableTableCreateCompanionBuilder =
    CustomImagesTableCompanion Function({
      required String id,
      required String fileName,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CustomImagesTableTableUpdateCompanionBuilder =
    CustomImagesTableCompanion Function({
      Value<String> id,
      Value<String> fileName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CustomImagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomImagesTableTable> {
  $$CustomImagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomImagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomImagesTableTable> {
  $$CustomImagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomImagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomImagesTableTable> {
  $$CustomImagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomImagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomImagesTableTable,
          CustomImagesTableData,
          $$CustomImagesTableTableFilterComposer,
          $$CustomImagesTableTableOrderingComposer,
          $$CustomImagesTableTableAnnotationComposer,
          $$CustomImagesTableTableCreateCompanionBuilder,
          $$CustomImagesTableTableUpdateCompanionBuilder,
          (
            CustomImagesTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomImagesTableTable,
              CustomImagesTableData
            >,
          ),
          CustomImagesTableData,
          PrefetchHooks Function()
        > {
  $$CustomImagesTableTableTableManager(
    _$AppDatabase db,
    $CustomImagesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomImagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomImagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomImagesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomImagesTableCompanion(
                id: id,
                fileName: fileName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fileName,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomImagesTableCompanion.insert(
                id: id,
                fileName: fileName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomImagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomImagesTableTable,
      CustomImagesTableData,
      $$CustomImagesTableTableFilterComposer,
      $$CustomImagesTableTableOrderingComposer,
      $$CustomImagesTableTableAnnotationComposer,
      $$CustomImagesTableTableCreateCompanionBuilder,
      $$CustomImagesTableTableUpdateCompanionBuilder,
      (
        CustomImagesTableData,
        BaseReferences<
          _$AppDatabase,
          $CustomImagesTableTable,
          CustomImagesTableData
        >,
      ),
      CustomImagesTableData,
      PrefetchHooks Function()
    >;
typedef $$DeviceNamesTableTableCreateCompanionBuilder =
    DeviceNamesTableCompanion Function({
      required String deviceId,
      required String nickname,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DeviceNamesTableTableUpdateCompanionBuilder =
    DeviceNamesTableCompanion Function({
      Value<String> deviceId,
      Value<String> nickname,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DeviceNamesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceNamesTableTable> {
  $$DeviceNamesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceNamesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceNamesTableTable> {
  $$DeviceNamesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceNamesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceNamesTableTable> {
  $$DeviceNamesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DeviceNamesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceNamesTableTable,
          DeviceNamesTableData,
          $$DeviceNamesTableTableFilterComposer,
          $$DeviceNamesTableTableOrderingComposer,
          $$DeviceNamesTableTableAnnotationComposer,
          $$DeviceNamesTableTableCreateCompanionBuilder,
          $$DeviceNamesTableTableUpdateCompanionBuilder,
          (
            DeviceNamesTableData,
            BaseReferences<
              _$AppDatabase,
              $DeviceNamesTableTable,
              DeviceNamesTableData
            >,
          ),
          DeviceNamesTableData,
          PrefetchHooks Function()
        > {
  $$DeviceNamesTableTableTableManager(
    _$AppDatabase db,
    $DeviceNamesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceNamesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceNamesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceNamesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceNamesTableCompanion(
                deviceId: deviceId,
                nickname: nickname,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String nickname,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeviceNamesTableCompanion.insert(
                deviceId: deviceId,
                nickname: nickname,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceNamesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceNamesTableTable,
      DeviceNamesTableData,
      $$DeviceNamesTableTableFilterComposer,
      $$DeviceNamesTableTableOrderingComposer,
      $$DeviceNamesTableTableAnnotationComposer,
      $$DeviceNamesTableTableCreateCompanionBuilder,
      $$DeviceNamesTableTableUpdateCompanionBuilder,
      (
        DeviceNamesTableData,
        BaseReferences<
          _$AppDatabase,
          $DeviceNamesTableTable,
          DeviceNamesTableData
        >,
      ),
      DeviceNamesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PreferencesTableTableTableManager get preferencesTable =>
      $$PreferencesTableTableTableManager(_db, _db.preferencesTable);
  $$CustomLayoutsTableTableTableManager get customLayoutsTable =>
      $$CustomLayoutsTableTableTableManager(_db, _db.customLayoutsTable);
  $$CustomImagesTableTableTableManager get customImagesTable =>
      $$CustomImagesTableTableTableManager(_db, _db.customImagesTable);
  $$DeviceNamesTableTableTableManager get deviceNamesTable =>
      $$DeviceNamesTableTableTableManager(_db, _db.deviceNamesTable);
}
