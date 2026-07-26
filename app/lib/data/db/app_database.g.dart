// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RuleConfigVersionsTableTable extends RuleConfigVersionsTable
    with TableInfo<$RuleConfigVersionsTableTable, RuleConfigVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleConfigVersionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuesJsonMeta = const VerificationMeta(
    'valuesJson',
  );
  @override
  late final GeneratedColumn<String> valuesJson = GeneratedColumn<String>(
    'values_json',
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
  List<GeneratedColumn> get $columns => [version, valuesJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_config_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleConfigVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('values_json')) {
      context.handle(
        _valuesJsonMeta,
        valuesJson.isAcceptableOrUnknown(data['values_json']!, _valuesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valuesJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {version};
  @override
  RuleConfigVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleConfigVersionRow(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      valuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}values_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RuleConfigVersionsTableTable createAlias(String alias) {
    return $RuleConfigVersionsTableTable(attachedDatabase, alias);
  }
}

class RuleConfigVersionRow extends DataClass
    implements Insertable<RuleConfigVersionRow> {
  final String version;
  final String valuesJson;
  final DateTime createdAt;
  const RuleConfigVersionRow({
    required this.version,
    required this.valuesJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<String>(version);
    map['values_json'] = Variable<String>(valuesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RuleConfigVersionsTableCompanion toCompanion(bool nullToAbsent) {
    return RuleConfigVersionsTableCompanion(
      version: Value(version),
      valuesJson: Value(valuesJson),
      createdAt: Value(createdAt),
    );
  }

  factory RuleConfigVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleConfigVersionRow(
      version: serializer.fromJson<String>(json['version']),
      valuesJson: serializer.fromJson<String>(json['valuesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<String>(version),
      'valuesJson': serializer.toJson<String>(valuesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RuleConfigVersionRow copyWith({
    String? version,
    String? valuesJson,
    DateTime? createdAt,
  }) => RuleConfigVersionRow(
    version: version ?? this.version,
    valuesJson: valuesJson ?? this.valuesJson,
    createdAt: createdAt ?? this.createdAt,
  );
  RuleConfigVersionRow copyWithCompanion(
    RuleConfigVersionsTableCompanion data,
  ) {
    return RuleConfigVersionRow(
      version: data.version.present ? data.version.value : this.version,
      valuesJson: data.valuesJson.present
          ? data.valuesJson.value
          : this.valuesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleConfigVersionRow(')
          ..write('version: $version, ')
          ..write('valuesJson: $valuesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, valuesJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleConfigVersionRow &&
          other.version == this.version &&
          other.valuesJson == this.valuesJson &&
          other.createdAt == this.createdAt);
}

class RuleConfigVersionsTableCompanion
    extends UpdateCompanion<RuleConfigVersionRow> {
  final Value<String> version;
  final Value<String> valuesJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RuleConfigVersionsTableCompanion({
    this.version = const Value.absent(),
    this.valuesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleConfigVersionsTableCompanion.insert({
    required String version,
    required String valuesJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : version = Value(version),
       valuesJson = Value(valuesJson),
       createdAt = Value(createdAt);
  static Insertable<RuleConfigVersionRow> custom({
    Expression<String>? version,
    Expression<String>? valuesJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (valuesJson != null) 'values_json': valuesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleConfigVersionsTableCompanion copyWith({
    Value<String>? version,
    Value<String>? valuesJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RuleConfigVersionsTableCompanion(
      version: version ?? this.version,
      valuesJson: valuesJson ?? this.valuesJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (valuesJson.present) {
      map['values_json'] = Variable<String>(valuesJson.value);
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
    return (StringBuffer('RuleConfigVersionsTableCompanion(')
          ..write('version: $version, ')
          ..write('valuesJson: $valuesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseEstimatedEnergyMeta =
      const VerificationMeta('baseEstimatedEnergy');
  @override
  late final GeneratedColumn<int> baseEstimatedEnergy = GeneratedColumn<int>(
    'base_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _pendingBaseEstimatedEnergyMeta =
      const VerificationMeta('pendingBaseEstimatedEnergy');
  @override
  late final GeneratedColumn<int> pendingBaseEstimatedEnergy =
      GeneratedColumn<int>(
        'pending_base_energy',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay?, String>
  baseEnergyEffectiveLifeDay =
      GeneratedColumn<String>(
        'base_energy_effective_life_day',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LifeDay?>(
        $AppSettingsTableTable.$converterbaseEnergyEffectiveLifeDayn,
      );
  static const VerificationMeta _activeRuleVersionMeta = const VerificationMeta(
    'activeRuleVersion',
  );
  @override
  late final GeneratedColumn<String> activeRuleVersion =
      GeneratedColumn<String>(
        'active_rule_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pendingRuleVersionMeta =
      const VerificationMeta('pendingRuleVersion');
  @override
  late final GeneratedColumn<String> pendingRuleVersion =
      GeneratedColumn<String>(
        'pending_rule_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay?, String>
  pendingRuleEffectiveLifeDay =
      GeneratedColumn<String>(
        'pending_rule_effective_life_day',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LifeDay?>(
        $AppSettingsTableTable.$converterpendingRuleEffectiveLifeDayn,
      );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    baseEstimatedEnergy,
    pendingBaseEstimatedEnergy,
    baseEnergyEffectiveLifeDay,
    activeRuleVersion,
    pendingRuleVersion,
    pendingRuleEffectiveLifeDay,
    onboardingCompleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_energy')) {
      context.handle(
        _baseEstimatedEnergyMeta,
        baseEstimatedEnergy.isAcceptableOrUnknown(
          data['base_energy']!,
          _baseEstimatedEnergyMeta,
        ),
      );
    }
    if (data.containsKey('pending_base_energy')) {
      context.handle(
        _pendingBaseEstimatedEnergyMeta,
        pendingBaseEstimatedEnergy.isAcceptableOrUnknown(
          data['pending_base_energy']!,
          _pendingBaseEstimatedEnergyMeta,
        ),
      );
    }
    if (data.containsKey('active_rule_version')) {
      context.handle(
        _activeRuleVersionMeta,
        activeRuleVersion.isAcceptableOrUnknown(
          data['active_rule_version']!,
          _activeRuleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeRuleVersionMeta);
    }
    if (data.containsKey('pending_rule_version')) {
      context.handle(
        _pendingRuleVersionMeta,
        pendingRuleVersion.isAcceptableOrUnknown(
          data['pending_rule_version']!,
          _pendingRuleVersionMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
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
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseEstimatedEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_energy'],
      )!,
      pendingBaseEstimatedEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_base_energy'],
      ),
      baseEnergyEffectiveLifeDay: $AppSettingsTableTable
          .$converterbaseEnergyEffectiveLifeDayn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}base_energy_effective_life_day'],
            ),
          ),
      activeRuleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_rule_version'],
      )!,
      pendingRuleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_rule_version'],
      ),
      pendingRuleEffectiveLifeDay: $AppSettingsTableTable
          .$converterpendingRuleEffectiveLifeDayn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}pending_rule_effective_life_day'],
            ),
          ),
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
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
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterbaseEnergyEffectiveLifeDay =
      const LifeDayConverter();
  static TypeConverter<LifeDay?, String?>
  $converterbaseEnergyEffectiveLifeDayn = NullAwareTypeConverter.wrap(
    $converterbaseEnergyEffectiveLifeDay,
  );
  static TypeConverter<LifeDay, String> $converterpendingRuleEffectiveLifeDay =
      const LifeDayConverter();
  static TypeConverter<LifeDay?, String?>
  $converterpendingRuleEffectiveLifeDayn = NullAwareTypeConverter.wrap(
    $converterpendingRuleEffectiveLifeDay,
  );
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final int baseEstimatedEnergy;
  final int? pendingBaseEstimatedEnergy;
  final LifeDay? baseEnergyEffectiveLifeDay;
  final String activeRuleVersion;
  final String? pendingRuleVersion;
  final LifeDay? pendingRuleEffectiveLifeDay;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppSettingsRow({
    required this.id,
    required this.baseEstimatedEnergy,
    this.pendingBaseEstimatedEnergy,
    this.baseEnergyEffectiveLifeDay,
    required this.activeRuleVersion,
    this.pendingRuleVersion,
    this.pendingRuleEffectiveLifeDay,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_energy'] = Variable<int>(baseEstimatedEnergy);
    if (!nullToAbsent || pendingBaseEstimatedEnergy != null) {
      map['pending_base_energy'] = Variable<int>(pendingBaseEstimatedEnergy);
    }
    if (!nullToAbsent || baseEnergyEffectiveLifeDay != null) {
      map['base_energy_effective_life_day'] = Variable<String>(
        $AppSettingsTableTable.$converterbaseEnergyEffectiveLifeDayn.toSql(
          baseEnergyEffectiveLifeDay,
        ),
      );
    }
    map['active_rule_version'] = Variable<String>(activeRuleVersion);
    if (!nullToAbsent || pendingRuleVersion != null) {
      map['pending_rule_version'] = Variable<String>(pendingRuleVersion);
    }
    if (!nullToAbsent || pendingRuleEffectiveLifeDay != null) {
      map['pending_rule_effective_life_day'] = Variable<String>(
        $AppSettingsTableTable.$converterpendingRuleEffectiveLifeDayn.toSql(
          pendingRuleEffectiveLifeDay,
        ),
      );
    }
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      baseEstimatedEnergy: Value(baseEstimatedEnergy),
      pendingBaseEstimatedEnergy:
          pendingBaseEstimatedEnergy == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingBaseEstimatedEnergy),
      baseEnergyEffectiveLifeDay:
          baseEnergyEffectiveLifeDay == null && nullToAbsent
          ? const Value.absent()
          : Value(baseEnergyEffectiveLifeDay),
      activeRuleVersion: Value(activeRuleVersion),
      pendingRuleVersion: pendingRuleVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRuleVersion),
      pendingRuleEffectiveLifeDay:
          pendingRuleEffectiveLifeDay == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRuleEffectiveLifeDay),
      onboardingCompleted: Value(onboardingCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      baseEstimatedEnergy: serializer.fromJson<int>(
        json['baseEstimatedEnergy'],
      ),
      pendingBaseEstimatedEnergy: serializer.fromJson<int?>(
        json['pendingBaseEstimatedEnergy'],
      ),
      baseEnergyEffectiveLifeDay: serializer.fromJson<LifeDay?>(
        json['baseEnergyEffectiveLifeDay'],
      ),
      activeRuleVersion: serializer.fromJson<String>(json['activeRuleVersion']),
      pendingRuleVersion: serializer.fromJson<String?>(
        json['pendingRuleVersion'],
      ),
      pendingRuleEffectiveLifeDay: serializer.fromJson<LifeDay?>(
        json['pendingRuleEffectiveLifeDay'],
      ),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseEstimatedEnergy': serializer.toJson<int>(baseEstimatedEnergy),
      'pendingBaseEstimatedEnergy': serializer.toJson<int?>(
        pendingBaseEstimatedEnergy,
      ),
      'baseEnergyEffectiveLifeDay': serializer.toJson<LifeDay?>(
        baseEnergyEffectiveLifeDay,
      ),
      'activeRuleVersion': serializer.toJson<String>(activeRuleVersion),
      'pendingRuleVersion': serializer.toJson<String?>(pendingRuleVersion),
      'pendingRuleEffectiveLifeDay': serializer.toJson<LifeDay?>(
        pendingRuleEffectiveLifeDay,
      ),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    int? baseEstimatedEnergy,
    Value<int?> pendingBaseEstimatedEnergy = const Value.absent(),
    Value<LifeDay?> baseEnergyEffectiveLifeDay = const Value.absent(),
    String? activeRuleVersion,
    Value<String?> pendingRuleVersion = const Value.absent(),
    Value<LifeDay?> pendingRuleEffectiveLifeDay = const Value.absent(),
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppSettingsRow(
    id: id ?? this.id,
    baseEstimatedEnergy: baseEstimatedEnergy ?? this.baseEstimatedEnergy,
    pendingBaseEstimatedEnergy: pendingBaseEstimatedEnergy.present
        ? pendingBaseEstimatedEnergy.value
        : this.pendingBaseEstimatedEnergy,
    baseEnergyEffectiveLifeDay: baseEnergyEffectiveLifeDay.present
        ? baseEnergyEffectiveLifeDay.value
        : this.baseEnergyEffectiveLifeDay,
    activeRuleVersion: activeRuleVersion ?? this.activeRuleVersion,
    pendingRuleVersion: pendingRuleVersion.present
        ? pendingRuleVersion.value
        : this.pendingRuleVersion,
    pendingRuleEffectiveLifeDay: pendingRuleEffectiveLifeDay.present
        ? pendingRuleEffectiveLifeDay.value
        : this.pendingRuleEffectiveLifeDay,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      baseEstimatedEnergy: data.baseEstimatedEnergy.present
          ? data.baseEstimatedEnergy.value
          : this.baseEstimatedEnergy,
      pendingBaseEstimatedEnergy: data.pendingBaseEstimatedEnergy.present
          ? data.pendingBaseEstimatedEnergy.value
          : this.pendingBaseEstimatedEnergy,
      baseEnergyEffectiveLifeDay: data.baseEnergyEffectiveLifeDay.present
          ? data.baseEnergyEffectiveLifeDay.value
          : this.baseEnergyEffectiveLifeDay,
      activeRuleVersion: data.activeRuleVersion.present
          ? data.activeRuleVersion.value
          : this.activeRuleVersion,
      pendingRuleVersion: data.pendingRuleVersion.present
          ? data.pendingRuleVersion.value
          : this.pendingRuleVersion,
      pendingRuleEffectiveLifeDay: data.pendingRuleEffectiveLifeDay.present
          ? data.pendingRuleEffectiveLifeDay.value
          : this.pendingRuleEffectiveLifeDay,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('baseEstimatedEnergy: $baseEstimatedEnergy, ')
          ..write('pendingBaseEstimatedEnergy: $pendingBaseEstimatedEnergy, ')
          ..write('baseEnergyEffectiveLifeDay: $baseEnergyEffectiveLifeDay, ')
          ..write('activeRuleVersion: $activeRuleVersion, ')
          ..write('pendingRuleVersion: $pendingRuleVersion, ')
          ..write('pendingRuleEffectiveLifeDay: $pendingRuleEffectiveLifeDay, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseEstimatedEnergy,
    pendingBaseEstimatedEnergy,
    baseEnergyEffectiveLifeDay,
    activeRuleVersion,
    pendingRuleVersion,
    pendingRuleEffectiveLifeDay,
    onboardingCompleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.baseEstimatedEnergy == this.baseEstimatedEnergy &&
          other.pendingBaseEstimatedEnergy == this.pendingBaseEstimatedEnergy &&
          other.baseEnergyEffectiveLifeDay == this.baseEnergyEffectiveLifeDay &&
          other.activeRuleVersion == this.activeRuleVersion &&
          other.pendingRuleVersion == this.pendingRuleVersion &&
          other.pendingRuleEffectiveLifeDay ==
              this.pendingRuleEffectiveLifeDay &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<int> baseEstimatedEnergy;
  final Value<int?> pendingBaseEstimatedEnergy;
  final Value<LifeDay?> baseEnergyEffectiveLifeDay;
  final Value<String> activeRuleVersion;
  final Value<String?> pendingRuleVersion;
  final Value<LifeDay?> pendingRuleEffectiveLifeDay;
  final Value<bool> onboardingCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.baseEstimatedEnergy = const Value.absent(),
    this.pendingBaseEstimatedEnergy = const Value.absent(),
    this.baseEnergyEffectiveLifeDay = const Value.absent(),
    this.activeRuleVersion = const Value.absent(),
    this.pendingRuleVersion = const Value.absent(),
    this.pendingRuleEffectiveLifeDay = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.baseEstimatedEnergy = const Value.absent(),
    this.pendingBaseEstimatedEnergy = const Value.absent(),
    this.baseEnergyEffectiveLifeDay = const Value.absent(),
    required String activeRuleVersion,
    this.pendingRuleVersion = const Value.absent(),
    this.pendingRuleEffectiveLifeDay = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : activeRuleVersion = Value(activeRuleVersion),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<int>? baseEstimatedEnergy,
    Expression<int>? pendingBaseEstimatedEnergy,
    Expression<String>? baseEnergyEffectiveLifeDay,
    Expression<String>? activeRuleVersion,
    Expression<String>? pendingRuleVersion,
    Expression<String>? pendingRuleEffectiveLifeDay,
    Expression<bool>? onboardingCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseEstimatedEnergy != null) 'base_energy': baseEstimatedEnergy,
      if (pendingBaseEstimatedEnergy != null)
        'pending_base_energy': pendingBaseEstimatedEnergy,
      if (baseEnergyEffectiveLifeDay != null)
        'base_energy_effective_life_day': baseEnergyEffectiveLifeDay,
      if (activeRuleVersion != null) 'active_rule_version': activeRuleVersion,
      if (pendingRuleVersion != null)
        'pending_rule_version': pendingRuleVersion,
      if (pendingRuleEffectiveLifeDay != null)
        'pending_rule_effective_life_day': pendingRuleEffectiveLifeDay,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? baseEstimatedEnergy,
    Value<int?>? pendingBaseEstimatedEnergy,
    Value<LifeDay?>? baseEnergyEffectiveLifeDay,
    Value<String>? activeRuleVersion,
    Value<String?>? pendingRuleVersion,
    Value<LifeDay?>? pendingRuleEffectiveLifeDay,
    Value<bool>? onboardingCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      baseEstimatedEnergy: baseEstimatedEnergy ?? this.baseEstimatedEnergy,
      pendingBaseEstimatedEnergy:
          pendingBaseEstimatedEnergy ?? this.pendingBaseEstimatedEnergy,
      baseEnergyEffectiveLifeDay:
          baseEnergyEffectiveLifeDay ?? this.baseEnergyEffectiveLifeDay,
      activeRuleVersion: activeRuleVersion ?? this.activeRuleVersion,
      pendingRuleVersion: pendingRuleVersion ?? this.pendingRuleVersion,
      pendingRuleEffectiveLifeDay:
          pendingRuleEffectiveLifeDay ?? this.pendingRuleEffectiveLifeDay,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseEstimatedEnergy.present) {
      map['base_energy'] = Variable<int>(baseEstimatedEnergy.value);
    }
    if (pendingBaseEstimatedEnergy.present) {
      map['pending_base_energy'] = Variable<int>(
        pendingBaseEstimatedEnergy.value,
      );
    }
    if (baseEnergyEffectiveLifeDay.present) {
      map['base_energy_effective_life_day'] = Variable<String>(
        $AppSettingsTableTable.$converterbaseEnergyEffectiveLifeDayn.toSql(
          baseEnergyEffectiveLifeDay.value,
        ),
      );
    }
    if (activeRuleVersion.present) {
      map['active_rule_version'] = Variable<String>(activeRuleVersion.value);
    }
    if (pendingRuleVersion.present) {
      map['pending_rule_version'] = Variable<String>(pendingRuleVersion.value);
    }
    if (pendingRuleEffectiveLifeDay.present) {
      map['pending_rule_effective_life_day'] = Variable<String>(
        $AppSettingsTableTable.$converterpendingRuleEffectiveLifeDayn.toSql(
          pendingRuleEffectiveLifeDay.value,
        ),
      );
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('baseEstimatedEnergy: $baseEstimatedEnergy, ')
          ..write('pendingBaseEstimatedEnergy: $pendingBaseEstimatedEnergy, ')
          ..write('baseEnergyEffectiveLifeDay: $baseEnergyEffectiveLifeDay, ')
          ..write('activeRuleVersion: $activeRuleVersion, ')
          ..write('pendingRuleVersion: $pendingRuleVersion, ')
          ..write('pendingRuleEffectiveLifeDay: $pendingRuleEffectiveLifeDay, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MorningCheckInsTableTable extends MorningCheckInsTable
    with TableInfo<$MorningCheckInsTableTable, MorningCheckInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MorningCheckInsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay, String> lifeDay =
      GeneratedColumn<String>(
        'life_day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      ).withConverter<LifeDay>($MorningCheckInsTableTable.$converterlifeDay);
  @override
  late final GeneratedColumnWithTypeConverter<MorningOverallState, String>
  overallState =
      GeneratedColumn<String>(
        'overall_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MorningOverallState>(
        $MorningCheckInsTableTable.$converteroverallState,
      );
  @override
  late final GeneratedColumnWithTypeConverter<FreeTimeLevel, String>
  freeTimeLevel =
      GeneratedColumn<String>(
        'free_time_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FreeTimeLevel>(
        $MorningCheckInsTableTable.$converterfreeTimeLevel,
      );
  @override
  late final GeneratedColumnWithTypeConverter<PressureSource, String>
  pressureSource =
      GeneratedColumn<String>(
        'pressure_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PressureSource>(
        $MorningCheckInsTableTable.$converterpressureSource,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SleepRecovery, String>
  sleepRecovery =
      GeneratedColumn<String>(
        'sleep_recovery',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SleepRecovery>(
        $MorningCheckInsTableTable.$convertersleepRecovery,
      );
  static const VerificationMeta _morningAdjustmentMeta = const VerificationMeta(
    'morningAdjustment',
  );
  @override
  late final GeneratedColumn<int> morningAdjustment = GeneratedColumn<int>(
    'morning_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lifeDay,
    overallState,
    freeTimeLevel,
    pressureSource,
    sleepRecovery,
    morningAdjustment,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'morning_check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<MorningCheckInRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('morning_adjustment')) {
      context.handle(
        _morningAdjustmentMeta,
        morningAdjustment.isAcceptableOrUnknown(
          data['morning_adjustment']!,
          _morningAdjustmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_morningAdjustmentMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MorningCheckInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MorningCheckInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lifeDay: $MorningCheckInsTableTable.$converterlifeDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}life_day'],
        )!,
      ),
      overallState: $MorningCheckInsTableTable.$converteroverallState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}overall_state'],
        )!,
      ),
      freeTimeLevel: $MorningCheckInsTableTable.$converterfreeTimeLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}free_time_level'],
        )!,
      ),
      pressureSource: $MorningCheckInsTableTable.$converterpressureSource
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}pressure_source'],
            )!,
          ),
      sleepRecovery: $MorningCheckInsTableTable.$convertersleepRecovery.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sleep_recovery'],
        )!,
      ),
      morningAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}morning_adjustment'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $MorningCheckInsTableTable createAlias(String alias) {
    return $MorningCheckInsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterlifeDay =
      const LifeDayConverter();
  static TypeConverter<MorningOverallState, String> $converteroverallState =
      const MorningOverallStateConverter();
  static TypeConverter<FreeTimeLevel, String> $converterfreeTimeLevel =
      const FreeTimeLevelConverter();
  static TypeConverter<PressureSource, String> $converterpressureSource =
      const PressureSourceConverter();
  static TypeConverter<SleepRecovery, String> $convertersleepRecovery =
      const SleepRecoveryConverter();
}

class MorningCheckInRow extends DataClass
    implements Insertable<MorningCheckInRow> {
  final String id;
  final LifeDay lifeDay;
  final MorningOverallState overallState;
  final FreeTimeLevel freeTimeLevel;
  final PressureSource pressureSource;
  final SleepRecovery sleepRecovery;
  final int morningAdjustment;
  final DateTime completedAt;
  const MorningCheckInRow({
    required this.id,
    required this.lifeDay,
    required this.overallState,
    required this.freeTimeLevel,
    required this.pressureSource,
    required this.sleepRecovery,
    required this.morningAdjustment,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['life_day'] = Variable<String>(
        $MorningCheckInsTableTable.$converterlifeDay.toSql(lifeDay),
      );
    }
    {
      map['overall_state'] = Variable<String>(
        $MorningCheckInsTableTable.$converteroverallState.toSql(overallState),
      );
    }
    {
      map['free_time_level'] = Variable<String>(
        $MorningCheckInsTableTable.$converterfreeTimeLevel.toSql(freeTimeLevel),
      );
    }
    {
      map['pressure_source'] = Variable<String>(
        $MorningCheckInsTableTable.$converterpressureSource.toSql(
          pressureSource,
        ),
      );
    }
    {
      map['sleep_recovery'] = Variable<String>(
        $MorningCheckInsTableTable.$convertersleepRecovery.toSql(sleepRecovery),
      );
    }
    map['morning_adjustment'] = Variable<int>(morningAdjustment);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  MorningCheckInsTableCompanion toCompanion(bool nullToAbsent) {
    return MorningCheckInsTableCompanion(
      id: Value(id),
      lifeDay: Value(lifeDay),
      overallState: Value(overallState),
      freeTimeLevel: Value(freeTimeLevel),
      pressureSource: Value(pressureSource),
      sleepRecovery: Value(sleepRecovery),
      morningAdjustment: Value(morningAdjustment),
      completedAt: Value(completedAt),
    );
  }

  factory MorningCheckInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MorningCheckInRow(
      id: serializer.fromJson<String>(json['id']),
      lifeDay: serializer.fromJson<LifeDay>(json['lifeDay']),
      overallState: serializer.fromJson<MorningOverallState>(
        json['overallState'],
      ),
      freeTimeLevel: serializer.fromJson<FreeTimeLevel>(json['freeTimeLevel']),
      pressureSource: serializer.fromJson<PressureSource>(
        json['pressureSource'],
      ),
      sleepRecovery: serializer.fromJson<SleepRecovery>(json['sleepRecovery']),
      morningAdjustment: serializer.fromJson<int>(json['morningAdjustment']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lifeDay': serializer.toJson<LifeDay>(lifeDay),
      'overallState': serializer.toJson<MorningOverallState>(overallState),
      'freeTimeLevel': serializer.toJson<FreeTimeLevel>(freeTimeLevel),
      'pressureSource': serializer.toJson<PressureSource>(pressureSource),
      'sleepRecovery': serializer.toJson<SleepRecovery>(sleepRecovery),
      'morningAdjustment': serializer.toJson<int>(morningAdjustment),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  MorningCheckInRow copyWith({
    String? id,
    LifeDay? lifeDay,
    MorningOverallState? overallState,
    FreeTimeLevel? freeTimeLevel,
    PressureSource? pressureSource,
    SleepRecovery? sleepRecovery,
    int? morningAdjustment,
    DateTime? completedAt,
  }) => MorningCheckInRow(
    id: id ?? this.id,
    lifeDay: lifeDay ?? this.lifeDay,
    overallState: overallState ?? this.overallState,
    freeTimeLevel: freeTimeLevel ?? this.freeTimeLevel,
    pressureSource: pressureSource ?? this.pressureSource,
    sleepRecovery: sleepRecovery ?? this.sleepRecovery,
    morningAdjustment: morningAdjustment ?? this.morningAdjustment,
    completedAt: completedAt ?? this.completedAt,
  );
  MorningCheckInRow copyWithCompanion(MorningCheckInsTableCompanion data) {
    return MorningCheckInRow(
      id: data.id.present ? data.id.value : this.id,
      lifeDay: data.lifeDay.present ? data.lifeDay.value : this.lifeDay,
      overallState: data.overallState.present
          ? data.overallState.value
          : this.overallState,
      freeTimeLevel: data.freeTimeLevel.present
          ? data.freeTimeLevel.value
          : this.freeTimeLevel,
      pressureSource: data.pressureSource.present
          ? data.pressureSource.value
          : this.pressureSource,
      sleepRecovery: data.sleepRecovery.present
          ? data.sleepRecovery.value
          : this.sleepRecovery,
      morningAdjustment: data.morningAdjustment.present
          ? data.morningAdjustment.value
          : this.morningAdjustment,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MorningCheckInRow(')
          ..write('id: $id, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('overallState: $overallState, ')
          ..write('freeTimeLevel: $freeTimeLevel, ')
          ..write('pressureSource: $pressureSource, ')
          ..write('sleepRecovery: $sleepRecovery, ')
          ..write('morningAdjustment: $morningAdjustment, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lifeDay,
    overallState,
    freeTimeLevel,
    pressureSource,
    sleepRecovery,
    morningAdjustment,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MorningCheckInRow &&
          other.id == this.id &&
          other.lifeDay == this.lifeDay &&
          other.overallState == this.overallState &&
          other.freeTimeLevel == this.freeTimeLevel &&
          other.pressureSource == this.pressureSource &&
          other.sleepRecovery == this.sleepRecovery &&
          other.morningAdjustment == this.morningAdjustment &&
          other.completedAt == this.completedAt);
}

class MorningCheckInsTableCompanion extends UpdateCompanion<MorningCheckInRow> {
  final Value<String> id;
  final Value<LifeDay> lifeDay;
  final Value<MorningOverallState> overallState;
  final Value<FreeTimeLevel> freeTimeLevel;
  final Value<PressureSource> pressureSource;
  final Value<SleepRecovery> sleepRecovery;
  final Value<int> morningAdjustment;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const MorningCheckInsTableCompanion({
    this.id = const Value.absent(),
    this.lifeDay = const Value.absent(),
    this.overallState = const Value.absent(),
    this.freeTimeLevel = const Value.absent(),
    this.pressureSource = const Value.absent(),
    this.sleepRecovery = const Value.absent(),
    this.morningAdjustment = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MorningCheckInsTableCompanion.insert({
    required String id,
    required LifeDay lifeDay,
    required MorningOverallState overallState,
    required FreeTimeLevel freeTimeLevel,
    required PressureSource pressureSource,
    required SleepRecovery sleepRecovery,
    required int morningAdjustment,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lifeDay = Value(lifeDay),
       overallState = Value(overallState),
       freeTimeLevel = Value(freeTimeLevel),
       pressureSource = Value(pressureSource),
       sleepRecovery = Value(sleepRecovery),
       morningAdjustment = Value(morningAdjustment),
       completedAt = Value(completedAt);
  static Insertable<MorningCheckInRow> custom({
    Expression<String>? id,
    Expression<String>? lifeDay,
    Expression<String>? overallState,
    Expression<String>? freeTimeLevel,
    Expression<String>? pressureSource,
    Expression<String>? sleepRecovery,
    Expression<int>? morningAdjustment,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lifeDay != null) 'life_day': lifeDay,
      if (overallState != null) 'overall_state': overallState,
      if (freeTimeLevel != null) 'free_time_level': freeTimeLevel,
      if (pressureSource != null) 'pressure_source': pressureSource,
      if (sleepRecovery != null) 'sleep_recovery': sleepRecovery,
      if (morningAdjustment != null) 'morning_adjustment': morningAdjustment,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MorningCheckInsTableCompanion copyWith({
    Value<String>? id,
    Value<LifeDay>? lifeDay,
    Value<MorningOverallState>? overallState,
    Value<FreeTimeLevel>? freeTimeLevel,
    Value<PressureSource>? pressureSource,
    Value<SleepRecovery>? sleepRecovery,
    Value<int>? morningAdjustment,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return MorningCheckInsTableCompanion(
      id: id ?? this.id,
      lifeDay: lifeDay ?? this.lifeDay,
      overallState: overallState ?? this.overallState,
      freeTimeLevel: freeTimeLevel ?? this.freeTimeLevel,
      pressureSource: pressureSource ?? this.pressureSource,
      sleepRecovery: sleepRecovery ?? this.sleepRecovery,
      morningAdjustment: morningAdjustment ?? this.morningAdjustment,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lifeDay.present) {
      map['life_day'] = Variable<String>(
        $MorningCheckInsTableTable.$converterlifeDay.toSql(lifeDay.value),
      );
    }
    if (overallState.present) {
      map['overall_state'] = Variable<String>(
        $MorningCheckInsTableTable.$converteroverallState.toSql(
          overallState.value,
        ),
      );
    }
    if (freeTimeLevel.present) {
      map['free_time_level'] = Variable<String>(
        $MorningCheckInsTableTable.$converterfreeTimeLevel.toSql(
          freeTimeLevel.value,
        ),
      );
    }
    if (pressureSource.present) {
      map['pressure_source'] = Variable<String>(
        $MorningCheckInsTableTable.$converterpressureSource.toSql(
          pressureSource.value,
        ),
      );
    }
    if (sleepRecovery.present) {
      map['sleep_recovery'] = Variable<String>(
        $MorningCheckInsTableTable.$convertersleepRecovery.toSql(
          sleepRecovery.value,
        ),
      );
    }
    if (morningAdjustment.present) {
      map['morning_adjustment'] = Variable<int>(morningAdjustment.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MorningCheckInsTableCompanion(')
          ..write('id: $id, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('overallState: $overallState, ')
          ..write('freeTimeLevel: $freeTimeLevel, ')
          ..write('pressureSource: $pressureSource, ')
          ..write('sleepRecovery: $sleepRecovery, ')
          ..write('morningAdjustment: $morningAdjustment, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityRecordsTableTable extends ActivityRecordsTable
    with TableInfo<$ActivityRecordsTableTable, ActivityRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay, String> lifeDay =
      GeneratedColumn<String>(
        'life_day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LifeDay>($ActivityRecordsTableTable.$converterlifeDay);
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  late final GeneratedColumnWithTypeConverter<ActivityCategory, String>
  category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityCategory>(
        $ActivityRecordsTableTable.$convertercategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ActivitySubcategory, String>
  subcategory =
      GeneratedColumn<String>(
        'subcategory',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivitySubcategory>(
        $ActivityRecordsTableTable.$convertersubcategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DurationSlot, int> duration =
      GeneratedColumn<int>(
        'duration_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DurationSlot>(
        $ActivityRecordsTableTable.$converterduration,
      );
  static const VerificationMeta _theoreticalDeltaMeta = const VerificationMeta(
    'theoreticalDelta',
  );
  @override
  late final GeneratedColumn<int> theoreticalDelta = GeneratedColumn<int>(
    'theoretical_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedDeltaMeta = const VerificationMeta(
    'appliedDelta',
  );
  @override
  late final GeneratedColumn<int> appliedDelta = GeneratedColumn<int>(
    'applied_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  @override
  late final GeneratedColumn<String> ruleVersion = GeneratedColumn<String>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityRecordStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityRecordStatus>(
        $ActivityRecordsTableTable.$converterstatus,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lifeDay,
    completedAt,
    createdAt,
    updatedAt,
    category,
    subcategory,
    duration,
    theoreticalDelta,
    appliedDelta,
    ruleVersion,
    status,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
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
    if (data.containsKey('theoretical_delta')) {
      context.handle(
        _theoreticalDeltaMeta,
        theoreticalDelta.isAcceptableOrUnknown(
          data['theoretical_delta']!,
          _theoreticalDeltaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_theoreticalDeltaMeta);
    }
    if (data.containsKey('applied_delta')) {
      context.handle(
        _appliedDeltaMeta,
        appliedDelta.isAcceptableOrUnknown(
          data['applied_delta']!,
          _appliedDeltaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedDeltaMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lifeDay: $ActivityRecordsTableTable.$converterlifeDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}life_day'],
        )!,
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      category: $ActivityRecordsTableTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      subcategory: $ActivityRecordsTableTable.$convertersubcategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subcategory'],
        )!,
      ),
      duration: $ActivityRecordsTableTable.$converterduration.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duration_minutes'],
        )!,
      ),
      theoreticalDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}theoretical_delta'],
      )!,
      appliedDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_delta'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version'],
      )!,
      status: $ActivityRecordsTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ActivityRecordsTableTable createAlias(String alias) {
    return $ActivityRecordsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterlifeDay =
      const LifeDayConverter();
  static TypeConverter<ActivityCategory, String> $convertercategory =
      const ActivityCategoryConverter();
  static TypeConverter<ActivitySubcategory, String> $convertersubcategory =
      const ActivitySubcategoryConverter();
  static TypeConverter<DurationSlot, int> $converterduration =
      const DurationSlotConverter();
  static TypeConverter<ActivityRecordStatus, String> $converterstatus =
      const ActivityRecordStatusConverter();
}

class ActivityRecordRow extends DataClass
    implements Insertable<ActivityRecordRow> {
  final String id;
  final LifeDay lifeDay;
  final DateTime completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ActivityCategory category;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final int theoreticalDelta;
  final int appliedDelta;
  final String ruleVersion;
  final ActivityRecordStatus status;
  final DateTime? deletedAt;
  const ActivityRecordRow({
    required this.id,
    required this.lifeDay,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.subcategory,
    required this.duration,
    required this.theoreticalDelta,
    required this.appliedDelta,
    required this.ruleVersion,
    required this.status,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['life_day'] = Variable<String>(
        $ActivityRecordsTableTable.$converterlifeDay.toSql(lifeDay),
      );
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['category'] = Variable<String>(
        $ActivityRecordsTableTable.$convertercategory.toSql(category),
      );
    }
    {
      map['subcategory'] = Variable<String>(
        $ActivityRecordsTableTable.$convertersubcategory.toSql(subcategory),
      );
    }
    {
      map['duration_minutes'] = Variable<int>(
        $ActivityRecordsTableTable.$converterduration.toSql(duration),
      );
    }
    map['theoretical_delta'] = Variable<int>(theoreticalDelta);
    map['applied_delta'] = Variable<int>(appliedDelta);
    map['rule_version'] = Variable<String>(ruleVersion);
    {
      map['status'] = Variable<String>(
        $ActivityRecordsTableTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ActivityRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return ActivityRecordsTableCompanion(
      id: Value(id),
      lifeDay: Value(lifeDay),
      completedAt: Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      category: Value(category),
      subcategory: Value(subcategory),
      duration: Value(duration),
      theoreticalDelta: Value(theoreticalDelta),
      appliedDelta: Value(appliedDelta),
      ruleVersion: Value(ruleVersion),
      status: Value(status),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ActivityRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRecordRow(
      id: serializer.fromJson<String>(json['id']),
      lifeDay: serializer.fromJson<LifeDay>(json['lifeDay']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      category: serializer.fromJson<ActivityCategory>(json['category']),
      subcategory: serializer.fromJson<ActivitySubcategory>(
        json['subcategory'],
      ),
      duration: serializer.fromJson<DurationSlot>(json['duration']),
      theoreticalDelta: serializer.fromJson<int>(json['theoreticalDelta']),
      appliedDelta: serializer.fromJson<int>(json['appliedDelta']),
      ruleVersion: serializer.fromJson<String>(json['ruleVersion']),
      status: serializer.fromJson<ActivityRecordStatus>(json['status']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lifeDay': serializer.toJson<LifeDay>(lifeDay),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'category': serializer.toJson<ActivityCategory>(category),
      'subcategory': serializer.toJson<ActivitySubcategory>(subcategory),
      'duration': serializer.toJson<DurationSlot>(duration),
      'theoreticalDelta': serializer.toJson<int>(theoreticalDelta),
      'appliedDelta': serializer.toJson<int>(appliedDelta),
      'ruleVersion': serializer.toJson<String>(ruleVersion),
      'status': serializer.toJson<ActivityRecordStatus>(status),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ActivityRecordRow copyWith({
    String? id,
    LifeDay? lifeDay,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    ActivityCategory? category,
    ActivitySubcategory? subcategory,
    DurationSlot? duration,
    int? theoreticalDelta,
    int? appliedDelta,
    String? ruleVersion,
    ActivityRecordStatus? status,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ActivityRecordRow(
    id: id ?? this.id,
    lifeDay: lifeDay ?? this.lifeDay,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    category: category ?? this.category,
    subcategory: subcategory ?? this.subcategory,
    duration: duration ?? this.duration,
    theoreticalDelta: theoreticalDelta ?? this.theoreticalDelta,
    appliedDelta: appliedDelta ?? this.appliedDelta,
    ruleVersion: ruleVersion ?? this.ruleVersion,
    status: status ?? this.status,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ActivityRecordRow copyWithCompanion(ActivityRecordsTableCompanion data) {
    return ActivityRecordRow(
      id: data.id.present ? data.id.value : this.id,
      lifeDay: data.lifeDay.present ? data.lifeDay.value : this.lifeDay,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      duration: data.duration.present ? data.duration.value : this.duration,
      theoreticalDelta: data.theoreticalDelta.present
          ? data.theoreticalDelta.value
          : this.theoreticalDelta,
      appliedDelta: data.appliedDelta.present
          ? data.appliedDelta.value
          : this.appliedDelta,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
      status: data.status.present ? data.status.value : this.status,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRecordRow(')
          ..write('id: $id, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('duration: $duration, ')
          ..write('theoreticalDelta: $theoreticalDelta, ')
          ..write('appliedDelta: $appliedDelta, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('status: $status, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lifeDay,
    completedAt,
    createdAt,
    updatedAt,
    category,
    subcategory,
    duration,
    theoreticalDelta,
    appliedDelta,
    ruleVersion,
    status,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRecordRow &&
          other.id == this.id &&
          other.lifeDay == this.lifeDay &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.duration == this.duration &&
          other.theoreticalDelta == this.theoreticalDelta &&
          other.appliedDelta == this.appliedDelta &&
          other.ruleVersion == this.ruleVersion &&
          other.status == this.status &&
          other.deletedAt == this.deletedAt);
}

class ActivityRecordsTableCompanion extends UpdateCompanion<ActivityRecordRow> {
  final Value<String> id;
  final Value<LifeDay> lifeDay;
  final Value<DateTime> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<ActivityCategory> category;
  final Value<ActivitySubcategory> subcategory;
  final Value<DurationSlot> duration;
  final Value<int> theoreticalDelta;
  final Value<int> appliedDelta;
  final Value<String> ruleVersion;
  final Value<ActivityRecordStatus> status;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ActivityRecordsTableCompanion({
    this.id = const Value.absent(),
    this.lifeDay = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.duration = const Value.absent(),
    this.theoreticalDelta = const Value.absent(),
    this.appliedDelta = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityRecordsTableCompanion.insert({
    required String id,
    required LifeDay lifeDay,
    required DateTime completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ActivityCategory category,
    required ActivitySubcategory subcategory,
    required DurationSlot duration,
    required int theoreticalDelta,
    required int appliedDelta,
    required String ruleVersion,
    required ActivityRecordStatus status,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lifeDay = Value(lifeDay),
       completedAt = Value(completedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       category = Value(category),
       subcategory = Value(subcategory),
       duration = Value(duration),
       theoreticalDelta = Value(theoreticalDelta),
       appliedDelta = Value(appliedDelta),
       ruleVersion = Value(ruleVersion),
       status = Value(status);
  static Insertable<ActivityRecordRow> custom({
    Expression<String>? id,
    Expression<String>? lifeDay,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<int>? duration,
    Expression<int>? theoreticalDelta,
    Expression<int>? appliedDelta,
    Expression<String>? ruleVersion,
    Expression<String>? status,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lifeDay != null) 'life_day': lifeDay,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (duration != null) 'duration_minutes': duration,
      if (theoreticalDelta != null) 'theoretical_delta': theoreticalDelta,
      if (appliedDelta != null) 'applied_delta': appliedDelta,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (status != null) 'status': status,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityRecordsTableCompanion copyWith({
    Value<String>? id,
    Value<LifeDay>? lifeDay,
    Value<DateTime>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<ActivityCategory>? category,
    Value<ActivitySubcategory>? subcategory,
    Value<DurationSlot>? duration,
    Value<int>? theoreticalDelta,
    Value<int>? appliedDelta,
    Value<String>? ruleVersion,
    Value<ActivityRecordStatus>? status,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ActivityRecordsTableCompanion(
      id: id ?? this.id,
      lifeDay: lifeDay ?? this.lifeDay,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      duration: duration ?? this.duration,
      theoreticalDelta: theoreticalDelta ?? this.theoreticalDelta,
      appliedDelta: appliedDelta ?? this.appliedDelta,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lifeDay.present) {
      map['life_day'] = Variable<String>(
        $ActivityRecordsTableTable.$converterlifeDay.toSql(lifeDay.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $ActivityRecordsTableTable.$convertercategory.toSql(category.value),
      );
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(
        $ActivityRecordsTableTable.$convertersubcategory.toSql(
          subcategory.value,
        ),
      );
    }
    if (duration.present) {
      map['duration_minutes'] = Variable<int>(
        $ActivityRecordsTableTable.$converterduration.toSql(duration.value),
      );
    }
    if (theoreticalDelta.present) {
      map['theoretical_delta'] = Variable<int>(theoreticalDelta.value);
    }
    if (appliedDelta.present) {
      map['applied_delta'] = Variable<int>(appliedDelta.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<String>(ruleVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ActivityRecordsTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('duration: $duration, ')
          ..write('theoreticalDelta: $theoreticalDelta, ')
          ..write('appliedDelta: $appliedDelta, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('status: $status, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnergyObservationsTableTable extends EnergyObservationsTable
    with TableInfo<$EnergyObservationsTableTable, EnergyObservationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnergyObservationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay, String> lifeDay =
      GeneratedColumn<String>(
        'life_day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LifeDay>($EnergyObservationsTableTable.$converterlifeDay);
  @override
  late final GeneratedColumnWithTypeConverter<EnergyObservationType, String>
  type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EnergyObservationType>(
        $EnergyObservationsTableTable.$convertertype,
      );
  @override
  late final GeneratedColumnWithTypeConverter<AbsoluteEnergyState?, String>
  absoluteState =
      GeneratedColumn<String>(
        'absolute_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<AbsoluteEnergyState?>(
        $EnergyObservationsTableTable.$converterabsoluteStaten,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RelativeCorrection?, String>
  relativeState =
      GeneratedColumn<String>(
        'relative_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<RelativeCorrection?>(
        $EnergyObservationsTableTable.$converterrelativeStaten,
      );
  static const VerificationMeta _estimateAtObservationMeta =
      const VerificationMeta('estimateAtObservation');
  @override
  late final GeneratedColumn<int> estimateAtObservation = GeneratedColumn<int>(
    'estimate_at_observation',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lifeDay,
    type,
    absoluteState,
    relativeState,
    estimateAtObservation,
    observedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'energy_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnergyObservationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('estimate_at_observation')) {
      context.handle(
        _estimateAtObservationMeta,
        estimateAtObservation.isAcceptableOrUnknown(
          data['estimate_at_observation']!,
          _estimateAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnergyObservationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnergyObservationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lifeDay: $EnergyObservationsTableTable.$converterlifeDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}life_day'],
        )!,
      ),
      type: $EnergyObservationsTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      absoluteState: $EnergyObservationsTableTable.$converterabsoluteStaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}absolute_state'],
            ),
          ),
      relativeState: $EnergyObservationsTableTable.$converterrelativeStaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}relative_state'],
            ),
          ),
      estimateAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_at_observation'],
      ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
    );
  }

  @override
  $EnergyObservationsTableTable createAlias(String alias) {
    return $EnergyObservationsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterlifeDay =
      const LifeDayConverter();
  static TypeConverter<EnergyObservationType, String> $convertertype =
      const EnergyObservationTypeConverter();
  static TypeConverter<AbsoluteEnergyState, String> $converterabsoluteState =
      const AbsoluteEnergyStateConverter();
  static TypeConverter<AbsoluteEnergyState?, String?> $converterabsoluteStaten =
      NullAwareTypeConverter.wrap($converterabsoluteState);
  static TypeConverter<RelativeCorrection, String> $converterrelativeState =
      const RelativeCorrectionConverter();
  static TypeConverter<RelativeCorrection?, String?> $converterrelativeStaten =
      NullAwareTypeConverter.wrap($converterrelativeState);
}

class EnergyObservationRow extends DataClass
    implements Insertable<EnergyObservationRow> {
  final String id;
  final LifeDay lifeDay;
  final EnergyObservationType type;
  final AbsoluteEnergyState? absoluteState;
  final RelativeCorrection? relativeState;
  final int? estimateAtObservation;
  final DateTime observedAt;
  const EnergyObservationRow({
    required this.id,
    required this.lifeDay,
    required this.type,
    this.absoluteState,
    this.relativeState,
    this.estimateAtObservation,
    required this.observedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['life_day'] = Variable<String>(
        $EnergyObservationsTableTable.$converterlifeDay.toSql(lifeDay),
      );
    }
    {
      map['type'] = Variable<String>(
        $EnergyObservationsTableTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || absoluteState != null) {
      map['absolute_state'] = Variable<String>(
        $EnergyObservationsTableTable.$converterabsoluteStaten.toSql(
          absoluteState,
        ),
      );
    }
    if (!nullToAbsent || relativeState != null) {
      map['relative_state'] = Variable<String>(
        $EnergyObservationsTableTable.$converterrelativeStaten.toSql(
          relativeState,
        ),
      );
    }
    if (!nullToAbsent || estimateAtObservation != null) {
      map['estimate_at_observation'] = Variable<int>(estimateAtObservation);
    }
    map['observed_at'] = Variable<DateTime>(observedAt);
    return map;
  }

  EnergyObservationsTableCompanion toCompanion(bool nullToAbsent) {
    return EnergyObservationsTableCompanion(
      id: Value(id),
      lifeDay: Value(lifeDay),
      type: Value(type),
      absoluteState: absoluteState == null && nullToAbsent
          ? const Value.absent()
          : Value(absoluteState),
      relativeState: relativeState == null && nullToAbsent
          ? const Value.absent()
          : Value(relativeState),
      estimateAtObservation: estimateAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateAtObservation),
      observedAt: Value(observedAt),
    );
  }

  factory EnergyObservationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnergyObservationRow(
      id: serializer.fromJson<String>(json['id']),
      lifeDay: serializer.fromJson<LifeDay>(json['lifeDay']),
      type: serializer.fromJson<EnergyObservationType>(json['type']),
      absoluteState: serializer.fromJson<AbsoluteEnergyState?>(
        json['absoluteState'],
      ),
      relativeState: serializer.fromJson<RelativeCorrection?>(
        json['relativeState'],
      ),
      estimateAtObservation: serializer.fromJson<int?>(
        json['estimateAtObservation'],
      ),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lifeDay': serializer.toJson<LifeDay>(lifeDay),
      'type': serializer.toJson<EnergyObservationType>(type),
      'absoluteState': serializer.toJson<AbsoluteEnergyState?>(absoluteState),
      'relativeState': serializer.toJson<RelativeCorrection?>(relativeState),
      'estimateAtObservation': serializer.toJson<int?>(estimateAtObservation),
      'observedAt': serializer.toJson<DateTime>(observedAt),
    };
  }

  EnergyObservationRow copyWith({
    String? id,
    LifeDay? lifeDay,
    EnergyObservationType? type,
    Value<AbsoluteEnergyState?> absoluteState = const Value.absent(),
    Value<RelativeCorrection?> relativeState = const Value.absent(),
    Value<int?> estimateAtObservation = const Value.absent(),
    DateTime? observedAt,
  }) => EnergyObservationRow(
    id: id ?? this.id,
    lifeDay: lifeDay ?? this.lifeDay,
    type: type ?? this.type,
    absoluteState: absoluteState.present
        ? absoluteState.value
        : this.absoluteState,
    relativeState: relativeState.present
        ? relativeState.value
        : this.relativeState,
    estimateAtObservation: estimateAtObservation.present
        ? estimateAtObservation.value
        : this.estimateAtObservation,
    observedAt: observedAt ?? this.observedAt,
  );
  EnergyObservationRow copyWithCompanion(
    EnergyObservationsTableCompanion data,
  ) {
    return EnergyObservationRow(
      id: data.id.present ? data.id.value : this.id,
      lifeDay: data.lifeDay.present ? data.lifeDay.value : this.lifeDay,
      type: data.type.present ? data.type.value : this.type,
      absoluteState: data.absoluteState.present
          ? data.absoluteState.value
          : this.absoluteState,
      relativeState: data.relativeState.present
          ? data.relativeState.value
          : this.relativeState,
      estimateAtObservation: data.estimateAtObservation.present
          ? data.estimateAtObservation.value
          : this.estimateAtObservation,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnergyObservationRow(')
          ..write('id: $id, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('type: $type, ')
          ..write('absoluteState: $absoluteState, ')
          ..write('relativeState: $relativeState, ')
          ..write('estimateAtObservation: $estimateAtObservation, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lifeDay,
    type,
    absoluteState,
    relativeState,
    estimateAtObservation,
    observedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnergyObservationRow &&
          other.id == this.id &&
          other.lifeDay == this.lifeDay &&
          other.type == this.type &&
          other.absoluteState == this.absoluteState &&
          other.relativeState == this.relativeState &&
          other.estimateAtObservation == this.estimateAtObservation &&
          other.observedAt == this.observedAt);
}

class EnergyObservationsTableCompanion
    extends UpdateCompanion<EnergyObservationRow> {
  final Value<String> id;
  final Value<LifeDay> lifeDay;
  final Value<EnergyObservationType> type;
  final Value<AbsoluteEnergyState?> absoluteState;
  final Value<RelativeCorrection?> relativeState;
  final Value<int?> estimateAtObservation;
  final Value<DateTime> observedAt;
  final Value<int> rowid;
  const EnergyObservationsTableCompanion({
    this.id = const Value.absent(),
    this.lifeDay = const Value.absent(),
    this.type = const Value.absent(),
    this.absoluteState = const Value.absent(),
    this.relativeState = const Value.absent(),
    this.estimateAtObservation = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnergyObservationsTableCompanion.insert({
    required String id,
    required LifeDay lifeDay,
    required EnergyObservationType type,
    this.absoluteState = const Value.absent(),
    this.relativeState = const Value.absent(),
    this.estimateAtObservation = const Value.absent(),
    required DateTime observedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lifeDay = Value(lifeDay),
       type = Value(type),
       observedAt = Value(observedAt);
  static Insertable<EnergyObservationRow> custom({
    Expression<String>? id,
    Expression<String>? lifeDay,
    Expression<String>? type,
    Expression<String>? absoluteState,
    Expression<String>? relativeState,
    Expression<int>? estimateAtObservation,
    Expression<DateTime>? observedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lifeDay != null) 'life_day': lifeDay,
      if (type != null) 'type': type,
      if (absoluteState != null) 'absolute_state': absoluteState,
      if (relativeState != null) 'relative_state': relativeState,
      if (estimateAtObservation != null)
        'estimate_at_observation': estimateAtObservation,
      if (observedAt != null) 'observed_at': observedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnergyObservationsTableCompanion copyWith({
    Value<String>? id,
    Value<LifeDay>? lifeDay,
    Value<EnergyObservationType>? type,
    Value<AbsoluteEnergyState?>? absoluteState,
    Value<RelativeCorrection?>? relativeState,
    Value<int?>? estimateAtObservation,
    Value<DateTime>? observedAt,
    Value<int>? rowid,
  }) {
    return EnergyObservationsTableCompanion(
      id: id ?? this.id,
      lifeDay: lifeDay ?? this.lifeDay,
      type: type ?? this.type,
      absoluteState: absoluteState ?? this.absoluteState,
      relativeState: relativeState ?? this.relativeState,
      estimateAtObservation:
          estimateAtObservation ?? this.estimateAtObservation,
      observedAt: observedAt ?? this.observedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lifeDay.present) {
      map['life_day'] = Variable<String>(
        $EnergyObservationsTableTable.$converterlifeDay.toSql(lifeDay.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $EnergyObservationsTableTable.$convertertype.toSql(type.value),
      );
    }
    if (absoluteState.present) {
      map['absolute_state'] = Variable<String>(
        $EnergyObservationsTableTable.$converterabsoluteStaten.toSql(
          absoluteState.value,
        ),
      );
    }
    if (relativeState.present) {
      map['relative_state'] = Variable<String>(
        $EnergyObservationsTableTable.$converterrelativeStaten.toSql(
          relativeState.value,
        ),
      );
    }
    if (estimateAtObservation.present) {
      map['estimate_at_observation'] = Variable<int>(
        estimateAtObservation.value,
      );
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnergyObservationsTableCompanion(')
          ..write('id: $id, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('type: $type, ')
          ..write('absoluteState: $absoluteState, ')
          ..write('relativeState: $relativeState, ')
          ..write('estimateAtObservation: $estimateAtObservation, ')
          ..write('observedAt: $observedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailySummariesTableTable extends DailySummariesTable
    with TableInfo<$DailySummariesTableTable, DailySummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySummariesTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay, String> lifeDay =
      GeneratedColumn<String>(
        'life_day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LifeDay>($DailySummariesTableTable.$converterlifeDay);
  static const VerificationMeta _baseEstimatedEnergyMeta =
      const VerificationMeta('baseEstimatedEnergy');
  @override
  late final GeneratedColumn<int> baseEstimatedEnergy = GeneratedColumn<int>(
    'base_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  @override
  late final GeneratedColumn<String> ruleVersion = GeneratedColumn<String>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _morningAdjustmentMeta = const VerificationMeta(
    'morningAdjustment',
  );
  @override
  late final GeneratedColumn<int> morningAdjustment = GeneratedColumn<int>(
    'morning_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortTermAdjustmentMeta =
      const VerificationMeta('shortTermAdjustment');
  @override
  late final GeneratedColumn<int> shortTermAdjustment = GeneratedColumn<int>(
    'short_term_adjustment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialEstimatedEnergyMeta =
      const VerificationMeta('initialEstimatedEnergy');
  @override
  late final GeneratedColumn<int> initialEstimatedEnergy = GeneratedColumn<int>(
    'initial_estimated_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalEstimatedEnergyMeta =
      const VerificationMeta('finalEstimatedEnergy');
  @override
  late final GeneratedColumn<int> finalEstimatedEnergy = GeneratedColumn<int>(
    'final_estimated_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalConsumptionMeta = const VerificationMeta(
    'totalConsumption',
  );
  @override
  late final GeneratedColumn<int> totalConsumption = GeneratedColumn<int>(
    'total_consumption',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalRecoveryMeta = const VerificationMeta(
    'totalRecovery',
  );
  @override
  late final GeneratedColumn<int> totalRecovery = GeneratedColumn<int>(
    'total_recovery',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorySummaryJsonMeta =
      const VerificationMeta('categorySummaryJson');
  @override
  late final GeneratedColumn<String> categorySummaryJson =
      GeneratedColumn<String>(
        'category_summary_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isStandardEffectiveDayMeta =
      const VerificationMeta('isStandardEffectiveDay');
  @override
  late final GeneratedColumn<bool> isStandardEffectiveDay =
      GeneratedColumn<bool>(
        'is_standard_effective_day',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_standard_effective_day" IN (0, 1))',
        ),
      );
  static const VerificationMeta _isWeakEffectiveDayMeta =
      const VerificationMeta('isWeakEffectiveDay');
  @override
  late final GeneratedColumn<bool> isWeakEffectiveDay = GeneratedColumn<bool>(
    'is_weak_effective_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_weak_effective_day" IN (0, 1))',
    ),
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lifeDay,
    baseEstimatedEnergy,
    ruleVersion,
    morningAdjustment,
    shortTermAdjustment,
    initialEstimatedEnergy,
    finalEstimatedEnergy,
    totalConsumption,
    totalRecovery,
    categorySummaryJson,
    isStandardEffectiveDay,
    isWeakEffectiveDay,
    settledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailySummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('base_energy')) {
      context.handle(
        _baseEstimatedEnergyMeta,
        baseEstimatedEnergy.isAcceptableOrUnknown(
          data['base_energy']!,
          _baseEstimatedEnergyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseEstimatedEnergyMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionMeta);
    }
    if (data.containsKey('morning_adjustment')) {
      context.handle(
        _morningAdjustmentMeta,
        morningAdjustment.isAcceptableOrUnknown(
          data['morning_adjustment']!,
          _morningAdjustmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_morningAdjustmentMeta);
    }
    if (data.containsKey('short_term_adjustment')) {
      context.handle(
        _shortTermAdjustmentMeta,
        shortTermAdjustment.isAcceptableOrUnknown(
          data['short_term_adjustment']!,
          _shortTermAdjustmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shortTermAdjustmentMeta);
    }
    if (data.containsKey('initial_estimated_energy')) {
      context.handle(
        _initialEstimatedEnergyMeta,
        initialEstimatedEnergy.isAcceptableOrUnknown(
          data['initial_estimated_energy']!,
          _initialEstimatedEnergyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialEstimatedEnergyMeta);
    }
    if (data.containsKey('final_estimated_energy')) {
      context.handle(
        _finalEstimatedEnergyMeta,
        finalEstimatedEnergy.isAcceptableOrUnknown(
          data['final_estimated_energy']!,
          _finalEstimatedEnergyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finalEstimatedEnergyMeta);
    }
    if (data.containsKey('total_consumption')) {
      context.handle(
        _totalConsumptionMeta,
        totalConsumption.isAcceptableOrUnknown(
          data['total_consumption']!,
          _totalConsumptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalConsumptionMeta);
    }
    if (data.containsKey('total_recovery')) {
      context.handle(
        _totalRecoveryMeta,
        totalRecovery.isAcceptableOrUnknown(
          data['total_recovery']!,
          _totalRecoveryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalRecoveryMeta);
    }
    if (data.containsKey('category_summary_json')) {
      context.handle(
        _categorySummaryJsonMeta,
        categorySummaryJson.isAcceptableOrUnknown(
          data['category_summary_json']!,
          _categorySummaryJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categorySummaryJsonMeta);
    }
    if (data.containsKey('is_standard_effective_day')) {
      context.handle(
        _isStandardEffectiveDayMeta,
        isStandardEffectiveDay.isAcceptableOrUnknown(
          data['is_standard_effective_day']!,
          _isStandardEffectiveDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isStandardEffectiveDayMeta);
    }
    if (data.containsKey('is_weak_effective_day')) {
      context.handle(
        _isWeakEffectiveDayMeta,
        isWeakEffectiveDay.isAcceptableOrUnknown(
          data['is_weak_effective_day']!,
          _isWeakEffectiveDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isWeakEffectiveDayMeta);
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_settledAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lifeDay};
  @override
  DailySummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySummaryRow(
      lifeDay: $DailySummariesTableTable.$converterlifeDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}life_day'],
        )!,
      ),
      baseEstimatedEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_energy'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version'],
      )!,
      morningAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}morning_adjustment'],
      )!,
      shortTermAdjustment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}short_term_adjustment'],
      )!,
      initialEstimatedEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_estimated_energy'],
      )!,
      finalEstimatedEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_estimated_energy'],
      )!,
      totalConsumption: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_consumption'],
      )!,
      totalRecovery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_recovery'],
      )!,
      categorySummaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_summary_json'],
      )!,
      isStandardEffectiveDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_standard_effective_day'],
      )!,
      isWeakEffectiveDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_weak_effective_day'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      )!,
    );
  }

  @override
  $DailySummariesTableTable createAlias(String alias) {
    return $DailySummariesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterlifeDay =
      const LifeDayConverter();
}

class DailySummaryRow extends DataClass implements Insertable<DailySummaryRow> {
  final LifeDay lifeDay;
  final int baseEstimatedEnergy;
  final String ruleVersion;
  final int morningAdjustment;
  final int shortTermAdjustment;
  final int initialEstimatedEnergy;
  final int finalEstimatedEnergy;
  final int totalConsumption;
  final int totalRecovery;
  final String categorySummaryJson;
  final bool isStandardEffectiveDay;
  final bool isWeakEffectiveDay;
  final DateTime settledAt;
  const DailySummaryRow({
    required this.lifeDay,
    required this.baseEstimatedEnergy,
    required this.ruleVersion,
    required this.morningAdjustment,
    required this.shortTermAdjustment,
    required this.initialEstimatedEnergy,
    required this.finalEstimatedEnergy,
    required this.totalConsumption,
    required this.totalRecovery,
    required this.categorySummaryJson,
    required this.isStandardEffectiveDay,
    required this.isWeakEffectiveDay,
    required this.settledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['life_day'] = Variable<String>(
        $DailySummariesTableTable.$converterlifeDay.toSql(lifeDay),
      );
    }
    map['base_energy'] = Variable<int>(baseEstimatedEnergy);
    map['rule_version'] = Variable<String>(ruleVersion);
    map['morning_adjustment'] = Variable<int>(morningAdjustment);
    map['short_term_adjustment'] = Variable<int>(shortTermAdjustment);
    map['initial_estimated_energy'] = Variable<int>(initialEstimatedEnergy);
    map['final_estimated_energy'] = Variable<int>(finalEstimatedEnergy);
    map['total_consumption'] = Variable<int>(totalConsumption);
    map['total_recovery'] = Variable<int>(totalRecovery);
    map['category_summary_json'] = Variable<String>(categorySummaryJson);
    map['is_standard_effective_day'] = Variable<bool>(isStandardEffectiveDay);
    map['is_weak_effective_day'] = Variable<bool>(isWeakEffectiveDay);
    map['settled_at'] = Variable<DateTime>(settledAt);
    return map;
  }

  DailySummariesTableCompanion toCompanion(bool nullToAbsent) {
    return DailySummariesTableCompanion(
      lifeDay: Value(lifeDay),
      baseEstimatedEnergy: Value(baseEstimatedEnergy),
      ruleVersion: Value(ruleVersion),
      morningAdjustment: Value(morningAdjustment),
      shortTermAdjustment: Value(shortTermAdjustment),
      initialEstimatedEnergy: Value(initialEstimatedEnergy),
      finalEstimatedEnergy: Value(finalEstimatedEnergy),
      totalConsumption: Value(totalConsumption),
      totalRecovery: Value(totalRecovery),
      categorySummaryJson: Value(categorySummaryJson),
      isStandardEffectiveDay: Value(isStandardEffectiveDay),
      isWeakEffectiveDay: Value(isWeakEffectiveDay),
      settledAt: Value(settledAt),
    );
  }

  factory DailySummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySummaryRow(
      lifeDay: serializer.fromJson<LifeDay>(json['lifeDay']),
      baseEstimatedEnergy: serializer.fromJson<int>(
        json['baseEstimatedEnergy'],
      ),
      ruleVersion: serializer.fromJson<String>(json['ruleVersion']),
      morningAdjustment: serializer.fromJson<int>(json['morningAdjustment']),
      shortTermAdjustment: serializer.fromJson<int>(
        json['shortTermAdjustment'],
      ),
      initialEstimatedEnergy: serializer.fromJson<int>(
        json['initialEstimatedEnergy'],
      ),
      finalEstimatedEnergy: serializer.fromJson<int>(
        json['finalEstimatedEnergy'],
      ),
      totalConsumption: serializer.fromJson<int>(json['totalConsumption']),
      totalRecovery: serializer.fromJson<int>(json['totalRecovery']),
      categorySummaryJson: serializer.fromJson<String>(
        json['categorySummaryJson'],
      ),
      isStandardEffectiveDay: serializer.fromJson<bool>(
        json['isStandardEffectiveDay'],
      ),
      isWeakEffectiveDay: serializer.fromJson<bool>(json['isWeakEffectiveDay']),
      settledAt: serializer.fromJson<DateTime>(json['settledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lifeDay': serializer.toJson<LifeDay>(lifeDay),
      'baseEstimatedEnergy': serializer.toJson<int>(baseEstimatedEnergy),
      'ruleVersion': serializer.toJson<String>(ruleVersion),
      'morningAdjustment': serializer.toJson<int>(morningAdjustment),
      'shortTermAdjustment': serializer.toJson<int>(shortTermAdjustment),
      'initialEstimatedEnergy': serializer.toJson<int>(initialEstimatedEnergy),
      'finalEstimatedEnergy': serializer.toJson<int>(finalEstimatedEnergy),
      'totalConsumption': serializer.toJson<int>(totalConsumption),
      'totalRecovery': serializer.toJson<int>(totalRecovery),
      'categorySummaryJson': serializer.toJson<String>(categorySummaryJson),
      'isStandardEffectiveDay': serializer.toJson<bool>(isStandardEffectiveDay),
      'isWeakEffectiveDay': serializer.toJson<bool>(isWeakEffectiveDay),
      'settledAt': serializer.toJson<DateTime>(settledAt),
    };
  }

  DailySummaryRow copyWith({
    LifeDay? lifeDay,
    int? baseEstimatedEnergy,
    String? ruleVersion,
    int? morningAdjustment,
    int? shortTermAdjustment,
    int? initialEstimatedEnergy,
    int? finalEstimatedEnergy,
    int? totalConsumption,
    int? totalRecovery,
    String? categorySummaryJson,
    bool? isStandardEffectiveDay,
    bool? isWeakEffectiveDay,
    DateTime? settledAt,
  }) => DailySummaryRow(
    lifeDay: lifeDay ?? this.lifeDay,
    baseEstimatedEnergy: baseEstimatedEnergy ?? this.baseEstimatedEnergy,
    ruleVersion: ruleVersion ?? this.ruleVersion,
    morningAdjustment: morningAdjustment ?? this.morningAdjustment,
    shortTermAdjustment: shortTermAdjustment ?? this.shortTermAdjustment,
    initialEstimatedEnergy:
        initialEstimatedEnergy ?? this.initialEstimatedEnergy,
    finalEstimatedEnergy: finalEstimatedEnergy ?? this.finalEstimatedEnergy,
    totalConsumption: totalConsumption ?? this.totalConsumption,
    totalRecovery: totalRecovery ?? this.totalRecovery,
    categorySummaryJson: categorySummaryJson ?? this.categorySummaryJson,
    isStandardEffectiveDay:
        isStandardEffectiveDay ?? this.isStandardEffectiveDay,
    isWeakEffectiveDay: isWeakEffectiveDay ?? this.isWeakEffectiveDay,
    settledAt: settledAt ?? this.settledAt,
  );
  DailySummaryRow copyWithCompanion(DailySummariesTableCompanion data) {
    return DailySummaryRow(
      lifeDay: data.lifeDay.present ? data.lifeDay.value : this.lifeDay,
      baseEstimatedEnergy: data.baseEstimatedEnergy.present
          ? data.baseEstimatedEnergy.value
          : this.baseEstimatedEnergy,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
      morningAdjustment: data.morningAdjustment.present
          ? data.morningAdjustment.value
          : this.morningAdjustment,
      shortTermAdjustment: data.shortTermAdjustment.present
          ? data.shortTermAdjustment.value
          : this.shortTermAdjustment,
      initialEstimatedEnergy: data.initialEstimatedEnergy.present
          ? data.initialEstimatedEnergy.value
          : this.initialEstimatedEnergy,
      finalEstimatedEnergy: data.finalEstimatedEnergy.present
          ? data.finalEstimatedEnergy.value
          : this.finalEstimatedEnergy,
      totalConsumption: data.totalConsumption.present
          ? data.totalConsumption.value
          : this.totalConsumption,
      totalRecovery: data.totalRecovery.present
          ? data.totalRecovery.value
          : this.totalRecovery,
      categorySummaryJson: data.categorySummaryJson.present
          ? data.categorySummaryJson.value
          : this.categorySummaryJson,
      isStandardEffectiveDay: data.isStandardEffectiveDay.present
          ? data.isStandardEffectiveDay.value
          : this.isStandardEffectiveDay,
      isWeakEffectiveDay: data.isWeakEffectiveDay.present
          ? data.isWeakEffectiveDay.value
          : this.isWeakEffectiveDay,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySummaryRow(')
          ..write('lifeDay: $lifeDay, ')
          ..write('baseEstimatedEnergy: $baseEstimatedEnergy, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('morningAdjustment: $morningAdjustment, ')
          ..write('shortTermAdjustment: $shortTermAdjustment, ')
          ..write('initialEstimatedEnergy: $initialEstimatedEnergy, ')
          ..write('finalEstimatedEnergy: $finalEstimatedEnergy, ')
          ..write('totalConsumption: $totalConsumption, ')
          ..write('totalRecovery: $totalRecovery, ')
          ..write('categorySummaryJson: $categorySummaryJson, ')
          ..write('isStandardEffectiveDay: $isStandardEffectiveDay, ')
          ..write('isWeakEffectiveDay: $isWeakEffectiveDay, ')
          ..write('settledAt: $settledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lifeDay,
    baseEstimatedEnergy,
    ruleVersion,
    morningAdjustment,
    shortTermAdjustment,
    initialEstimatedEnergy,
    finalEstimatedEnergy,
    totalConsumption,
    totalRecovery,
    categorySummaryJson,
    isStandardEffectiveDay,
    isWeakEffectiveDay,
    settledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySummaryRow &&
          other.lifeDay == this.lifeDay &&
          other.baseEstimatedEnergy == this.baseEstimatedEnergy &&
          other.ruleVersion == this.ruleVersion &&
          other.morningAdjustment == this.morningAdjustment &&
          other.shortTermAdjustment == this.shortTermAdjustment &&
          other.initialEstimatedEnergy == this.initialEstimatedEnergy &&
          other.finalEstimatedEnergy == this.finalEstimatedEnergy &&
          other.totalConsumption == this.totalConsumption &&
          other.totalRecovery == this.totalRecovery &&
          other.categorySummaryJson == this.categorySummaryJson &&
          other.isStandardEffectiveDay == this.isStandardEffectiveDay &&
          other.isWeakEffectiveDay == this.isWeakEffectiveDay &&
          other.settledAt == this.settledAt);
}

class DailySummariesTableCompanion extends UpdateCompanion<DailySummaryRow> {
  final Value<LifeDay> lifeDay;
  final Value<int> baseEstimatedEnergy;
  final Value<String> ruleVersion;
  final Value<int> morningAdjustment;
  final Value<int> shortTermAdjustment;
  final Value<int> initialEstimatedEnergy;
  final Value<int> finalEstimatedEnergy;
  final Value<int> totalConsumption;
  final Value<int> totalRecovery;
  final Value<String> categorySummaryJson;
  final Value<bool> isStandardEffectiveDay;
  final Value<bool> isWeakEffectiveDay;
  final Value<DateTime> settledAt;
  final Value<int> rowid;
  const DailySummariesTableCompanion({
    this.lifeDay = const Value.absent(),
    this.baseEstimatedEnergy = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.morningAdjustment = const Value.absent(),
    this.shortTermAdjustment = const Value.absent(),
    this.initialEstimatedEnergy = const Value.absent(),
    this.finalEstimatedEnergy = const Value.absent(),
    this.totalConsumption = const Value.absent(),
    this.totalRecovery = const Value.absent(),
    this.categorySummaryJson = const Value.absent(),
    this.isStandardEffectiveDay = const Value.absent(),
    this.isWeakEffectiveDay = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySummariesTableCompanion.insert({
    required LifeDay lifeDay,
    required int baseEstimatedEnergy,
    required String ruleVersion,
    required int morningAdjustment,
    required int shortTermAdjustment,
    required int initialEstimatedEnergy,
    required int finalEstimatedEnergy,
    required int totalConsumption,
    required int totalRecovery,
    required String categorySummaryJson,
    required bool isStandardEffectiveDay,
    required bool isWeakEffectiveDay,
    required DateTime settledAt,
    this.rowid = const Value.absent(),
  }) : lifeDay = Value(lifeDay),
       baseEstimatedEnergy = Value(baseEstimatedEnergy),
       ruleVersion = Value(ruleVersion),
       morningAdjustment = Value(morningAdjustment),
       shortTermAdjustment = Value(shortTermAdjustment),
       initialEstimatedEnergy = Value(initialEstimatedEnergy),
       finalEstimatedEnergy = Value(finalEstimatedEnergy),
       totalConsumption = Value(totalConsumption),
       totalRecovery = Value(totalRecovery),
       categorySummaryJson = Value(categorySummaryJson),
       isStandardEffectiveDay = Value(isStandardEffectiveDay),
       isWeakEffectiveDay = Value(isWeakEffectiveDay),
       settledAt = Value(settledAt);
  static Insertable<DailySummaryRow> custom({
    Expression<String>? lifeDay,
    Expression<int>? baseEstimatedEnergy,
    Expression<String>? ruleVersion,
    Expression<int>? morningAdjustment,
    Expression<int>? shortTermAdjustment,
    Expression<int>? initialEstimatedEnergy,
    Expression<int>? finalEstimatedEnergy,
    Expression<int>? totalConsumption,
    Expression<int>? totalRecovery,
    Expression<String>? categorySummaryJson,
    Expression<bool>? isStandardEffectiveDay,
    Expression<bool>? isWeakEffectiveDay,
    Expression<DateTime>? settledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lifeDay != null) 'life_day': lifeDay,
      if (baseEstimatedEnergy != null) 'base_energy': baseEstimatedEnergy,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (morningAdjustment != null) 'morning_adjustment': morningAdjustment,
      if (shortTermAdjustment != null)
        'short_term_adjustment': shortTermAdjustment,
      if (initialEstimatedEnergy != null)
        'initial_estimated_energy': initialEstimatedEnergy,
      if (finalEstimatedEnergy != null)
        'final_estimated_energy': finalEstimatedEnergy,
      if (totalConsumption != null) 'total_consumption': totalConsumption,
      if (totalRecovery != null) 'total_recovery': totalRecovery,
      if (categorySummaryJson != null)
        'category_summary_json': categorySummaryJson,
      if (isStandardEffectiveDay != null)
        'is_standard_effective_day': isStandardEffectiveDay,
      if (isWeakEffectiveDay != null)
        'is_weak_effective_day': isWeakEffectiveDay,
      if (settledAt != null) 'settled_at': settledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySummariesTableCompanion copyWith({
    Value<LifeDay>? lifeDay,
    Value<int>? baseEstimatedEnergy,
    Value<String>? ruleVersion,
    Value<int>? morningAdjustment,
    Value<int>? shortTermAdjustment,
    Value<int>? initialEstimatedEnergy,
    Value<int>? finalEstimatedEnergy,
    Value<int>? totalConsumption,
    Value<int>? totalRecovery,
    Value<String>? categorySummaryJson,
    Value<bool>? isStandardEffectiveDay,
    Value<bool>? isWeakEffectiveDay,
    Value<DateTime>? settledAt,
    Value<int>? rowid,
  }) {
    return DailySummariesTableCompanion(
      lifeDay: lifeDay ?? this.lifeDay,
      baseEstimatedEnergy: baseEstimatedEnergy ?? this.baseEstimatedEnergy,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      morningAdjustment: morningAdjustment ?? this.morningAdjustment,
      shortTermAdjustment: shortTermAdjustment ?? this.shortTermAdjustment,
      initialEstimatedEnergy:
          initialEstimatedEnergy ?? this.initialEstimatedEnergy,
      finalEstimatedEnergy: finalEstimatedEnergy ?? this.finalEstimatedEnergy,
      totalConsumption: totalConsumption ?? this.totalConsumption,
      totalRecovery: totalRecovery ?? this.totalRecovery,
      categorySummaryJson: categorySummaryJson ?? this.categorySummaryJson,
      isStandardEffectiveDay:
          isStandardEffectiveDay ?? this.isStandardEffectiveDay,
      isWeakEffectiveDay: isWeakEffectiveDay ?? this.isWeakEffectiveDay,
      settledAt: settledAt ?? this.settledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lifeDay.present) {
      map['life_day'] = Variable<String>(
        $DailySummariesTableTable.$converterlifeDay.toSql(lifeDay.value),
      );
    }
    if (baseEstimatedEnergy.present) {
      map['base_energy'] = Variable<int>(baseEstimatedEnergy.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<String>(ruleVersion.value);
    }
    if (morningAdjustment.present) {
      map['morning_adjustment'] = Variable<int>(morningAdjustment.value);
    }
    if (shortTermAdjustment.present) {
      map['short_term_adjustment'] = Variable<int>(shortTermAdjustment.value);
    }
    if (initialEstimatedEnergy.present) {
      map['initial_estimated_energy'] = Variable<int>(
        initialEstimatedEnergy.value,
      );
    }
    if (finalEstimatedEnergy.present) {
      map['final_estimated_energy'] = Variable<int>(finalEstimatedEnergy.value);
    }
    if (totalConsumption.present) {
      map['total_consumption'] = Variable<int>(totalConsumption.value);
    }
    if (totalRecovery.present) {
      map['total_recovery'] = Variable<int>(totalRecovery.value);
    }
    if (categorySummaryJson.present) {
      map['category_summary_json'] = Variable<String>(
        categorySummaryJson.value,
      );
    }
    if (isStandardEffectiveDay.present) {
      map['is_standard_effective_day'] = Variable<bool>(
        isStandardEffectiveDay.value,
      );
    }
    if (isWeakEffectiveDay.present) {
      map['is_weak_effective_day'] = Variable<bool>(isWeakEffectiveDay.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySummariesTableCompanion(')
          ..write('lifeDay: $lifeDay, ')
          ..write('baseEstimatedEnergy: $baseEstimatedEnergy, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('morningAdjustment: $morningAdjustment, ')
          ..write('shortTermAdjustment: $shortTermAdjustment, ')
          ..write('initialEstimatedEnergy: $initialEstimatedEnergy, ')
          ..write('finalEstimatedEnergy: $finalEstimatedEnergy, ')
          ..write('totalConsumption: $totalConsumption, ')
          ..write('totalRecovery: $totalRecovery, ')
          ..write('categorySummaryJson: $categorySummaryJson, ')
          ..write('isStandardEffectiveDay: $isStandardEffectiveDay, ')
          ..write('isWeakEffectiveDay: $isWeakEffectiveDay, ')
          ..write('settledAt: $settledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromptReceiptsTableTable extends PromptReceiptsTable
    with TableInfo<$PromptReceiptsTableTable, PromptReceiptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptReceiptsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PromptReceiptType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PromptReceiptType>(
        $PromptReceiptsTableTable.$convertertype,
      );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PromptReceiptAction, String>
  action =
      GeneratedColumn<String>(
        'action',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PromptReceiptAction>(
        $PromptReceiptsTableTable.$converteraction,
      );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    scopeKey,
    action,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompt_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromptReceiptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {type, scopeKey, action},
  ];
  @override
  PromptReceiptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromptReceiptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $PromptReceiptsTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      action: $PromptReceiptsTableTable.$converteraction.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action'],
        )!,
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $PromptReceiptsTableTable createAlias(String alias) {
    return $PromptReceiptsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<PromptReceiptType, String> $convertertype =
      const PromptReceiptTypeConverter();
  static TypeConverter<PromptReceiptAction, String> $converteraction =
      const PromptReceiptActionConverter();
}

class PromptReceiptRow extends DataClass
    implements Insertable<PromptReceiptRow> {
  final String id;
  final PromptReceiptType type;
  final String scopeKey;
  final PromptReceiptAction action;
  final DateTime occurredAt;
  const PromptReceiptRow({
    required this.id,
    required this.type,
    required this.scopeKey,
    required this.action,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>(
        $PromptReceiptsTableTable.$convertertype.toSql(type),
      );
    }
    map['scope_key'] = Variable<String>(scopeKey);
    {
      map['action'] = Variable<String>(
        $PromptReceiptsTableTable.$converteraction.toSql(action),
      );
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  PromptReceiptsTableCompanion toCompanion(bool nullToAbsent) {
    return PromptReceiptsTableCompanion(
      id: Value(id),
      type: Value(type),
      scopeKey: Value(scopeKey),
      action: Value(action),
      occurredAt: Value(occurredAt),
    );
  }

  factory PromptReceiptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromptReceiptRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<PromptReceiptType>(json['type']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      action: serializer.fromJson<PromptReceiptAction>(json['action']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<PromptReceiptType>(type),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'action': serializer.toJson<PromptReceiptAction>(action),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  PromptReceiptRow copyWith({
    String? id,
    PromptReceiptType? type,
    String? scopeKey,
    PromptReceiptAction? action,
    DateTime? occurredAt,
  }) => PromptReceiptRow(
    id: id ?? this.id,
    type: type ?? this.type,
    scopeKey: scopeKey ?? this.scopeKey,
    action: action ?? this.action,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  PromptReceiptRow copyWithCompanion(PromptReceiptsTableCompanion data) {
    return PromptReceiptRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      action: data.action.present ? data.action.value : this.action,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromptReceiptRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('action: $action, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, scopeKey, action, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromptReceiptRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.scopeKey == this.scopeKey &&
          other.action == this.action &&
          other.occurredAt == this.occurredAt);
}

class PromptReceiptsTableCompanion extends UpdateCompanion<PromptReceiptRow> {
  final Value<String> id;
  final Value<PromptReceiptType> type;
  final Value<String> scopeKey;
  final Value<PromptReceiptAction> action;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const PromptReceiptsTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.action = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromptReceiptsTableCompanion.insert({
    required String id,
    required PromptReceiptType type,
    required String scopeKey,
    required PromptReceiptAction action,
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       scopeKey = Value(scopeKey),
       action = Value(action),
       occurredAt = Value(occurredAt);
  static Insertable<PromptReceiptRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? scopeKey,
    Expression<String>? action,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (action != null) 'action': action,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromptReceiptsTableCompanion copyWith({
    Value<String>? id,
    Value<PromptReceiptType>? type,
    Value<String>? scopeKey,
    Value<PromptReceiptAction>? action,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return PromptReceiptsTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      scopeKey: scopeKey ?? this.scopeKey,
      action: action ?? this.action,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $PromptReceiptsTableTable.$convertertype.toSql(type.value),
      );
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(
        $PromptReceiptsTableTable.$converteraction.toSql(action.value),
      );
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptReceiptsTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('action: $action, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $RuleConfigVersionsTableTable ruleConfigVersionsTable =
      $RuleConfigVersionsTableTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  late final $MorningCheckInsTableTable morningCheckInsTable =
      $MorningCheckInsTableTable(this);
  late final $ActivityRecordsTableTable activityRecordsTable =
      $ActivityRecordsTableTable(this);
  late final $EnergyObservationsTableTable energyObservationsTable =
      $EnergyObservationsTableTable(this);
  late final $DailySummariesTableTable dailySummariesTable =
      $DailySummariesTableTable(this);
  late final $PromptReceiptsTableTable promptReceiptsTable =
      $PromptReceiptsTableTable(this);
  late final Index activityRecordsLifeDayOrder = Index(
    'activity_records_life_day_order',
    'CREATE INDEX activity_records_life_day_order ON activity_records (life_day, completed_at, created_at, id)',
  );
  late final Index energyObservationsLifeDayTime = Index(
    'energy_observations_life_day_time',
    'CREATE INDEX energy_observations_life_day_time ON energy_observations (life_day, observed_at, id)',
  );
  late final AppSettingsDao appSettingsDao = AppSettingsDao(
    this as AppDatabase,
  );
  late final RuleConfigVersionsDao ruleConfigVersionsDao =
      RuleConfigVersionsDao(this as AppDatabase);
  late final MorningCheckInsDao morningCheckInsDao = MorningCheckInsDao(
    this as AppDatabase,
  );
  late final ActivityRecordsDao activityRecordsDao = ActivityRecordsDao(
    this as AppDatabase,
  );
  late final EnergyObservationsDao energyObservationsDao =
      EnergyObservationsDao(this as AppDatabase);
  late final DailySummariesDao dailySummariesDao = DailySummariesDao(
    this as AppDatabase,
  );
  late final PromptReceiptsDao promptReceiptsDao = PromptReceiptsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ruleConfigVersionsTable,
    appSettingsTable,
    morningCheckInsTable,
    activityRecordsTable,
    energyObservationsTable,
    dailySummariesTable,
    promptReceiptsTable,
    activityRecordsLifeDayOrder,
    energyObservationsLifeDayTime,
  ];
}

mixin _$AppSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $AppSettingsTableTable get appSettingsTable =>
      attachedDatabase.appSettingsTable;
}
mixin _$RuleConfigVersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
}
mixin _$MorningCheckInsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MorningCheckInsTableTable get morningCheckInsTable =>
      attachedDatabase.morningCheckInsTable;
}
mixin _$ActivityRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $ActivityRecordsTableTable get activityRecordsTable =>
      attachedDatabase.activityRecordsTable;
}
mixin _$EnergyObservationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EnergyObservationsTableTable get energyObservationsTable =>
      attachedDatabase.energyObservationsTable;
}
mixin _$DailySummariesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $DailySummariesTableTable get dailySummariesTable =>
      attachedDatabase.dailySummariesTable;
}
mixin _$PromptReceiptsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptReceiptsTableTable get promptReceiptsTable =>
      attachedDatabase.promptReceiptsTable;
}
