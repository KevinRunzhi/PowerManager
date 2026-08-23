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
  @override
  late final GeneratedColumnWithTypeConverter<LearningMode, String>
  baselineLearningMode =
      GeneratedColumn<String>(
        'baseline_learning_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('off'),
      ).withConverter<LearningMode>(
        $AppSettingsTableTable.$converterbaselineLearningMode,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LearningMode, String>
  activityImpactLearningMode =
      GeneratedColumn<String>(
        'activity_impact_learning_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('off'),
      ).withConverter<LearningMode>(
        $AppSettingsTableTable.$converteractivityImpactLearningMode,
      );
  static const VerificationMeta _baselineLearningSuspendedMeta =
      const VerificationMeta('baselineLearningSuspended');
  @override
  late final GeneratedColumn<bool> baselineLearningSuspended =
      GeneratedColumn<bool>(
        'baseline_learning_suspended',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("baseline_learning_suspended" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _baselineLearningSuspendedAtMeta =
      const VerificationMeta('baselineLearningSuspendedAt');
  @override
  late final GeneratedColumn<DateTime> baselineLearningSuspendedAt =
      GeneratedColumn<DateTime>(
        'baseline_learning_suspended_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _baselineLearningSuspensionReasonMeta =
      const VerificationMeta('baselineLearningSuspensionReason');
  @override
  late final GeneratedColumn<String> baselineLearningSuspensionReason =
      GeneratedColumn<String>(
        'baseline_learning_suspension_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activityImpactLearningSuspendedMeta =
      const VerificationMeta('activityImpactLearningSuspended');
  @override
  late final GeneratedColumn<bool> activityImpactLearningSuspended =
      GeneratedColumn<bool>(
        'activity_impact_learning_suspended',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("activity_impact_learning_suspended" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _activityImpactLearningSuspendedAtMeta =
      const VerificationMeta('activityImpactLearningSuspendedAt');
  @override
  late final GeneratedColumn<DateTime> activityImpactLearningSuspendedAt =
      GeneratedColumn<DateTime>(
        'activity_impact_learning_suspended_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activityImpactLearningSuspensionReasonMeta =
      const VerificationMeta('activityImpactLearningSuspensionReason');
  @override
  late final GeneratedColumn<String> activityImpactLearningSuspensionReason =
      GeneratedColumn<String>(
        'activity_impact_learning_suspension_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _baselineLearningCooldownUntilMeta =
      const VerificationMeta('baselineLearningCooldownUntil');
  @override
  late final GeneratedColumn<DateTime> baselineLearningCooldownUntil =
      GeneratedColumn<DateTime>(
        'baseline_learning_cooldown_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activityImpactLearningCooldownUntilMeta =
      const VerificationMeta('activityImpactLearningCooldownUntil');
  @override
  late final GeneratedColumn<DateTime> activityImpactLearningCooldownUntil =
      GeneratedColumn<DateTime>(
        'activity_impact_learning_cooldown_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    activeRuleVersion,
    pendingRuleVersion,
    pendingRuleEffectiveLifeDay,
    onboardingCompleted,
    baselineLearningMode,
    activityImpactLearningMode,
    baselineLearningSuspended,
    baselineLearningSuspendedAt,
    baselineLearningSuspensionReason,
    activityImpactLearningSuspended,
    activityImpactLearningSuspendedAt,
    activityImpactLearningSuspensionReason,
    baselineLearningCooldownUntil,
    activityImpactLearningCooldownUntil,
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
    if (data.containsKey('baseline_learning_suspended')) {
      context.handle(
        _baselineLearningSuspendedMeta,
        baselineLearningSuspended.isAcceptableOrUnknown(
          data['baseline_learning_suspended']!,
          _baselineLearningSuspendedMeta,
        ),
      );
    }
    if (data.containsKey('baseline_learning_suspended_at')) {
      context.handle(
        _baselineLearningSuspendedAtMeta,
        baselineLearningSuspendedAt.isAcceptableOrUnknown(
          data['baseline_learning_suspended_at']!,
          _baselineLearningSuspendedAtMeta,
        ),
      );
    }
    if (data.containsKey('baseline_learning_suspension_reason')) {
      context.handle(
        _baselineLearningSuspensionReasonMeta,
        baselineLearningSuspensionReason.isAcceptableOrUnknown(
          data['baseline_learning_suspension_reason']!,
          _baselineLearningSuspensionReasonMeta,
        ),
      );
    }
    if (data.containsKey('activity_impact_learning_suspended')) {
      context.handle(
        _activityImpactLearningSuspendedMeta,
        activityImpactLearningSuspended.isAcceptableOrUnknown(
          data['activity_impact_learning_suspended']!,
          _activityImpactLearningSuspendedMeta,
        ),
      );
    }
    if (data.containsKey('activity_impact_learning_suspended_at')) {
      context.handle(
        _activityImpactLearningSuspendedAtMeta,
        activityImpactLearningSuspendedAt.isAcceptableOrUnknown(
          data['activity_impact_learning_suspended_at']!,
          _activityImpactLearningSuspendedAtMeta,
        ),
      );
    }
    if (data.containsKey('activity_impact_learning_suspension_reason')) {
      context.handle(
        _activityImpactLearningSuspensionReasonMeta,
        activityImpactLearningSuspensionReason.isAcceptableOrUnknown(
          data['activity_impact_learning_suspension_reason']!,
          _activityImpactLearningSuspensionReasonMeta,
        ),
      );
    }
    if (data.containsKey('baseline_learning_cooldown_until')) {
      context.handle(
        _baselineLearningCooldownUntilMeta,
        baselineLearningCooldownUntil.isAcceptableOrUnknown(
          data['baseline_learning_cooldown_until']!,
          _baselineLearningCooldownUntilMeta,
        ),
      );
    }
    if (data.containsKey('activity_impact_learning_cooldown_until')) {
      context.handle(
        _activityImpactLearningCooldownUntilMeta,
        activityImpactLearningCooldownUntil.isAcceptableOrUnknown(
          data['activity_impact_learning_cooldown_until']!,
          _activityImpactLearningCooldownUntilMeta,
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
      baselineLearningMode: $AppSettingsTableTable
          .$converterbaselineLearningMode
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}baseline_learning_mode'],
            )!,
          ),
      activityImpactLearningMode: $AppSettingsTableTable
          .$converteractivityImpactLearningMode
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}activity_impact_learning_mode'],
            )!,
          ),
      baselineLearningSuspended: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}baseline_learning_suspended'],
      )!,
      baselineLearningSuspendedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}baseline_learning_suspended_at'],
      ),
      baselineLearningSuspensionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}baseline_learning_suspension_reason'],
      ),
      activityImpactLearningSuspended: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activity_impact_learning_suspended'],
      )!,
      activityImpactLearningSuspendedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activity_impact_learning_suspended_at'],
      ),
      activityImpactLearningSuspensionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_impact_learning_suspension_reason'],
      ),
      baselineLearningCooldownUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}baseline_learning_cooldown_until'],
      ),
      activityImpactLearningCooldownUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activity_impact_learning_cooldown_until'],
      ),
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

  static TypeConverter<LifeDay, String> $converterpendingRuleEffectiveLifeDay =
      const LifeDayConverter();
  static TypeConverter<LifeDay?, String?>
  $converterpendingRuleEffectiveLifeDayn = NullAwareTypeConverter.wrap(
    $converterpendingRuleEffectiveLifeDay,
  );
  static TypeConverter<LearningMode, String> $converterbaselineLearningMode =
      const LearningModeConverter();
  static TypeConverter<LearningMode, String>
  $converteractivityImpactLearningMode = const LearningModeConverter();
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String activeRuleVersion;
  final String? pendingRuleVersion;
  final LifeDay? pendingRuleEffectiveLifeDay;
  final bool onboardingCompleted;
  final LearningMode baselineLearningMode;
  final LearningMode activityImpactLearningMode;
  final bool baselineLearningSuspended;
  final DateTime? baselineLearningSuspendedAt;
  final String? baselineLearningSuspensionReason;
  final bool activityImpactLearningSuspended;
  final DateTime? activityImpactLearningSuspendedAt;
  final String? activityImpactLearningSuspensionReason;
  final DateTime? baselineLearningCooldownUntil;
  final DateTime? activityImpactLearningCooldownUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppSettingsRow({
    required this.id,
    required this.activeRuleVersion,
    this.pendingRuleVersion,
    this.pendingRuleEffectiveLifeDay,
    required this.onboardingCompleted,
    required this.baselineLearningMode,
    required this.activityImpactLearningMode,
    required this.baselineLearningSuspended,
    this.baselineLearningSuspendedAt,
    this.baselineLearningSuspensionReason,
    required this.activityImpactLearningSuspended,
    this.activityImpactLearningSuspendedAt,
    this.activityImpactLearningSuspensionReason,
    this.baselineLearningCooldownUntil,
    this.activityImpactLearningCooldownUntil,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    {
      map['baseline_learning_mode'] = Variable<String>(
        $AppSettingsTableTable.$converterbaselineLearningMode.toSql(
          baselineLearningMode,
        ),
      );
    }
    {
      map['activity_impact_learning_mode'] = Variable<String>(
        $AppSettingsTableTable.$converteractivityImpactLearningMode.toSql(
          activityImpactLearningMode,
        ),
      );
    }
    map['baseline_learning_suspended'] = Variable<bool>(
      baselineLearningSuspended,
    );
    if (!nullToAbsent || baselineLearningSuspendedAt != null) {
      map['baseline_learning_suspended_at'] = Variable<DateTime>(
        baselineLearningSuspendedAt,
      );
    }
    if (!nullToAbsent || baselineLearningSuspensionReason != null) {
      map['baseline_learning_suspension_reason'] = Variable<String>(
        baselineLearningSuspensionReason,
      );
    }
    map['activity_impact_learning_suspended'] = Variable<bool>(
      activityImpactLearningSuspended,
    );
    if (!nullToAbsent || activityImpactLearningSuspendedAt != null) {
      map['activity_impact_learning_suspended_at'] = Variable<DateTime>(
        activityImpactLearningSuspendedAt,
      );
    }
    if (!nullToAbsent || activityImpactLearningSuspensionReason != null) {
      map['activity_impact_learning_suspension_reason'] = Variable<String>(
        activityImpactLearningSuspensionReason,
      );
    }
    if (!nullToAbsent || baselineLearningCooldownUntil != null) {
      map['baseline_learning_cooldown_until'] = Variable<DateTime>(
        baselineLearningCooldownUntil,
      );
    }
    if (!nullToAbsent || activityImpactLearningCooldownUntil != null) {
      map['activity_impact_learning_cooldown_until'] = Variable<DateTime>(
        activityImpactLearningCooldownUntil,
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      activeRuleVersion: Value(activeRuleVersion),
      pendingRuleVersion: pendingRuleVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRuleVersion),
      pendingRuleEffectiveLifeDay:
          pendingRuleEffectiveLifeDay == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRuleEffectiveLifeDay),
      onboardingCompleted: Value(onboardingCompleted),
      baselineLearningMode: Value(baselineLearningMode),
      activityImpactLearningMode: Value(activityImpactLearningMode),
      baselineLearningSuspended: Value(baselineLearningSuspended),
      baselineLearningSuspendedAt:
          baselineLearningSuspendedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineLearningSuspendedAt),
      baselineLearningSuspensionReason:
          baselineLearningSuspensionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineLearningSuspensionReason),
      activityImpactLearningSuspended: Value(activityImpactLearningSuspended),
      activityImpactLearningSuspendedAt:
          activityImpactLearningSuspendedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activityImpactLearningSuspendedAt),
      activityImpactLearningSuspensionReason:
          activityImpactLearningSuspensionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(activityImpactLearningSuspensionReason),
      baselineLearningCooldownUntil:
          baselineLearningCooldownUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineLearningCooldownUntil),
      activityImpactLearningCooldownUntil:
          activityImpactLearningCooldownUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(activityImpactLearningCooldownUntil),
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
      baselineLearningMode: serializer.fromJson<LearningMode>(
        json['baselineLearningMode'],
      ),
      activityImpactLearningMode: serializer.fromJson<LearningMode>(
        json['activityImpactLearningMode'],
      ),
      baselineLearningSuspended: serializer.fromJson<bool>(
        json['baselineLearningSuspended'],
      ),
      baselineLearningSuspendedAt: serializer.fromJson<DateTime?>(
        json['baselineLearningSuspendedAt'],
      ),
      baselineLearningSuspensionReason: serializer.fromJson<String?>(
        json['baselineLearningSuspensionReason'],
      ),
      activityImpactLearningSuspended: serializer.fromJson<bool>(
        json['activityImpactLearningSuspended'],
      ),
      activityImpactLearningSuspendedAt: serializer.fromJson<DateTime?>(
        json['activityImpactLearningSuspendedAt'],
      ),
      activityImpactLearningSuspensionReason: serializer.fromJson<String?>(
        json['activityImpactLearningSuspensionReason'],
      ),
      baselineLearningCooldownUntil: serializer.fromJson<DateTime?>(
        json['baselineLearningCooldownUntil'],
      ),
      activityImpactLearningCooldownUntil: serializer.fromJson<DateTime?>(
        json['activityImpactLearningCooldownUntil'],
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
      'activeRuleVersion': serializer.toJson<String>(activeRuleVersion),
      'pendingRuleVersion': serializer.toJson<String?>(pendingRuleVersion),
      'pendingRuleEffectiveLifeDay': serializer.toJson<LifeDay?>(
        pendingRuleEffectiveLifeDay,
      ),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'baselineLearningMode': serializer.toJson<LearningMode>(
        baselineLearningMode,
      ),
      'activityImpactLearningMode': serializer.toJson<LearningMode>(
        activityImpactLearningMode,
      ),
      'baselineLearningSuspended': serializer.toJson<bool>(
        baselineLearningSuspended,
      ),
      'baselineLearningSuspendedAt': serializer.toJson<DateTime?>(
        baselineLearningSuspendedAt,
      ),
      'baselineLearningSuspensionReason': serializer.toJson<String?>(
        baselineLearningSuspensionReason,
      ),
      'activityImpactLearningSuspended': serializer.toJson<bool>(
        activityImpactLearningSuspended,
      ),
      'activityImpactLearningSuspendedAt': serializer.toJson<DateTime?>(
        activityImpactLearningSuspendedAt,
      ),
      'activityImpactLearningSuspensionReason': serializer.toJson<String?>(
        activityImpactLearningSuspensionReason,
      ),
      'baselineLearningCooldownUntil': serializer.toJson<DateTime?>(
        baselineLearningCooldownUntil,
      ),
      'activityImpactLearningCooldownUntil': serializer.toJson<DateTime?>(
        activityImpactLearningCooldownUntil,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    String? activeRuleVersion,
    Value<String?> pendingRuleVersion = const Value.absent(),
    Value<LifeDay?> pendingRuleEffectiveLifeDay = const Value.absent(),
    bool? onboardingCompleted,
    LearningMode? baselineLearningMode,
    LearningMode? activityImpactLearningMode,
    bool? baselineLearningSuspended,
    Value<DateTime?> baselineLearningSuspendedAt = const Value.absent(),
    Value<String?> baselineLearningSuspensionReason = const Value.absent(),
    bool? activityImpactLearningSuspended,
    Value<DateTime?> activityImpactLearningSuspendedAt = const Value.absent(),
    Value<String?> activityImpactLearningSuspensionReason =
        const Value.absent(),
    Value<DateTime?> baselineLearningCooldownUntil = const Value.absent(),
    Value<DateTime?> activityImpactLearningCooldownUntil = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppSettingsRow(
    id: id ?? this.id,
    activeRuleVersion: activeRuleVersion ?? this.activeRuleVersion,
    pendingRuleVersion: pendingRuleVersion.present
        ? pendingRuleVersion.value
        : this.pendingRuleVersion,
    pendingRuleEffectiveLifeDay: pendingRuleEffectiveLifeDay.present
        ? pendingRuleEffectiveLifeDay.value
        : this.pendingRuleEffectiveLifeDay,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    baselineLearningMode: baselineLearningMode ?? this.baselineLearningMode,
    activityImpactLearningMode:
        activityImpactLearningMode ?? this.activityImpactLearningMode,
    baselineLearningSuspended:
        baselineLearningSuspended ?? this.baselineLearningSuspended,
    baselineLearningSuspendedAt: baselineLearningSuspendedAt.present
        ? baselineLearningSuspendedAt.value
        : this.baselineLearningSuspendedAt,
    baselineLearningSuspensionReason: baselineLearningSuspensionReason.present
        ? baselineLearningSuspensionReason.value
        : this.baselineLearningSuspensionReason,
    activityImpactLearningSuspended:
        activityImpactLearningSuspended ?? this.activityImpactLearningSuspended,
    activityImpactLearningSuspendedAt: activityImpactLearningSuspendedAt.present
        ? activityImpactLearningSuspendedAt.value
        : this.activityImpactLearningSuspendedAt,
    activityImpactLearningSuspensionReason:
        activityImpactLearningSuspensionReason.present
        ? activityImpactLearningSuspensionReason.value
        : this.activityImpactLearningSuspensionReason,
    baselineLearningCooldownUntil: baselineLearningCooldownUntil.present
        ? baselineLearningCooldownUntil.value
        : this.baselineLearningCooldownUntil,
    activityImpactLearningCooldownUntil:
        activityImpactLearningCooldownUntil.present
        ? activityImpactLearningCooldownUntil.value
        : this.activityImpactLearningCooldownUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
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
      baselineLearningMode: data.baselineLearningMode.present
          ? data.baselineLearningMode.value
          : this.baselineLearningMode,
      activityImpactLearningMode: data.activityImpactLearningMode.present
          ? data.activityImpactLearningMode.value
          : this.activityImpactLearningMode,
      baselineLearningSuspended: data.baselineLearningSuspended.present
          ? data.baselineLearningSuspended.value
          : this.baselineLearningSuspended,
      baselineLearningSuspendedAt: data.baselineLearningSuspendedAt.present
          ? data.baselineLearningSuspendedAt.value
          : this.baselineLearningSuspendedAt,
      baselineLearningSuspensionReason:
          data.baselineLearningSuspensionReason.present
          ? data.baselineLearningSuspensionReason.value
          : this.baselineLearningSuspensionReason,
      activityImpactLearningSuspended:
          data.activityImpactLearningSuspended.present
          ? data.activityImpactLearningSuspended.value
          : this.activityImpactLearningSuspended,
      activityImpactLearningSuspendedAt:
          data.activityImpactLearningSuspendedAt.present
          ? data.activityImpactLearningSuspendedAt.value
          : this.activityImpactLearningSuspendedAt,
      activityImpactLearningSuspensionReason:
          data.activityImpactLearningSuspensionReason.present
          ? data.activityImpactLearningSuspensionReason.value
          : this.activityImpactLearningSuspensionReason,
      baselineLearningCooldownUntil: data.baselineLearningCooldownUntil.present
          ? data.baselineLearningCooldownUntil.value
          : this.baselineLearningCooldownUntil,
      activityImpactLearningCooldownUntil:
          data.activityImpactLearningCooldownUntil.present
          ? data.activityImpactLearningCooldownUntil.value
          : this.activityImpactLearningCooldownUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('activeRuleVersion: $activeRuleVersion, ')
          ..write('pendingRuleVersion: $pendingRuleVersion, ')
          ..write('pendingRuleEffectiveLifeDay: $pendingRuleEffectiveLifeDay, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('baselineLearningMode: $baselineLearningMode, ')
          ..write('activityImpactLearningMode: $activityImpactLearningMode, ')
          ..write('baselineLearningSuspended: $baselineLearningSuspended, ')
          ..write('baselineLearningSuspendedAt: $baselineLearningSuspendedAt, ')
          ..write(
            'baselineLearningSuspensionReason: $baselineLearningSuspensionReason, ',
          )
          ..write(
            'activityImpactLearningSuspended: $activityImpactLearningSuspended, ',
          )
          ..write(
            'activityImpactLearningSuspendedAt: $activityImpactLearningSuspendedAt, ',
          )
          ..write(
            'activityImpactLearningSuspensionReason: $activityImpactLearningSuspensionReason, ',
          )
          ..write(
            'baselineLearningCooldownUntil: $baselineLearningCooldownUntil, ',
          )
          ..write(
            'activityImpactLearningCooldownUntil: $activityImpactLearningCooldownUntil, ',
          )
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activeRuleVersion,
    pendingRuleVersion,
    pendingRuleEffectiveLifeDay,
    onboardingCompleted,
    baselineLearningMode,
    activityImpactLearningMode,
    baselineLearningSuspended,
    baselineLearningSuspendedAt,
    baselineLearningSuspensionReason,
    activityImpactLearningSuspended,
    activityImpactLearningSuspendedAt,
    activityImpactLearningSuspensionReason,
    baselineLearningCooldownUntil,
    activityImpactLearningCooldownUntil,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.activeRuleVersion == this.activeRuleVersion &&
          other.pendingRuleVersion == this.pendingRuleVersion &&
          other.pendingRuleEffectiveLifeDay ==
              this.pendingRuleEffectiveLifeDay &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.baselineLearningMode == this.baselineLearningMode &&
          other.activityImpactLearningMode == this.activityImpactLearningMode &&
          other.baselineLearningSuspended == this.baselineLearningSuspended &&
          other.baselineLearningSuspendedAt ==
              this.baselineLearningSuspendedAt &&
          other.baselineLearningSuspensionReason ==
              this.baselineLearningSuspensionReason &&
          other.activityImpactLearningSuspended ==
              this.activityImpactLearningSuspended &&
          other.activityImpactLearningSuspendedAt ==
              this.activityImpactLearningSuspendedAt &&
          other.activityImpactLearningSuspensionReason ==
              this.activityImpactLearningSuspensionReason &&
          other.baselineLearningCooldownUntil ==
              this.baselineLearningCooldownUntil &&
          other.activityImpactLearningCooldownUntil ==
              this.activityImpactLearningCooldownUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String> activeRuleVersion;
  final Value<String?> pendingRuleVersion;
  final Value<LifeDay?> pendingRuleEffectiveLifeDay;
  final Value<bool> onboardingCompleted;
  final Value<LearningMode> baselineLearningMode;
  final Value<LearningMode> activityImpactLearningMode;
  final Value<bool> baselineLearningSuspended;
  final Value<DateTime?> baselineLearningSuspendedAt;
  final Value<String?> baselineLearningSuspensionReason;
  final Value<bool> activityImpactLearningSuspended;
  final Value<DateTime?> activityImpactLearningSuspendedAt;
  final Value<String?> activityImpactLearningSuspensionReason;
  final Value<DateTime?> baselineLearningCooldownUntil;
  final Value<DateTime?> activityImpactLearningCooldownUntil;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.activeRuleVersion = const Value.absent(),
    this.pendingRuleVersion = const Value.absent(),
    this.pendingRuleEffectiveLifeDay = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.baselineLearningMode = const Value.absent(),
    this.activityImpactLearningMode = const Value.absent(),
    this.baselineLearningSuspended = const Value.absent(),
    this.baselineLearningSuspendedAt = const Value.absent(),
    this.baselineLearningSuspensionReason = const Value.absent(),
    this.activityImpactLearningSuspended = const Value.absent(),
    this.activityImpactLearningSuspendedAt = const Value.absent(),
    this.activityImpactLearningSuspensionReason = const Value.absent(),
    this.baselineLearningCooldownUntil = const Value.absent(),
    this.activityImpactLearningCooldownUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String activeRuleVersion,
    this.pendingRuleVersion = const Value.absent(),
    this.pendingRuleEffectiveLifeDay = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.baselineLearningMode = const Value.absent(),
    this.activityImpactLearningMode = const Value.absent(),
    this.baselineLearningSuspended = const Value.absent(),
    this.baselineLearningSuspendedAt = const Value.absent(),
    this.baselineLearningSuspensionReason = const Value.absent(),
    this.activityImpactLearningSuspended = const Value.absent(),
    this.activityImpactLearningSuspendedAt = const Value.absent(),
    this.activityImpactLearningSuspensionReason = const Value.absent(),
    this.baselineLearningCooldownUntil = const Value.absent(),
    this.activityImpactLearningCooldownUntil = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : activeRuleVersion = Value(activeRuleVersion),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? activeRuleVersion,
    Expression<String>? pendingRuleVersion,
    Expression<String>? pendingRuleEffectiveLifeDay,
    Expression<bool>? onboardingCompleted,
    Expression<String>? baselineLearningMode,
    Expression<String>? activityImpactLearningMode,
    Expression<bool>? baselineLearningSuspended,
    Expression<DateTime>? baselineLearningSuspendedAt,
    Expression<String>? baselineLearningSuspensionReason,
    Expression<bool>? activityImpactLearningSuspended,
    Expression<DateTime>? activityImpactLearningSuspendedAt,
    Expression<String>? activityImpactLearningSuspensionReason,
    Expression<DateTime>? baselineLearningCooldownUntil,
    Expression<DateTime>? activityImpactLearningCooldownUntil,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activeRuleVersion != null) 'active_rule_version': activeRuleVersion,
      if (pendingRuleVersion != null)
        'pending_rule_version': pendingRuleVersion,
      if (pendingRuleEffectiveLifeDay != null)
        'pending_rule_effective_life_day': pendingRuleEffectiveLifeDay,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (baselineLearningMode != null)
        'baseline_learning_mode': baselineLearningMode,
      if (activityImpactLearningMode != null)
        'activity_impact_learning_mode': activityImpactLearningMode,
      if (baselineLearningSuspended != null)
        'baseline_learning_suspended': baselineLearningSuspended,
      if (baselineLearningSuspendedAt != null)
        'baseline_learning_suspended_at': baselineLearningSuspendedAt,
      if (baselineLearningSuspensionReason != null)
        'baseline_learning_suspension_reason': baselineLearningSuspensionReason,
      if (activityImpactLearningSuspended != null)
        'activity_impact_learning_suspended': activityImpactLearningSuspended,
      if (activityImpactLearningSuspendedAt != null)
        'activity_impact_learning_suspended_at':
            activityImpactLearningSuspendedAt,
      if (activityImpactLearningSuspensionReason != null)
        'activity_impact_learning_suspension_reason':
            activityImpactLearningSuspensionReason,
      if (baselineLearningCooldownUntil != null)
        'baseline_learning_cooldown_until': baselineLearningCooldownUntil,
      if (activityImpactLearningCooldownUntil != null)
        'activity_impact_learning_cooldown_until':
            activityImpactLearningCooldownUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? activeRuleVersion,
    Value<String?>? pendingRuleVersion,
    Value<LifeDay?>? pendingRuleEffectiveLifeDay,
    Value<bool>? onboardingCompleted,
    Value<LearningMode>? baselineLearningMode,
    Value<LearningMode>? activityImpactLearningMode,
    Value<bool>? baselineLearningSuspended,
    Value<DateTime?>? baselineLearningSuspendedAt,
    Value<String?>? baselineLearningSuspensionReason,
    Value<bool>? activityImpactLearningSuspended,
    Value<DateTime?>? activityImpactLearningSuspendedAt,
    Value<String?>? activityImpactLearningSuspensionReason,
    Value<DateTime?>? baselineLearningCooldownUntil,
    Value<DateTime?>? activityImpactLearningCooldownUntil,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      activeRuleVersion: activeRuleVersion ?? this.activeRuleVersion,
      pendingRuleVersion: pendingRuleVersion ?? this.pendingRuleVersion,
      pendingRuleEffectiveLifeDay:
          pendingRuleEffectiveLifeDay ?? this.pendingRuleEffectiveLifeDay,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      baselineLearningMode: baselineLearningMode ?? this.baselineLearningMode,
      activityImpactLearningMode:
          activityImpactLearningMode ?? this.activityImpactLearningMode,
      baselineLearningSuspended:
          baselineLearningSuspended ?? this.baselineLearningSuspended,
      baselineLearningSuspendedAt:
          baselineLearningSuspendedAt ?? this.baselineLearningSuspendedAt,
      baselineLearningSuspensionReason:
          baselineLearningSuspensionReason ??
          this.baselineLearningSuspensionReason,
      activityImpactLearningSuspended:
          activityImpactLearningSuspended ??
          this.activityImpactLearningSuspended,
      activityImpactLearningSuspendedAt:
          activityImpactLearningSuspendedAt ??
          this.activityImpactLearningSuspendedAt,
      activityImpactLearningSuspensionReason:
          activityImpactLearningSuspensionReason ??
          this.activityImpactLearningSuspensionReason,
      baselineLearningCooldownUntil:
          baselineLearningCooldownUntil ?? this.baselineLearningCooldownUntil,
      activityImpactLearningCooldownUntil:
          activityImpactLearningCooldownUntil ??
          this.activityImpactLearningCooldownUntil,
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
    if (baselineLearningMode.present) {
      map['baseline_learning_mode'] = Variable<String>(
        $AppSettingsTableTable.$converterbaselineLearningMode.toSql(
          baselineLearningMode.value,
        ),
      );
    }
    if (activityImpactLearningMode.present) {
      map['activity_impact_learning_mode'] = Variable<String>(
        $AppSettingsTableTable.$converteractivityImpactLearningMode.toSql(
          activityImpactLearningMode.value,
        ),
      );
    }
    if (baselineLearningSuspended.present) {
      map['baseline_learning_suspended'] = Variable<bool>(
        baselineLearningSuspended.value,
      );
    }
    if (baselineLearningSuspendedAt.present) {
      map['baseline_learning_suspended_at'] = Variable<DateTime>(
        baselineLearningSuspendedAt.value,
      );
    }
    if (baselineLearningSuspensionReason.present) {
      map['baseline_learning_suspension_reason'] = Variable<String>(
        baselineLearningSuspensionReason.value,
      );
    }
    if (activityImpactLearningSuspended.present) {
      map['activity_impact_learning_suspended'] = Variable<bool>(
        activityImpactLearningSuspended.value,
      );
    }
    if (activityImpactLearningSuspendedAt.present) {
      map['activity_impact_learning_suspended_at'] = Variable<DateTime>(
        activityImpactLearningSuspendedAt.value,
      );
    }
    if (activityImpactLearningSuspensionReason.present) {
      map['activity_impact_learning_suspension_reason'] = Variable<String>(
        activityImpactLearningSuspensionReason.value,
      );
    }
    if (baselineLearningCooldownUntil.present) {
      map['baseline_learning_cooldown_until'] = Variable<DateTime>(
        baselineLearningCooldownUntil.value,
      );
    }
    if (activityImpactLearningCooldownUntil.present) {
      map['activity_impact_learning_cooldown_until'] = Variable<DateTime>(
        activityImpactLearningCooldownUntil.value,
      );
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
          ..write('activeRuleVersion: $activeRuleVersion, ')
          ..write('pendingRuleVersion: $pendingRuleVersion, ')
          ..write('pendingRuleEffectiveLifeDay: $pendingRuleEffectiveLifeDay, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('baselineLearningMode: $baselineLearningMode, ')
          ..write('activityImpactLearningMode: $activityImpactLearningMode, ')
          ..write('baselineLearningSuspended: $baselineLearningSuspended, ')
          ..write('baselineLearningSuspendedAt: $baselineLearningSuspendedAt, ')
          ..write(
            'baselineLearningSuspensionReason: $baselineLearningSuspensionReason, ',
          )
          ..write(
            'activityImpactLearningSuspended: $activityImpactLearningSuspended, ',
          )
          ..write(
            'activityImpactLearningSuspendedAt: $activityImpactLearningSuspendedAt, ',
          )
          ..write(
            'activityImpactLearningSuspensionReason: $activityImpactLearningSuspensionReason, ',
          )
          ..write(
            'baselineLearningCooldownUntil: $baselineLearningCooldownUntil, ',
          )
          ..write(
            'activityImpactLearningCooldownUntil: $activityImpactLearningCooldownUntil, ',
          )
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
  static const VerificationMeta _defaultTheoreticalDeltaMeta =
      const VerificationMeta('defaultTheoreticalDelta');
  @override
  late final GeneratedColumn<int> defaultTheoreticalDelta =
      GeneratedColumn<int>(
        'default_theoretical_delta',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _factorMeta = const VerificationMeta('factor');
  @override
  late final GeneratedColumn<double> factor = GeneratedColumn<double>(
    'activity_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _personalizedTheoreticalDeltaMeta =
      const VerificationMeta('personalizedTheoreticalDelta');
  @override
  late final GeneratedColumn<int> personalizedTheoreticalDelta =
      GeneratedColumn<int>(
        'personalized_theoretical_delta',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _personalizationVersionIdMeta =
      const VerificationMeta('personalizationVersionId');
  @override
  late final GeneratedColumn<String> personalizationVersionId =
      GeneratedColumn<String>(
        'personalization_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay?, String>
  factorRegimeStartedLifeDay =
      GeneratedColumn<String>(
        'factor_regime_started_life_day',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LifeDay?>(
        $ActivityRecordsTableTable.$converterfactorRegimeStartedLifeDayn,
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
    defaultTheoreticalDelta,
    factor,
    personalizedTheoreticalDelta,
    personalizationVersionId,
    factorRegimeStartedLifeDay,
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
    if (data.containsKey('default_theoretical_delta')) {
      context.handle(
        _defaultTheoreticalDeltaMeta,
        defaultTheoreticalDelta.isAcceptableOrUnknown(
          data['default_theoretical_delta']!,
          _defaultTheoreticalDeltaMeta,
        ),
      );
    }
    if (data.containsKey('activity_factor')) {
      context.handle(
        _factorMeta,
        factor.isAcceptableOrUnknown(data['activity_factor']!, _factorMeta),
      );
    }
    if (data.containsKey('personalized_theoretical_delta')) {
      context.handle(
        _personalizedTheoreticalDeltaMeta,
        personalizedTheoreticalDelta.isAcceptableOrUnknown(
          data['personalized_theoretical_delta']!,
          _personalizedTheoreticalDeltaMeta,
        ),
      );
    }
    if (data.containsKey('personalization_version_id')) {
      context.handle(
        _personalizationVersionIdMeta,
        personalizationVersionId.isAcceptableOrUnknown(
          data['personalization_version_id']!,
          _personalizationVersionIdMeta,
        ),
      );
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
      defaultTheoreticalDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_theoretical_delta'],
      )!,
      factor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}activity_factor'],
      )!,
      personalizedTheoreticalDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personalized_theoretical_delta'],
      )!,
      personalizationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personalization_version_id'],
      ),
      factorRegimeStartedLifeDay: $ActivityRecordsTableTable
          .$converterfactorRegimeStartedLifeDayn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}factor_regime_started_life_day'],
            ),
          ),
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
  static TypeConverter<LifeDay, String> $converterfactorRegimeStartedLifeDay =
      const LifeDayConverter();
  static TypeConverter<LifeDay?, String?>
  $converterfactorRegimeStartedLifeDayn = NullAwareTypeConverter.wrap(
    $converterfactorRegimeStartedLifeDay,
  );
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
  final int defaultTheoreticalDelta;
  final double factor;
  final int personalizedTheoreticalDelta;
  final String? personalizationVersionId;
  final LifeDay? factorRegimeStartedLifeDay;
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
    required this.defaultTheoreticalDelta,
    required this.factor,
    required this.personalizedTheoreticalDelta,
    this.personalizationVersionId,
    this.factorRegimeStartedLifeDay,
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
    map['default_theoretical_delta'] = Variable<int>(defaultTheoreticalDelta);
    map['activity_factor'] = Variable<double>(factor);
    map['personalized_theoretical_delta'] = Variable<int>(
      personalizedTheoreticalDelta,
    );
    if (!nullToAbsent || personalizationVersionId != null) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId,
      );
    }
    if (!nullToAbsent || factorRegimeStartedLifeDay != null) {
      map['factor_regime_started_life_day'] = Variable<String>(
        $ActivityRecordsTableTable.$converterfactorRegimeStartedLifeDayn.toSql(
          factorRegimeStartedLifeDay,
        ),
      );
    }
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
      defaultTheoreticalDelta: Value(defaultTheoreticalDelta),
      factor: Value(factor),
      personalizedTheoreticalDelta: Value(personalizedTheoreticalDelta),
      personalizationVersionId: personalizationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(personalizationVersionId),
      factorRegimeStartedLifeDay:
          factorRegimeStartedLifeDay == null && nullToAbsent
          ? const Value.absent()
          : Value(factorRegimeStartedLifeDay),
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
      defaultTheoreticalDelta: serializer.fromJson<int>(
        json['defaultTheoreticalDelta'],
      ),
      factor: serializer.fromJson<double>(json['factor']),
      personalizedTheoreticalDelta: serializer.fromJson<int>(
        json['personalizedTheoreticalDelta'],
      ),
      personalizationVersionId: serializer.fromJson<String?>(
        json['personalizationVersionId'],
      ),
      factorRegimeStartedLifeDay: serializer.fromJson<LifeDay?>(
        json['factorRegimeStartedLifeDay'],
      ),
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
      'defaultTheoreticalDelta': serializer.toJson<int>(
        defaultTheoreticalDelta,
      ),
      'factor': serializer.toJson<double>(factor),
      'personalizedTheoreticalDelta': serializer.toJson<int>(
        personalizedTheoreticalDelta,
      ),
      'personalizationVersionId': serializer.toJson<String?>(
        personalizationVersionId,
      ),
      'factorRegimeStartedLifeDay': serializer.toJson<LifeDay?>(
        factorRegimeStartedLifeDay,
      ),
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
    int? defaultTheoreticalDelta,
    double? factor,
    int? personalizedTheoreticalDelta,
    Value<String?> personalizationVersionId = const Value.absent(),
    Value<LifeDay?> factorRegimeStartedLifeDay = const Value.absent(),
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
    defaultTheoreticalDelta:
        defaultTheoreticalDelta ?? this.defaultTheoreticalDelta,
    factor: factor ?? this.factor,
    personalizedTheoreticalDelta:
        personalizedTheoreticalDelta ?? this.personalizedTheoreticalDelta,
    personalizationVersionId: personalizationVersionId.present
        ? personalizationVersionId.value
        : this.personalizationVersionId,
    factorRegimeStartedLifeDay: factorRegimeStartedLifeDay.present
        ? factorRegimeStartedLifeDay.value
        : this.factorRegimeStartedLifeDay,
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
      defaultTheoreticalDelta: data.defaultTheoreticalDelta.present
          ? data.defaultTheoreticalDelta.value
          : this.defaultTheoreticalDelta,
      factor: data.factor.present ? data.factor.value : this.factor,
      personalizedTheoreticalDelta: data.personalizedTheoreticalDelta.present
          ? data.personalizedTheoreticalDelta.value
          : this.personalizedTheoreticalDelta,
      personalizationVersionId: data.personalizationVersionId.present
          ? data.personalizationVersionId.value
          : this.personalizationVersionId,
      factorRegimeStartedLifeDay: data.factorRegimeStartedLifeDay.present
          ? data.factorRegimeStartedLifeDay.value
          : this.factorRegimeStartedLifeDay,
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
          ..write('defaultTheoreticalDelta: $defaultTheoreticalDelta, ')
          ..write('factor: $factor, ')
          ..write(
            'personalizedTheoreticalDelta: $personalizedTheoreticalDelta, ',
          )
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('factorRegimeStartedLifeDay: $factorRegimeStartedLifeDay, ')
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
    defaultTheoreticalDelta,
    factor,
    personalizedTheoreticalDelta,
    personalizationVersionId,
    factorRegimeStartedLifeDay,
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
          other.defaultTheoreticalDelta == this.defaultTheoreticalDelta &&
          other.factor == this.factor &&
          other.personalizedTheoreticalDelta ==
              this.personalizedTheoreticalDelta &&
          other.personalizationVersionId == this.personalizationVersionId &&
          other.factorRegimeStartedLifeDay == this.factorRegimeStartedLifeDay &&
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
  final Value<int> defaultTheoreticalDelta;
  final Value<double> factor;
  final Value<int> personalizedTheoreticalDelta;
  final Value<String?> personalizationVersionId;
  final Value<LifeDay?> factorRegimeStartedLifeDay;
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
    this.defaultTheoreticalDelta = const Value.absent(),
    this.factor = const Value.absent(),
    this.personalizedTheoreticalDelta = const Value.absent(),
    this.personalizationVersionId = const Value.absent(),
    this.factorRegimeStartedLifeDay = const Value.absent(),
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
    this.defaultTheoreticalDelta = const Value.absent(),
    this.factor = const Value.absent(),
    this.personalizedTheoreticalDelta = const Value.absent(),
    this.personalizationVersionId = const Value.absent(),
    this.factorRegimeStartedLifeDay = const Value.absent(),
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
    Expression<int>? defaultTheoreticalDelta,
    Expression<double>? factor,
    Expression<int>? personalizedTheoreticalDelta,
    Expression<String>? personalizationVersionId,
    Expression<String>? factorRegimeStartedLifeDay,
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
      if (defaultTheoreticalDelta != null)
        'default_theoretical_delta': defaultTheoreticalDelta,
      if (factor != null) 'activity_factor': factor,
      if (personalizedTheoreticalDelta != null)
        'personalized_theoretical_delta': personalizedTheoreticalDelta,
      if (personalizationVersionId != null)
        'personalization_version_id': personalizationVersionId,
      if (factorRegimeStartedLifeDay != null)
        'factor_regime_started_life_day': factorRegimeStartedLifeDay,
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
    Value<int>? defaultTheoreticalDelta,
    Value<double>? factor,
    Value<int>? personalizedTheoreticalDelta,
    Value<String?>? personalizationVersionId,
    Value<LifeDay?>? factorRegimeStartedLifeDay,
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
      defaultTheoreticalDelta:
          defaultTheoreticalDelta ?? this.defaultTheoreticalDelta,
      factor: factor ?? this.factor,
      personalizedTheoreticalDelta:
          personalizedTheoreticalDelta ?? this.personalizedTheoreticalDelta,
      personalizationVersionId:
          personalizationVersionId ?? this.personalizationVersionId,
      factorRegimeStartedLifeDay:
          factorRegimeStartedLifeDay ?? this.factorRegimeStartedLifeDay,
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
    if (defaultTheoreticalDelta.present) {
      map['default_theoretical_delta'] = Variable<int>(
        defaultTheoreticalDelta.value,
      );
    }
    if (factor.present) {
      map['activity_factor'] = Variable<double>(factor.value);
    }
    if (personalizedTheoreticalDelta.present) {
      map['personalized_theoretical_delta'] = Variable<int>(
        personalizedTheoreticalDelta.value,
      );
    }
    if (personalizationVersionId.present) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId.value,
      );
    }
    if (factorRegimeStartedLifeDay.present) {
      map['factor_regime_started_life_day'] = Variable<String>(
        $ActivityRecordsTableTable.$converterfactorRegimeStartedLifeDayn.toSql(
          factorRegimeStartedLifeDay.value,
        ),
      );
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
          ..write('defaultTheoreticalDelta: $defaultTheoreticalDelta, ')
          ..write('factor: $factor, ')
          ..write(
            'personalizedTheoreticalDelta: $personalizedTheoreticalDelta, ',
          )
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('factorRegimeStartedLifeDay: $factorRegimeStartedLifeDay, ')
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
  static const VerificationMeta _contractVersionMeta = const VerificationMeta(
    'contractVersion',
  );
  @override
  late final GeneratedColumn<String> contractVersion = GeneratedColumn<String>(
    'contract_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ObservationReferenceType?, String>
  referenceType =
      GeneratedColumn<String>(
        'reference_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ObservationReferenceType?>(
        $EnergyObservationsTableTable.$converterreferenceTypen,
      );
  static const VerificationMeta _initialEstimateAtObservationMeta =
      const VerificationMeta('initialEstimateAtObservation');
  @override
  late final GeneratedColumn<int> initialEstimateAtObservation =
      GeneratedColumn<int>(
        'initial_estimate_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estimatedOrdinalAtObservationMeta =
      const VerificationMeta('estimatedOrdinalAtObservation');
  @override
  late final GeneratedColumn<int> estimatedOrdinalAtObservation =
      GeneratedColumn<int>(
        'estimated_ordinal_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _baseEnergyAtObservationMeta =
      const VerificationMeta('baseEnergyAtObservation');
  @override
  late final GeneratedColumn<int> baseEnergyAtObservation =
      GeneratedColumn<int>(
        'base_energy_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ruleVersionAtObservationMeta =
      const VerificationMeta('ruleVersionAtObservation');
  @override
  late final GeneratedColumn<String> ruleVersionAtObservation =
      GeneratedColumn<String>(
        'rule_version_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _comparisonBandVersionMeta =
      const VerificationMeta('comparisonBandVersion');
  @override
  late final GeneratedColumn<String> comparisonBandVersion =
      GeneratedColumn<String>(
        'comparison_band_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _personalizationVersionAtObservationMeta =
      const VerificationMeta('personalizationVersionAtObservation');
  @override
  late final GeneratedColumn<String> personalizationVersionAtObservation =
      GeneratedColumn<String>(
        'personalization_version_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _effectiveModelFingerprintAtObservationMeta =
      const VerificationMeta('effectiveModelFingerprintAtObservation');
  @override
  late final GeneratedColumn<String> effectiveModelFingerprintAtObservation =
      GeneratedColumn<String>(
        'effective_model_fingerprint_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _modelRegimeEpochAtObservationMeta =
      const VerificationMeta('modelRegimeEpochAtObservation');
  @override
  late final GeneratedColumn<String> modelRegimeEpochAtObservation =
      GeneratedColumn<String>(
        'model_regime_epoch_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activeActivityCountAtObservationMeta =
      const VerificationMeta('activeActivityCountAtObservation');
  @override
  late final GeneratedColumn<int> activeActivityCountAtObservation =
      GeneratedColumn<int>(
        'active_activity_count_at_observation',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ObservationCoverageState?, String>
  coverageState =
      GeneratedColumn<String>(
        'coverage_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ObservationCoverageState?>(
        $EnergyObservationsTableTable.$convertercoverageStaten,
      );
  static const VerificationMeta _modelRegimeKeyMeta = const VerificationMeta(
    'modelRegimeKey',
  );
  @override
  late final GeneratedColumn<String> modelRegimeKey = GeneratedColumn<String>(
    'model_regime_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    contractVersion,
    referenceType,
    initialEstimateAtObservation,
    estimatedOrdinalAtObservation,
    baseEnergyAtObservation,
    ruleVersionAtObservation,
    comparisonBandVersion,
    personalizationVersionAtObservation,
    effectiveModelFingerprintAtObservation,
    modelRegimeEpochAtObservation,
    activeActivityCountAtObservation,
    coverageState,
    modelRegimeKey,
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
    if (data.containsKey('contract_version')) {
      context.handle(
        _contractVersionMeta,
        contractVersion.isAcceptableOrUnknown(
          data['contract_version']!,
          _contractVersionMeta,
        ),
      );
    }
    if (data.containsKey('initial_estimate_at_observation')) {
      context.handle(
        _initialEstimateAtObservationMeta,
        initialEstimateAtObservation.isAcceptableOrUnknown(
          data['initial_estimate_at_observation']!,
          _initialEstimateAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('estimated_ordinal_at_observation')) {
      context.handle(
        _estimatedOrdinalAtObservationMeta,
        estimatedOrdinalAtObservation.isAcceptableOrUnknown(
          data['estimated_ordinal_at_observation']!,
          _estimatedOrdinalAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('base_energy_at_observation')) {
      context.handle(
        _baseEnergyAtObservationMeta,
        baseEnergyAtObservation.isAcceptableOrUnknown(
          data['base_energy_at_observation']!,
          _baseEnergyAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('rule_version_at_observation')) {
      context.handle(
        _ruleVersionAtObservationMeta,
        ruleVersionAtObservation.isAcceptableOrUnknown(
          data['rule_version_at_observation']!,
          _ruleVersionAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('comparison_band_version')) {
      context.handle(
        _comparisonBandVersionMeta,
        comparisonBandVersion.isAcceptableOrUnknown(
          data['comparison_band_version']!,
          _comparisonBandVersionMeta,
        ),
      );
    }
    if (data.containsKey('personalization_version_at_observation')) {
      context.handle(
        _personalizationVersionAtObservationMeta,
        personalizationVersionAtObservation.isAcceptableOrUnknown(
          data['personalization_version_at_observation']!,
          _personalizationVersionAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('effective_model_fingerprint_at_observation')) {
      context.handle(
        _effectiveModelFingerprintAtObservationMeta,
        effectiveModelFingerprintAtObservation.isAcceptableOrUnknown(
          data['effective_model_fingerprint_at_observation']!,
          _effectiveModelFingerprintAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('model_regime_epoch_at_observation')) {
      context.handle(
        _modelRegimeEpochAtObservationMeta,
        modelRegimeEpochAtObservation.isAcceptableOrUnknown(
          data['model_regime_epoch_at_observation']!,
          _modelRegimeEpochAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('active_activity_count_at_observation')) {
      context.handle(
        _activeActivityCountAtObservationMeta,
        activeActivityCountAtObservation.isAcceptableOrUnknown(
          data['active_activity_count_at_observation']!,
          _activeActivityCountAtObservationMeta,
        ),
      );
    }
    if (data.containsKey('model_regime_key')) {
      context.handle(
        _modelRegimeKeyMeta,
        modelRegimeKey.isAcceptableOrUnknown(
          data['model_regime_key']!,
          _modelRegimeKeyMeta,
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
      contractVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contract_version'],
      ),
      referenceType: $EnergyObservationsTableTable.$converterreferenceTypen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reference_type'],
            ),
          ),
      initialEstimateAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_estimate_at_observation'],
      ),
      estimatedOrdinalAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_ordinal_at_observation'],
      ),
      baseEnergyAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_energy_at_observation'],
      ),
      ruleVersionAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version_at_observation'],
      ),
      comparisonBandVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comparison_band_version'],
      ),
      personalizationVersionAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personalization_version_at_observation'],
      ),
      effectiveModelFingerprintAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_model_fingerprint_at_observation'],
      ),
      modelRegimeEpochAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_regime_epoch_at_observation'],
      ),
      activeActivityCountAtObservation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_activity_count_at_observation'],
      ),
      coverageState: $EnergyObservationsTableTable.$convertercoverageStaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}coverage_state'],
            ),
          ),
      modelRegimeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_regime_key'],
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
  static TypeConverter<ObservationReferenceType, String>
  $converterreferenceType = const ObservationReferenceTypeConverter();
  static TypeConverter<ObservationReferenceType?, String?>
  $converterreferenceTypen = NullAwareTypeConverter.wrap(
    $converterreferenceType,
  );
  static TypeConverter<ObservationCoverageState, String>
  $convertercoverageState = const ObservationCoverageStateConverter();
  static TypeConverter<ObservationCoverageState?, String?>
  $convertercoverageStaten = NullAwareTypeConverter.wrap(
    $convertercoverageState,
  );
}

class EnergyObservationRow extends DataClass
    implements Insertable<EnergyObservationRow> {
  final String id;
  final LifeDay lifeDay;
  final EnergyObservationType type;
  final AbsoluteEnergyState? absoluteState;
  final RelativeCorrection? relativeState;
  final int? estimateAtObservation;
  final String? contractVersion;
  final ObservationReferenceType? referenceType;
  final int? initialEstimateAtObservation;
  final int? estimatedOrdinalAtObservation;
  final int? baseEnergyAtObservation;
  final String? ruleVersionAtObservation;
  final String? comparisonBandVersion;
  final String? personalizationVersionAtObservation;
  final String? effectiveModelFingerprintAtObservation;
  final String? modelRegimeEpochAtObservation;
  final int? activeActivityCountAtObservation;
  final ObservationCoverageState? coverageState;
  final String? modelRegimeKey;
  final DateTime observedAt;
  const EnergyObservationRow({
    required this.id,
    required this.lifeDay,
    required this.type,
    this.absoluteState,
    this.relativeState,
    this.estimateAtObservation,
    this.contractVersion,
    this.referenceType,
    this.initialEstimateAtObservation,
    this.estimatedOrdinalAtObservation,
    this.baseEnergyAtObservation,
    this.ruleVersionAtObservation,
    this.comparisonBandVersion,
    this.personalizationVersionAtObservation,
    this.effectiveModelFingerprintAtObservation,
    this.modelRegimeEpochAtObservation,
    this.activeActivityCountAtObservation,
    this.coverageState,
    this.modelRegimeKey,
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
    if (!nullToAbsent || contractVersion != null) {
      map['contract_version'] = Variable<String>(contractVersion);
    }
    if (!nullToAbsent || referenceType != null) {
      map['reference_type'] = Variable<String>(
        $EnergyObservationsTableTable.$converterreferenceTypen.toSql(
          referenceType,
        ),
      );
    }
    if (!nullToAbsent || initialEstimateAtObservation != null) {
      map['initial_estimate_at_observation'] = Variable<int>(
        initialEstimateAtObservation,
      );
    }
    if (!nullToAbsent || estimatedOrdinalAtObservation != null) {
      map['estimated_ordinal_at_observation'] = Variable<int>(
        estimatedOrdinalAtObservation,
      );
    }
    if (!nullToAbsent || baseEnergyAtObservation != null) {
      map['base_energy_at_observation'] = Variable<int>(
        baseEnergyAtObservation,
      );
    }
    if (!nullToAbsent || ruleVersionAtObservation != null) {
      map['rule_version_at_observation'] = Variable<String>(
        ruleVersionAtObservation,
      );
    }
    if (!nullToAbsent || comparisonBandVersion != null) {
      map['comparison_band_version'] = Variable<String>(comparisonBandVersion);
    }
    if (!nullToAbsent || personalizationVersionAtObservation != null) {
      map['personalization_version_at_observation'] = Variable<String>(
        personalizationVersionAtObservation,
      );
    }
    if (!nullToAbsent || effectiveModelFingerprintAtObservation != null) {
      map['effective_model_fingerprint_at_observation'] = Variable<String>(
        effectiveModelFingerprintAtObservation,
      );
    }
    if (!nullToAbsent || modelRegimeEpochAtObservation != null) {
      map['model_regime_epoch_at_observation'] = Variable<String>(
        modelRegimeEpochAtObservation,
      );
    }
    if (!nullToAbsent || activeActivityCountAtObservation != null) {
      map['active_activity_count_at_observation'] = Variable<int>(
        activeActivityCountAtObservation,
      );
    }
    if (!nullToAbsent || coverageState != null) {
      map['coverage_state'] = Variable<String>(
        $EnergyObservationsTableTable.$convertercoverageStaten.toSql(
          coverageState,
        ),
      );
    }
    if (!nullToAbsent || modelRegimeKey != null) {
      map['model_regime_key'] = Variable<String>(modelRegimeKey);
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
      contractVersion: contractVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(contractVersion),
      referenceType: referenceType == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceType),
      initialEstimateAtObservation:
          initialEstimateAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(initialEstimateAtObservation),
      estimatedOrdinalAtObservation:
          estimatedOrdinalAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedOrdinalAtObservation),
      baseEnergyAtObservation: baseEnergyAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(baseEnergyAtObservation),
      ruleVersionAtObservation: ruleVersionAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(ruleVersionAtObservation),
      comparisonBandVersion: comparisonBandVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(comparisonBandVersion),
      personalizationVersionAtObservation:
          personalizationVersionAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(personalizationVersionAtObservation),
      effectiveModelFingerprintAtObservation:
          effectiveModelFingerprintAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveModelFingerprintAtObservation),
      modelRegimeEpochAtObservation:
          modelRegimeEpochAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(modelRegimeEpochAtObservation),
      activeActivityCountAtObservation:
          activeActivityCountAtObservation == null && nullToAbsent
          ? const Value.absent()
          : Value(activeActivityCountAtObservation),
      coverageState: coverageState == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageState),
      modelRegimeKey: modelRegimeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(modelRegimeKey),
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
      contractVersion: serializer.fromJson<String?>(json['contractVersion']),
      referenceType: serializer.fromJson<ObservationReferenceType?>(
        json['referenceType'],
      ),
      initialEstimateAtObservation: serializer.fromJson<int?>(
        json['initialEstimateAtObservation'],
      ),
      estimatedOrdinalAtObservation: serializer.fromJson<int?>(
        json['estimatedOrdinalAtObservation'],
      ),
      baseEnergyAtObservation: serializer.fromJson<int?>(
        json['baseEnergyAtObservation'],
      ),
      ruleVersionAtObservation: serializer.fromJson<String?>(
        json['ruleVersionAtObservation'],
      ),
      comparisonBandVersion: serializer.fromJson<String?>(
        json['comparisonBandVersion'],
      ),
      personalizationVersionAtObservation: serializer.fromJson<String?>(
        json['personalizationVersionAtObservation'],
      ),
      effectiveModelFingerprintAtObservation: serializer.fromJson<String?>(
        json['effectiveModelFingerprintAtObservation'],
      ),
      modelRegimeEpochAtObservation: serializer.fromJson<String?>(
        json['modelRegimeEpochAtObservation'],
      ),
      activeActivityCountAtObservation: serializer.fromJson<int?>(
        json['activeActivityCountAtObservation'],
      ),
      coverageState: serializer.fromJson<ObservationCoverageState?>(
        json['coverageState'],
      ),
      modelRegimeKey: serializer.fromJson<String?>(json['modelRegimeKey']),
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
      'contractVersion': serializer.toJson<String?>(contractVersion),
      'referenceType': serializer.toJson<ObservationReferenceType?>(
        referenceType,
      ),
      'initialEstimateAtObservation': serializer.toJson<int?>(
        initialEstimateAtObservation,
      ),
      'estimatedOrdinalAtObservation': serializer.toJson<int?>(
        estimatedOrdinalAtObservation,
      ),
      'baseEnergyAtObservation': serializer.toJson<int?>(
        baseEnergyAtObservation,
      ),
      'ruleVersionAtObservation': serializer.toJson<String?>(
        ruleVersionAtObservation,
      ),
      'comparisonBandVersion': serializer.toJson<String?>(
        comparisonBandVersion,
      ),
      'personalizationVersionAtObservation': serializer.toJson<String?>(
        personalizationVersionAtObservation,
      ),
      'effectiveModelFingerprintAtObservation': serializer.toJson<String?>(
        effectiveModelFingerprintAtObservation,
      ),
      'modelRegimeEpochAtObservation': serializer.toJson<String?>(
        modelRegimeEpochAtObservation,
      ),
      'activeActivityCountAtObservation': serializer.toJson<int?>(
        activeActivityCountAtObservation,
      ),
      'coverageState': serializer.toJson<ObservationCoverageState?>(
        coverageState,
      ),
      'modelRegimeKey': serializer.toJson<String?>(modelRegimeKey),
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
    Value<String?> contractVersion = const Value.absent(),
    Value<ObservationReferenceType?> referenceType = const Value.absent(),
    Value<int?> initialEstimateAtObservation = const Value.absent(),
    Value<int?> estimatedOrdinalAtObservation = const Value.absent(),
    Value<int?> baseEnergyAtObservation = const Value.absent(),
    Value<String?> ruleVersionAtObservation = const Value.absent(),
    Value<String?> comparisonBandVersion = const Value.absent(),
    Value<String?> personalizationVersionAtObservation = const Value.absent(),
    Value<String?> effectiveModelFingerprintAtObservation =
        const Value.absent(),
    Value<String?> modelRegimeEpochAtObservation = const Value.absent(),
    Value<int?> activeActivityCountAtObservation = const Value.absent(),
    Value<ObservationCoverageState?> coverageState = const Value.absent(),
    Value<String?> modelRegimeKey = const Value.absent(),
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
    contractVersion: contractVersion.present
        ? contractVersion.value
        : this.contractVersion,
    referenceType: referenceType.present
        ? referenceType.value
        : this.referenceType,
    initialEstimateAtObservation: initialEstimateAtObservation.present
        ? initialEstimateAtObservation.value
        : this.initialEstimateAtObservation,
    estimatedOrdinalAtObservation: estimatedOrdinalAtObservation.present
        ? estimatedOrdinalAtObservation.value
        : this.estimatedOrdinalAtObservation,
    baseEnergyAtObservation: baseEnergyAtObservation.present
        ? baseEnergyAtObservation.value
        : this.baseEnergyAtObservation,
    ruleVersionAtObservation: ruleVersionAtObservation.present
        ? ruleVersionAtObservation.value
        : this.ruleVersionAtObservation,
    comparisonBandVersion: comparisonBandVersion.present
        ? comparisonBandVersion.value
        : this.comparisonBandVersion,
    personalizationVersionAtObservation:
        personalizationVersionAtObservation.present
        ? personalizationVersionAtObservation.value
        : this.personalizationVersionAtObservation,
    effectiveModelFingerprintAtObservation:
        effectiveModelFingerprintAtObservation.present
        ? effectiveModelFingerprintAtObservation.value
        : this.effectiveModelFingerprintAtObservation,
    modelRegimeEpochAtObservation: modelRegimeEpochAtObservation.present
        ? modelRegimeEpochAtObservation.value
        : this.modelRegimeEpochAtObservation,
    activeActivityCountAtObservation: activeActivityCountAtObservation.present
        ? activeActivityCountAtObservation.value
        : this.activeActivityCountAtObservation,
    coverageState: coverageState.present
        ? coverageState.value
        : this.coverageState,
    modelRegimeKey: modelRegimeKey.present
        ? modelRegimeKey.value
        : this.modelRegimeKey,
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
      contractVersion: data.contractVersion.present
          ? data.contractVersion.value
          : this.contractVersion,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      initialEstimateAtObservation: data.initialEstimateAtObservation.present
          ? data.initialEstimateAtObservation.value
          : this.initialEstimateAtObservation,
      estimatedOrdinalAtObservation: data.estimatedOrdinalAtObservation.present
          ? data.estimatedOrdinalAtObservation.value
          : this.estimatedOrdinalAtObservation,
      baseEnergyAtObservation: data.baseEnergyAtObservation.present
          ? data.baseEnergyAtObservation.value
          : this.baseEnergyAtObservation,
      ruleVersionAtObservation: data.ruleVersionAtObservation.present
          ? data.ruleVersionAtObservation.value
          : this.ruleVersionAtObservation,
      comparisonBandVersion: data.comparisonBandVersion.present
          ? data.comparisonBandVersion.value
          : this.comparisonBandVersion,
      personalizationVersionAtObservation:
          data.personalizationVersionAtObservation.present
          ? data.personalizationVersionAtObservation.value
          : this.personalizationVersionAtObservation,
      effectiveModelFingerprintAtObservation:
          data.effectiveModelFingerprintAtObservation.present
          ? data.effectiveModelFingerprintAtObservation.value
          : this.effectiveModelFingerprintAtObservation,
      modelRegimeEpochAtObservation: data.modelRegimeEpochAtObservation.present
          ? data.modelRegimeEpochAtObservation.value
          : this.modelRegimeEpochAtObservation,
      activeActivityCountAtObservation:
          data.activeActivityCountAtObservation.present
          ? data.activeActivityCountAtObservation.value
          : this.activeActivityCountAtObservation,
      coverageState: data.coverageState.present
          ? data.coverageState.value
          : this.coverageState,
      modelRegimeKey: data.modelRegimeKey.present
          ? data.modelRegimeKey.value
          : this.modelRegimeKey,
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
          ..write('contractVersion: $contractVersion, ')
          ..write('referenceType: $referenceType, ')
          ..write(
            'initialEstimateAtObservation: $initialEstimateAtObservation, ',
          )
          ..write(
            'estimatedOrdinalAtObservation: $estimatedOrdinalAtObservation, ',
          )
          ..write('baseEnergyAtObservation: $baseEnergyAtObservation, ')
          ..write('ruleVersionAtObservation: $ruleVersionAtObservation, ')
          ..write('comparisonBandVersion: $comparisonBandVersion, ')
          ..write(
            'personalizationVersionAtObservation: $personalizationVersionAtObservation, ',
          )
          ..write(
            'effectiveModelFingerprintAtObservation: $effectiveModelFingerprintAtObservation, ',
          )
          ..write(
            'modelRegimeEpochAtObservation: $modelRegimeEpochAtObservation, ',
          )
          ..write(
            'activeActivityCountAtObservation: $activeActivityCountAtObservation, ',
          )
          ..write('coverageState: $coverageState, ')
          ..write('modelRegimeKey: $modelRegimeKey, ')
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
    contractVersion,
    referenceType,
    initialEstimateAtObservation,
    estimatedOrdinalAtObservation,
    baseEnergyAtObservation,
    ruleVersionAtObservation,
    comparisonBandVersion,
    personalizationVersionAtObservation,
    effectiveModelFingerprintAtObservation,
    modelRegimeEpochAtObservation,
    activeActivityCountAtObservation,
    coverageState,
    modelRegimeKey,
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
          other.contractVersion == this.contractVersion &&
          other.referenceType == this.referenceType &&
          other.initialEstimateAtObservation ==
              this.initialEstimateAtObservation &&
          other.estimatedOrdinalAtObservation ==
              this.estimatedOrdinalAtObservation &&
          other.baseEnergyAtObservation == this.baseEnergyAtObservation &&
          other.ruleVersionAtObservation == this.ruleVersionAtObservation &&
          other.comparisonBandVersion == this.comparisonBandVersion &&
          other.personalizationVersionAtObservation ==
              this.personalizationVersionAtObservation &&
          other.effectiveModelFingerprintAtObservation ==
              this.effectiveModelFingerprintAtObservation &&
          other.modelRegimeEpochAtObservation ==
              this.modelRegimeEpochAtObservation &&
          other.activeActivityCountAtObservation ==
              this.activeActivityCountAtObservation &&
          other.coverageState == this.coverageState &&
          other.modelRegimeKey == this.modelRegimeKey &&
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
  final Value<String?> contractVersion;
  final Value<ObservationReferenceType?> referenceType;
  final Value<int?> initialEstimateAtObservation;
  final Value<int?> estimatedOrdinalAtObservation;
  final Value<int?> baseEnergyAtObservation;
  final Value<String?> ruleVersionAtObservation;
  final Value<String?> comparisonBandVersion;
  final Value<String?> personalizationVersionAtObservation;
  final Value<String?> effectiveModelFingerprintAtObservation;
  final Value<String?> modelRegimeEpochAtObservation;
  final Value<int?> activeActivityCountAtObservation;
  final Value<ObservationCoverageState?> coverageState;
  final Value<String?> modelRegimeKey;
  final Value<DateTime> observedAt;
  final Value<int> rowid;
  const EnergyObservationsTableCompanion({
    this.id = const Value.absent(),
    this.lifeDay = const Value.absent(),
    this.type = const Value.absent(),
    this.absoluteState = const Value.absent(),
    this.relativeState = const Value.absent(),
    this.estimateAtObservation = const Value.absent(),
    this.contractVersion = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.initialEstimateAtObservation = const Value.absent(),
    this.estimatedOrdinalAtObservation = const Value.absent(),
    this.baseEnergyAtObservation = const Value.absent(),
    this.ruleVersionAtObservation = const Value.absent(),
    this.comparisonBandVersion = const Value.absent(),
    this.personalizationVersionAtObservation = const Value.absent(),
    this.effectiveModelFingerprintAtObservation = const Value.absent(),
    this.modelRegimeEpochAtObservation = const Value.absent(),
    this.activeActivityCountAtObservation = const Value.absent(),
    this.coverageState = const Value.absent(),
    this.modelRegimeKey = const Value.absent(),
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
    this.contractVersion = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.initialEstimateAtObservation = const Value.absent(),
    this.estimatedOrdinalAtObservation = const Value.absent(),
    this.baseEnergyAtObservation = const Value.absent(),
    this.ruleVersionAtObservation = const Value.absent(),
    this.comparisonBandVersion = const Value.absent(),
    this.personalizationVersionAtObservation = const Value.absent(),
    this.effectiveModelFingerprintAtObservation = const Value.absent(),
    this.modelRegimeEpochAtObservation = const Value.absent(),
    this.activeActivityCountAtObservation = const Value.absent(),
    this.coverageState = const Value.absent(),
    this.modelRegimeKey = const Value.absent(),
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
    Expression<String>? contractVersion,
    Expression<String>? referenceType,
    Expression<int>? initialEstimateAtObservation,
    Expression<int>? estimatedOrdinalAtObservation,
    Expression<int>? baseEnergyAtObservation,
    Expression<String>? ruleVersionAtObservation,
    Expression<String>? comparisonBandVersion,
    Expression<String>? personalizationVersionAtObservation,
    Expression<String>? effectiveModelFingerprintAtObservation,
    Expression<String>? modelRegimeEpochAtObservation,
    Expression<int>? activeActivityCountAtObservation,
    Expression<String>? coverageState,
    Expression<String>? modelRegimeKey,
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
      if (contractVersion != null) 'contract_version': contractVersion,
      if (referenceType != null) 'reference_type': referenceType,
      if (initialEstimateAtObservation != null)
        'initial_estimate_at_observation': initialEstimateAtObservation,
      if (estimatedOrdinalAtObservation != null)
        'estimated_ordinal_at_observation': estimatedOrdinalAtObservation,
      if (baseEnergyAtObservation != null)
        'base_energy_at_observation': baseEnergyAtObservation,
      if (ruleVersionAtObservation != null)
        'rule_version_at_observation': ruleVersionAtObservation,
      if (comparisonBandVersion != null)
        'comparison_band_version': comparisonBandVersion,
      if (personalizationVersionAtObservation != null)
        'personalization_version_at_observation':
            personalizationVersionAtObservation,
      if (effectiveModelFingerprintAtObservation != null)
        'effective_model_fingerprint_at_observation':
            effectiveModelFingerprintAtObservation,
      if (modelRegimeEpochAtObservation != null)
        'model_regime_epoch_at_observation': modelRegimeEpochAtObservation,
      if (activeActivityCountAtObservation != null)
        'active_activity_count_at_observation':
            activeActivityCountAtObservation,
      if (coverageState != null) 'coverage_state': coverageState,
      if (modelRegimeKey != null) 'model_regime_key': modelRegimeKey,
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
    Value<String?>? contractVersion,
    Value<ObservationReferenceType?>? referenceType,
    Value<int?>? initialEstimateAtObservation,
    Value<int?>? estimatedOrdinalAtObservation,
    Value<int?>? baseEnergyAtObservation,
    Value<String?>? ruleVersionAtObservation,
    Value<String?>? comparisonBandVersion,
    Value<String?>? personalizationVersionAtObservation,
    Value<String?>? effectiveModelFingerprintAtObservation,
    Value<String?>? modelRegimeEpochAtObservation,
    Value<int?>? activeActivityCountAtObservation,
    Value<ObservationCoverageState?>? coverageState,
    Value<String?>? modelRegimeKey,
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
      contractVersion: contractVersion ?? this.contractVersion,
      referenceType: referenceType ?? this.referenceType,
      initialEstimateAtObservation:
          initialEstimateAtObservation ?? this.initialEstimateAtObservation,
      estimatedOrdinalAtObservation:
          estimatedOrdinalAtObservation ?? this.estimatedOrdinalAtObservation,
      baseEnergyAtObservation:
          baseEnergyAtObservation ?? this.baseEnergyAtObservation,
      ruleVersionAtObservation:
          ruleVersionAtObservation ?? this.ruleVersionAtObservation,
      comparisonBandVersion:
          comparisonBandVersion ?? this.comparisonBandVersion,
      personalizationVersionAtObservation:
          personalizationVersionAtObservation ??
          this.personalizationVersionAtObservation,
      effectiveModelFingerprintAtObservation:
          effectiveModelFingerprintAtObservation ??
          this.effectiveModelFingerprintAtObservation,
      modelRegimeEpochAtObservation:
          modelRegimeEpochAtObservation ?? this.modelRegimeEpochAtObservation,
      activeActivityCountAtObservation:
          activeActivityCountAtObservation ??
          this.activeActivityCountAtObservation,
      coverageState: coverageState ?? this.coverageState,
      modelRegimeKey: modelRegimeKey ?? this.modelRegimeKey,
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
    if (contractVersion.present) {
      map['contract_version'] = Variable<String>(contractVersion.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(
        $EnergyObservationsTableTable.$converterreferenceTypen.toSql(
          referenceType.value,
        ),
      );
    }
    if (initialEstimateAtObservation.present) {
      map['initial_estimate_at_observation'] = Variable<int>(
        initialEstimateAtObservation.value,
      );
    }
    if (estimatedOrdinalAtObservation.present) {
      map['estimated_ordinal_at_observation'] = Variable<int>(
        estimatedOrdinalAtObservation.value,
      );
    }
    if (baseEnergyAtObservation.present) {
      map['base_energy_at_observation'] = Variable<int>(
        baseEnergyAtObservation.value,
      );
    }
    if (ruleVersionAtObservation.present) {
      map['rule_version_at_observation'] = Variable<String>(
        ruleVersionAtObservation.value,
      );
    }
    if (comparisonBandVersion.present) {
      map['comparison_band_version'] = Variable<String>(
        comparisonBandVersion.value,
      );
    }
    if (personalizationVersionAtObservation.present) {
      map['personalization_version_at_observation'] = Variable<String>(
        personalizationVersionAtObservation.value,
      );
    }
    if (effectiveModelFingerprintAtObservation.present) {
      map['effective_model_fingerprint_at_observation'] = Variable<String>(
        effectiveModelFingerprintAtObservation.value,
      );
    }
    if (modelRegimeEpochAtObservation.present) {
      map['model_regime_epoch_at_observation'] = Variable<String>(
        modelRegimeEpochAtObservation.value,
      );
    }
    if (activeActivityCountAtObservation.present) {
      map['active_activity_count_at_observation'] = Variable<int>(
        activeActivityCountAtObservation.value,
      );
    }
    if (coverageState.present) {
      map['coverage_state'] = Variable<String>(
        $EnergyObservationsTableTable.$convertercoverageStaten.toSql(
          coverageState.value,
        ),
      );
    }
    if (modelRegimeKey.present) {
      map['model_regime_key'] = Variable<String>(modelRegimeKey.value);
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
          ..write('contractVersion: $contractVersion, ')
          ..write('referenceType: $referenceType, ')
          ..write(
            'initialEstimateAtObservation: $initialEstimateAtObservation, ',
          )
          ..write(
            'estimatedOrdinalAtObservation: $estimatedOrdinalAtObservation, ',
          )
          ..write('baseEnergyAtObservation: $baseEnergyAtObservation, ')
          ..write('ruleVersionAtObservation: $ruleVersionAtObservation, ')
          ..write('comparisonBandVersion: $comparisonBandVersion, ')
          ..write(
            'personalizationVersionAtObservation: $personalizationVersionAtObservation, ',
          )
          ..write(
            'effectiveModelFingerprintAtObservation: $effectiveModelFingerprintAtObservation, ',
          )
          ..write(
            'modelRegimeEpochAtObservation: $modelRegimeEpochAtObservation, ',
          )
          ..write(
            'activeActivityCountAtObservation: $activeActivityCountAtObservation, ',
          )
          ..write('coverageState: $coverageState, ')
          ..write('modelRegimeKey: $modelRegimeKey, ')
          ..write('observedAt: $observedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityFeedbackTableTable extends ActivityFeedbackTable
    with TableInfo<$ActivityFeedbackTableTable, ActivityFeedbackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityFeedbackTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityRecordIdMeta = const VerificationMeta(
    'activityRecordId',
  );
  @override
  late final GeneratedColumn<String> activityRecordId = GeneratedColumn<String>(
    'activity_record_id',
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
      ).withConverter<LifeDay>($ActivityFeedbackTableTable.$converterlifeDay);
  @override
  late final GeneratedColumnWithTypeConverter<ActivitySubcategory, String>
  subcategorySnapshot =
      GeneratedColumn<String>(
        'subcategory_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivitySubcategory>(
        $ActivityFeedbackTableTable.$convertersubcategorySnapshot,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DurationSlot, int>
  durationSnapshot =
      GeneratedColumn<int>(
        'duration_minutes_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DurationSlot>(
        $ActivityFeedbackTableTable.$converterdurationSnapshot,
      );
  static const VerificationMeta _theoreticalDeltaSnapshotMeta =
      const VerificationMeta('theoreticalDeltaSnapshot');
  @override
  late final GeneratedColumn<int> theoreticalDeltaSnapshot =
      GeneratedColumn<int>(
        'theoretical_delta_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _appliedDeltaSnapshotMeta =
      const VerificationMeta('appliedDeltaSnapshot');
  @override
  late final GeneratedColumn<int> appliedDeltaSnapshot = GeneratedColumn<int>(
    'applied_delta_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultTheoreticalDeltaSnapshotMeta =
      const VerificationMeta('defaultTheoreticalDeltaSnapshot');
  @override
  late final GeneratedColumn<int> defaultTheoreticalDeltaSnapshot =
      GeneratedColumn<int>(
        'default_theoretical_delta_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _factorSnapshotMeta = const VerificationMeta(
    'factorSnapshot',
  );
  @override
  late final GeneratedColumn<double> factorSnapshot = GeneratedColumn<double>(
    'factor_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _personalizedTheoreticalDeltaSnapshotMeta =
      const VerificationMeta('personalizedTheoreticalDeltaSnapshot');
  @override
  late final GeneratedColumn<int> personalizedTheoreticalDeltaSnapshot =
      GeneratedColumn<int>(
        'personalized_theoretical_delta_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _personalizationVersionIdMeta =
      const VerificationMeta('personalizationVersionId');
  @override
  late final GeneratedColumn<String> personalizationVersionId =
      GeneratedColumn<String>(
        'personalization_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay?, String>
  factorRegimeStartedLifeDay =
      GeneratedColumn<String>(
        'factor_regime_started_life_day',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LifeDay?>(
        $ActivityFeedbackTableTable.$converterfactorRegimeStartedLifeDayn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityImpactSign, String>
  impactSignSnapshot =
      GeneratedColumn<String>(
        'impact_sign_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityImpactSign>(
        $ActivityFeedbackTableTable.$converterimpactSignSnapshot,
      );
  static const VerificationMeta _ruleVersionSnapshotMeta =
      const VerificationMeta('ruleVersionSnapshot');
  @override
  late final GeneratedColumn<String> ruleVersionSnapshot =
      GeneratedColumn<String>(
        'rule_version_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _activityUpdatedAtSnapshotMeta =
      const VerificationMeta('activityUpdatedAtSnapshot');
  @override
  late final GeneratedColumn<DateTime> activityUpdatedAtSnapshot =
      GeneratedColumn<DateTime>(
        'activity_updated_at_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityFeedbackDirection, String>
  direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityFeedbackDirection>(
        $ActivityFeedbackTableTable.$converterdirection,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    ActivityFeedbackCollectionSource,
    String
  >
  collectionSource =
      GeneratedColumn<String>(
        'collection_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('userInitiated'),
      ).withConverter<ActivityFeedbackCollectionSource>(
        $ActivityFeedbackTableTable.$convertercollectionSource,
      );
  static const VerificationMeta _samplingPolicyVersionMeta =
      const VerificationMeta('samplingPolicyVersion');
  @override
  late final GeneratedColumn<String> samplingPolicyVersion =
      GeneratedColumn<String>(
        'sampling_policy_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sampledAtMeta = const VerificationMeta(
    'sampledAt',
  );
  @override
  late final GeneratedColumn<DateTime> sampledAt = GeneratedColumn<DateTime>(
    'sampled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleIdMeta = const VerificationMeta(
    'sampleId',
  );
  @override
  late final GeneratedColumn<String> sampleId = GeneratedColumn<String>(
    'sample_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityFeedbackStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityFeedbackStatus>(
        $ActivityFeedbackTableTable.$converterstatus,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    ActivityFeedbackInvalidationReason?,
    String
  >
  invalidationReason =
      GeneratedColumn<String>(
        'invalidation_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ActivityFeedbackInvalidationReason?>(
        $ActivityFeedbackTableTable.$converterinvalidationReasonn,
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
    activityRecordId,
    lifeDay,
    subcategorySnapshot,
    durationSnapshot,
    theoreticalDeltaSnapshot,
    appliedDeltaSnapshot,
    defaultTheoreticalDeltaSnapshot,
    factorSnapshot,
    personalizedTheoreticalDeltaSnapshot,
    personalizationVersionId,
    factorRegimeStartedLifeDay,
    impactSignSnapshot,
    ruleVersionSnapshot,
    activityUpdatedAtSnapshot,
    direction,
    collectionSource,
    samplingPolicyVersion,
    sampledAt,
    sampleId,
    status,
    invalidationReason,
    observedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityFeedbackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_record_id')) {
      context.handle(
        _activityRecordIdMeta,
        activityRecordId.isAcceptableOrUnknown(
          data['activity_record_id']!,
          _activityRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityRecordIdMeta);
    }
    if (data.containsKey('theoretical_delta_snapshot')) {
      context.handle(
        _theoreticalDeltaSnapshotMeta,
        theoreticalDeltaSnapshot.isAcceptableOrUnknown(
          data['theoretical_delta_snapshot']!,
          _theoreticalDeltaSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_theoreticalDeltaSnapshotMeta);
    }
    if (data.containsKey('applied_delta_snapshot')) {
      context.handle(
        _appliedDeltaSnapshotMeta,
        appliedDeltaSnapshot.isAcceptableOrUnknown(
          data['applied_delta_snapshot']!,
          _appliedDeltaSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedDeltaSnapshotMeta);
    }
    if (data.containsKey('default_theoretical_delta_snapshot')) {
      context.handle(
        _defaultTheoreticalDeltaSnapshotMeta,
        defaultTheoreticalDeltaSnapshot.isAcceptableOrUnknown(
          data['default_theoretical_delta_snapshot']!,
          _defaultTheoreticalDeltaSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('factor_snapshot')) {
      context.handle(
        _factorSnapshotMeta,
        factorSnapshot.isAcceptableOrUnknown(
          data['factor_snapshot']!,
          _factorSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('personalized_theoretical_delta_snapshot')) {
      context.handle(
        _personalizedTheoreticalDeltaSnapshotMeta,
        personalizedTheoreticalDeltaSnapshot.isAcceptableOrUnknown(
          data['personalized_theoretical_delta_snapshot']!,
          _personalizedTheoreticalDeltaSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('personalization_version_id')) {
      context.handle(
        _personalizationVersionIdMeta,
        personalizationVersionId.isAcceptableOrUnknown(
          data['personalization_version_id']!,
          _personalizationVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('rule_version_snapshot')) {
      context.handle(
        _ruleVersionSnapshotMeta,
        ruleVersionSnapshot.isAcceptableOrUnknown(
          data['rule_version_snapshot']!,
          _ruleVersionSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionSnapshotMeta);
    }
    if (data.containsKey('activity_updated_at_snapshot')) {
      context.handle(
        _activityUpdatedAtSnapshotMeta,
        activityUpdatedAtSnapshot.isAcceptableOrUnknown(
          data['activity_updated_at_snapshot']!,
          _activityUpdatedAtSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityUpdatedAtSnapshotMeta);
    }
    if (data.containsKey('sampling_policy_version')) {
      context.handle(
        _samplingPolicyVersionMeta,
        samplingPolicyVersion.isAcceptableOrUnknown(
          data['sampling_policy_version']!,
          _samplingPolicyVersionMeta,
        ),
      );
    }
    if (data.containsKey('sampled_at')) {
      context.handle(
        _sampledAtMeta,
        sampledAt.isAcceptableOrUnknown(data['sampled_at']!, _sampledAtMeta),
      );
    }
    if (data.containsKey('sample_id')) {
      context.handle(
        _sampleIdMeta,
        sampleId.isAcceptableOrUnknown(data['sample_id']!, _sampleIdMeta),
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
  ActivityFeedbackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityFeedbackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activityRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_record_id'],
      )!,
      lifeDay: $ActivityFeedbackTableTable.$converterlifeDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}life_day'],
        )!,
      ),
      subcategorySnapshot: $ActivityFeedbackTableTable
          .$convertersubcategorySnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}subcategory_snapshot'],
            )!,
          ),
      durationSnapshot: $ActivityFeedbackTableTable.$converterdurationSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}duration_minutes_snapshot'],
            )!,
          ),
      theoreticalDeltaSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}theoretical_delta_snapshot'],
      )!,
      appliedDeltaSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_delta_snapshot'],
      )!,
      defaultTheoreticalDeltaSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_theoretical_delta_snapshot'],
      )!,
      factorSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}factor_snapshot'],
      )!,
      personalizedTheoreticalDeltaSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personalized_theoretical_delta_snapshot'],
      )!,
      personalizationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personalization_version_id'],
      ),
      factorRegimeStartedLifeDay: $ActivityFeedbackTableTable
          .$converterfactorRegimeStartedLifeDayn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}factor_regime_started_life_day'],
            ),
          ),
      impactSignSnapshot: $ActivityFeedbackTableTable
          .$converterimpactSignSnapshot
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}impact_sign_snapshot'],
            )!,
          ),
      ruleVersionSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version_snapshot'],
      )!,
      activityUpdatedAtSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activity_updated_at_snapshot'],
      )!,
      direction: $ActivityFeedbackTableTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      collectionSource: $ActivityFeedbackTableTable.$convertercollectionSource
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}collection_source'],
            )!,
          ),
      samplingPolicyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sampling_policy_version'],
      ),
      sampledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sampled_at'],
      ),
      sampleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_id'],
      ),
      status: $ActivityFeedbackTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      invalidationReason: $ActivityFeedbackTableTable
          .$converterinvalidationReasonn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}invalidation_reason'],
            ),
          ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
    );
  }

  @override
  $ActivityFeedbackTableTable createAlias(String alias) {
    return $ActivityFeedbackTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterlifeDay =
      const LifeDayConverter();
  static TypeConverter<ActivitySubcategory, String>
  $convertersubcategorySnapshot = const ActivitySubcategoryConverter();
  static TypeConverter<DurationSlot, int> $converterdurationSnapshot =
      const DurationSlotConverter();
  static TypeConverter<LifeDay, String> $converterfactorRegimeStartedLifeDay =
      const LifeDayConverter();
  static TypeConverter<LifeDay?, String?>
  $converterfactorRegimeStartedLifeDayn = NullAwareTypeConverter.wrap(
    $converterfactorRegimeStartedLifeDay,
  );
  static TypeConverter<ActivityImpactSign, String>
  $converterimpactSignSnapshot = const ActivityImpactSignConverter();
  static TypeConverter<ActivityFeedbackDirection, String> $converterdirection =
      const ActivityFeedbackDirectionConverter();
  static TypeConverter<ActivityFeedbackCollectionSource, String>
  $convertercollectionSource =
      const ActivityFeedbackCollectionSourceConverter();
  static TypeConverter<ActivityFeedbackStatus, String> $converterstatus =
      const ActivityFeedbackStatusConverter();
  static TypeConverter<ActivityFeedbackInvalidationReason, String>
  $converterinvalidationReason =
      const ActivityFeedbackInvalidationReasonConverter();
  static TypeConverter<ActivityFeedbackInvalidationReason?, String?>
  $converterinvalidationReasonn = NullAwareTypeConverter.wrap(
    $converterinvalidationReason,
  );
}

class ActivityFeedbackRow extends DataClass
    implements Insertable<ActivityFeedbackRow> {
  final String id;
  final String activityRecordId;
  final LifeDay lifeDay;
  final ActivitySubcategory subcategorySnapshot;
  final DurationSlot durationSnapshot;
  final int theoreticalDeltaSnapshot;
  final int appliedDeltaSnapshot;
  final int defaultTheoreticalDeltaSnapshot;
  final double factorSnapshot;
  final int personalizedTheoreticalDeltaSnapshot;
  final String? personalizationVersionId;
  final LifeDay? factorRegimeStartedLifeDay;
  final ActivityImpactSign impactSignSnapshot;
  final String ruleVersionSnapshot;
  final DateTime activityUpdatedAtSnapshot;
  final ActivityFeedbackDirection direction;
  final ActivityFeedbackCollectionSource collectionSource;
  final String? samplingPolicyVersion;
  final DateTime? sampledAt;
  final String? sampleId;
  final ActivityFeedbackStatus status;
  final ActivityFeedbackInvalidationReason? invalidationReason;
  final DateTime observedAt;
  const ActivityFeedbackRow({
    required this.id,
    required this.activityRecordId,
    required this.lifeDay,
    required this.subcategorySnapshot,
    required this.durationSnapshot,
    required this.theoreticalDeltaSnapshot,
    required this.appliedDeltaSnapshot,
    required this.defaultTheoreticalDeltaSnapshot,
    required this.factorSnapshot,
    required this.personalizedTheoreticalDeltaSnapshot,
    this.personalizationVersionId,
    this.factorRegimeStartedLifeDay,
    required this.impactSignSnapshot,
    required this.ruleVersionSnapshot,
    required this.activityUpdatedAtSnapshot,
    required this.direction,
    required this.collectionSource,
    this.samplingPolicyVersion,
    this.sampledAt,
    this.sampleId,
    required this.status,
    this.invalidationReason,
    required this.observedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_record_id'] = Variable<String>(activityRecordId);
    {
      map['life_day'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterlifeDay.toSql(lifeDay),
      );
    }
    {
      map['subcategory_snapshot'] = Variable<String>(
        $ActivityFeedbackTableTable.$convertersubcategorySnapshot.toSql(
          subcategorySnapshot,
        ),
      );
    }
    {
      map['duration_minutes_snapshot'] = Variable<int>(
        $ActivityFeedbackTableTable.$converterdurationSnapshot.toSql(
          durationSnapshot,
        ),
      );
    }
    map['theoretical_delta_snapshot'] = Variable<int>(theoreticalDeltaSnapshot);
    map['applied_delta_snapshot'] = Variable<int>(appliedDeltaSnapshot);
    map['default_theoretical_delta_snapshot'] = Variable<int>(
      defaultTheoreticalDeltaSnapshot,
    );
    map['factor_snapshot'] = Variable<double>(factorSnapshot);
    map['personalized_theoretical_delta_snapshot'] = Variable<int>(
      personalizedTheoreticalDeltaSnapshot,
    );
    if (!nullToAbsent || personalizationVersionId != null) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId,
      );
    }
    if (!nullToAbsent || factorRegimeStartedLifeDay != null) {
      map['factor_regime_started_life_day'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterfactorRegimeStartedLifeDayn.toSql(
          factorRegimeStartedLifeDay,
        ),
      );
    }
    {
      map['impact_sign_snapshot'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterimpactSignSnapshot.toSql(
          impactSignSnapshot,
        ),
      );
    }
    map['rule_version_snapshot'] = Variable<String>(ruleVersionSnapshot);
    map['activity_updated_at_snapshot'] = Variable<DateTime>(
      activityUpdatedAtSnapshot,
    );
    {
      map['direction'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterdirection.toSql(direction),
      );
    }
    {
      map['collection_source'] = Variable<String>(
        $ActivityFeedbackTableTable.$convertercollectionSource.toSql(
          collectionSource,
        ),
      );
    }
    if (!nullToAbsent || samplingPolicyVersion != null) {
      map['sampling_policy_version'] = Variable<String>(samplingPolicyVersion);
    }
    if (!nullToAbsent || sampledAt != null) {
      map['sampled_at'] = Variable<DateTime>(sampledAt);
    }
    if (!nullToAbsent || sampleId != null) {
      map['sample_id'] = Variable<String>(sampleId);
    }
    {
      map['status'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || invalidationReason != null) {
      map['invalidation_reason'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterinvalidationReasonn.toSql(
          invalidationReason,
        ),
      );
    }
    map['observed_at'] = Variable<DateTime>(observedAt);
    return map;
  }

  ActivityFeedbackTableCompanion toCompanion(bool nullToAbsent) {
    return ActivityFeedbackTableCompanion(
      id: Value(id),
      activityRecordId: Value(activityRecordId),
      lifeDay: Value(lifeDay),
      subcategorySnapshot: Value(subcategorySnapshot),
      durationSnapshot: Value(durationSnapshot),
      theoreticalDeltaSnapshot: Value(theoreticalDeltaSnapshot),
      appliedDeltaSnapshot: Value(appliedDeltaSnapshot),
      defaultTheoreticalDeltaSnapshot: Value(defaultTheoreticalDeltaSnapshot),
      factorSnapshot: Value(factorSnapshot),
      personalizedTheoreticalDeltaSnapshot: Value(
        personalizedTheoreticalDeltaSnapshot,
      ),
      personalizationVersionId: personalizationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(personalizationVersionId),
      factorRegimeStartedLifeDay:
          factorRegimeStartedLifeDay == null && nullToAbsent
          ? const Value.absent()
          : Value(factorRegimeStartedLifeDay),
      impactSignSnapshot: Value(impactSignSnapshot),
      ruleVersionSnapshot: Value(ruleVersionSnapshot),
      activityUpdatedAtSnapshot: Value(activityUpdatedAtSnapshot),
      direction: Value(direction),
      collectionSource: Value(collectionSource),
      samplingPolicyVersion: samplingPolicyVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(samplingPolicyVersion),
      sampledAt: sampledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sampledAt),
      sampleId: sampleId == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleId),
      status: Value(status),
      invalidationReason: invalidationReason == null && nullToAbsent
          ? const Value.absent()
          : Value(invalidationReason),
      observedAt: Value(observedAt),
    );
  }

  factory ActivityFeedbackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityFeedbackRow(
      id: serializer.fromJson<String>(json['id']),
      activityRecordId: serializer.fromJson<String>(json['activityRecordId']),
      lifeDay: serializer.fromJson<LifeDay>(json['lifeDay']),
      subcategorySnapshot: serializer.fromJson<ActivitySubcategory>(
        json['subcategorySnapshot'],
      ),
      durationSnapshot: serializer.fromJson<DurationSlot>(
        json['durationSnapshot'],
      ),
      theoreticalDeltaSnapshot: serializer.fromJson<int>(
        json['theoreticalDeltaSnapshot'],
      ),
      appliedDeltaSnapshot: serializer.fromJson<int>(
        json['appliedDeltaSnapshot'],
      ),
      defaultTheoreticalDeltaSnapshot: serializer.fromJson<int>(
        json['defaultTheoreticalDeltaSnapshot'],
      ),
      factorSnapshot: serializer.fromJson<double>(json['factorSnapshot']),
      personalizedTheoreticalDeltaSnapshot: serializer.fromJson<int>(
        json['personalizedTheoreticalDeltaSnapshot'],
      ),
      personalizationVersionId: serializer.fromJson<String?>(
        json['personalizationVersionId'],
      ),
      factorRegimeStartedLifeDay: serializer.fromJson<LifeDay?>(
        json['factorRegimeStartedLifeDay'],
      ),
      impactSignSnapshot: serializer.fromJson<ActivityImpactSign>(
        json['impactSignSnapshot'],
      ),
      ruleVersionSnapshot: serializer.fromJson<String>(
        json['ruleVersionSnapshot'],
      ),
      activityUpdatedAtSnapshot: serializer.fromJson<DateTime>(
        json['activityUpdatedAtSnapshot'],
      ),
      direction: serializer.fromJson<ActivityFeedbackDirection>(
        json['direction'],
      ),
      collectionSource: serializer.fromJson<ActivityFeedbackCollectionSource>(
        json['collectionSource'],
      ),
      samplingPolicyVersion: serializer.fromJson<String?>(
        json['samplingPolicyVersion'],
      ),
      sampledAt: serializer.fromJson<DateTime?>(json['sampledAt']),
      sampleId: serializer.fromJson<String?>(json['sampleId']),
      status: serializer.fromJson<ActivityFeedbackStatus>(json['status']),
      invalidationReason: serializer
          .fromJson<ActivityFeedbackInvalidationReason?>(
            json['invalidationReason'],
          ),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityRecordId': serializer.toJson<String>(activityRecordId),
      'lifeDay': serializer.toJson<LifeDay>(lifeDay),
      'subcategorySnapshot': serializer.toJson<ActivitySubcategory>(
        subcategorySnapshot,
      ),
      'durationSnapshot': serializer.toJson<DurationSlot>(durationSnapshot),
      'theoreticalDeltaSnapshot': serializer.toJson<int>(
        theoreticalDeltaSnapshot,
      ),
      'appliedDeltaSnapshot': serializer.toJson<int>(appliedDeltaSnapshot),
      'defaultTheoreticalDeltaSnapshot': serializer.toJson<int>(
        defaultTheoreticalDeltaSnapshot,
      ),
      'factorSnapshot': serializer.toJson<double>(factorSnapshot),
      'personalizedTheoreticalDeltaSnapshot': serializer.toJson<int>(
        personalizedTheoreticalDeltaSnapshot,
      ),
      'personalizationVersionId': serializer.toJson<String?>(
        personalizationVersionId,
      ),
      'factorRegimeStartedLifeDay': serializer.toJson<LifeDay?>(
        factorRegimeStartedLifeDay,
      ),
      'impactSignSnapshot': serializer.toJson<ActivityImpactSign>(
        impactSignSnapshot,
      ),
      'ruleVersionSnapshot': serializer.toJson<String>(ruleVersionSnapshot),
      'activityUpdatedAtSnapshot': serializer.toJson<DateTime>(
        activityUpdatedAtSnapshot,
      ),
      'direction': serializer.toJson<ActivityFeedbackDirection>(direction),
      'collectionSource': serializer.toJson<ActivityFeedbackCollectionSource>(
        collectionSource,
      ),
      'samplingPolicyVersion': serializer.toJson<String?>(
        samplingPolicyVersion,
      ),
      'sampledAt': serializer.toJson<DateTime?>(sampledAt),
      'sampleId': serializer.toJson<String?>(sampleId),
      'status': serializer.toJson<ActivityFeedbackStatus>(status),
      'invalidationReason': serializer
          .toJson<ActivityFeedbackInvalidationReason?>(invalidationReason),
      'observedAt': serializer.toJson<DateTime>(observedAt),
    };
  }

  ActivityFeedbackRow copyWith({
    String? id,
    String? activityRecordId,
    LifeDay? lifeDay,
    ActivitySubcategory? subcategorySnapshot,
    DurationSlot? durationSnapshot,
    int? theoreticalDeltaSnapshot,
    int? appliedDeltaSnapshot,
    int? defaultTheoreticalDeltaSnapshot,
    double? factorSnapshot,
    int? personalizedTheoreticalDeltaSnapshot,
    Value<String?> personalizationVersionId = const Value.absent(),
    Value<LifeDay?> factorRegimeStartedLifeDay = const Value.absent(),
    ActivityImpactSign? impactSignSnapshot,
    String? ruleVersionSnapshot,
    DateTime? activityUpdatedAtSnapshot,
    ActivityFeedbackDirection? direction,
    ActivityFeedbackCollectionSource? collectionSource,
    Value<String?> samplingPolicyVersion = const Value.absent(),
    Value<DateTime?> sampledAt = const Value.absent(),
    Value<String?> sampleId = const Value.absent(),
    ActivityFeedbackStatus? status,
    Value<ActivityFeedbackInvalidationReason?> invalidationReason =
        const Value.absent(),
    DateTime? observedAt,
  }) => ActivityFeedbackRow(
    id: id ?? this.id,
    activityRecordId: activityRecordId ?? this.activityRecordId,
    lifeDay: lifeDay ?? this.lifeDay,
    subcategorySnapshot: subcategorySnapshot ?? this.subcategorySnapshot,
    durationSnapshot: durationSnapshot ?? this.durationSnapshot,
    theoreticalDeltaSnapshot:
        theoreticalDeltaSnapshot ?? this.theoreticalDeltaSnapshot,
    appliedDeltaSnapshot: appliedDeltaSnapshot ?? this.appliedDeltaSnapshot,
    defaultTheoreticalDeltaSnapshot:
        defaultTheoreticalDeltaSnapshot ?? this.defaultTheoreticalDeltaSnapshot,
    factorSnapshot: factorSnapshot ?? this.factorSnapshot,
    personalizedTheoreticalDeltaSnapshot:
        personalizedTheoreticalDeltaSnapshot ??
        this.personalizedTheoreticalDeltaSnapshot,
    personalizationVersionId: personalizationVersionId.present
        ? personalizationVersionId.value
        : this.personalizationVersionId,
    factorRegimeStartedLifeDay: factorRegimeStartedLifeDay.present
        ? factorRegimeStartedLifeDay.value
        : this.factorRegimeStartedLifeDay,
    impactSignSnapshot: impactSignSnapshot ?? this.impactSignSnapshot,
    ruleVersionSnapshot: ruleVersionSnapshot ?? this.ruleVersionSnapshot,
    activityUpdatedAtSnapshot:
        activityUpdatedAtSnapshot ?? this.activityUpdatedAtSnapshot,
    direction: direction ?? this.direction,
    collectionSource: collectionSource ?? this.collectionSource,
    samplingPolicyVersion: samplingPolicyVersion.present
        ? samplingPolicyVersion.value
        : this.samplingPolicyVersion,
    sampledAt: sampledAt.present ? sampledAt.value : this.sampledAt,
    sampleId: sampleId.present ? sampleId.value : this.sampleId,
    status: status ?? this.status,
    invalidationReason: invalidationReason.present
        ? invalidationReason.value
        : this.invalidationReason,
    observedAt: observedAt ?? this.observedAt,
  );
  ActivityFeedbackRow copyWithCompanion(ActivityFeedbackTableCompanion data) {
    return ActivityFeedbackRow(
      id: data.id.present ? data.id.value : this.id,
      activityRecordId: data.activityRecordId.present
          ? data.activityRecordId.value
          : this.activityRecordId,
      lifeDay: data.lifeDay.present ? data.lifeDay.value : this.lifeDay,
      subcategorySnapshot: data.subcategorySnapshot.present
          ? data.subcategorySnapshot.value
          : this.subcategorySnapshot,
      durationSnapshot: data.durationSnapshot.present
          ? data.durationSnapshot.value
          : this.durationSnapshot,
      theoreticalDeltaSnapshot: data.theoreticalDeltaSnapshot.present
          ? data.theoreticalDeltaSnapshot.value
          : this.theoreticalDeltaSnapshot,
      appliedDeltaSnapshot: data.appliedDeltaSnapshot.present
          ? data.appliedDeltaSnapshot.value
          : this.appliedDeltaSnapshot,
      defaultTheoreticalDeltaSnapshot:
          data.defaultTheoreticalDeltaSnapshot.present
          ? data.defaultTheoreticalDeltaSnapshot.value
          : this.defaultTheoreticalDeltaSnapshot,
      factorSnapshot: data.factorSnapshot.present
          ? data.factorSnapshot.value
          : this.factorSnapshot,
      personalizedTheoreticalDeltaSnapshot:
          data.personalizedTheoreticalDeltaSnapshot.present
          ? data.personalizedTheoreticalDeltaSnapshot.value
          : this.personalizedTheoreticalDeltaSnapshot,
      personalizationVersionId: data.personalizationVersionId.present
          ? data.personalizationVersionId.value
          : this.personalizationVersionId,
      factorRegimeStartedLifeDay: data.factorRegimeStartedLifeDay.present
          ? data.factorRegimeStartedLifeDay.value
          : this.factorRegimeStartedLifeDay,
      impactSignSnapshot: data.impactSignSnapshot.present
          ? data.impactSignSnapshot.value
          : this.impactSignSnapshot,
      ruleVersionSnapshot: data.ruleVersionSnapshot.present
          ? data.ruleVersionSnapshot.value
          : this.ruleVersionSnapshot,
      activityUpdatedAtSnapshot: data.activityUpdatedAtSnapshot.present
          ? data.activityUpdatedAtSnapshot.value
          : this.activityUpdatedAtSnapshot,
      direction: data.direction.present ? data.direction.value : this.direction,
      collectionSource: data.collectionSource.present
          ? data.collectionSource.value
          : this.collectionSource,
      samplingPolicyVersion: data.samplingPolicyVersion.present
          ? data.samplingPolicyVersion.value
          : this.samplingPolicyVersion,
      sampledAt: data.sampledAt.present ? data.sampledAt.value : this.sampledAt,
      sampleId: data.sampleId.present ? data.sampleId.value : this.sampleId,
      status: data.status.present ? data.status.value : this.status,
      invalidationReason: data.invalidationReason.present
          ? data.invalidationReason.value
          : this.invalidationReason,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityFeedbackRow(')
          ..write('id: $id, ')
          ..write('activityRecordId: $activityRecordId, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('subcategorySnapshot: $subcategorySnapshot, ')
          ..write('durationSnapshot: $durationSnapshot, ')
          ..write('theoreticalDeltaSnapshot: $theoreticalDeltaSnapshot, ')
          ..write('appliedDeltaSnapshot: $appliedDeltaSnapshot, ')
          ..write(
            'defaultTheoreticalDeltaSnapshot: $defaultTheoreticalDeltaSnapshot, ',
          )
          ..write('factorSnapshot: $factorSnapshot, ')
          ..write(
            'personalizedTheoreticalDeltaSnapshot: $personalizedTheoreticalDeltaSnapshot, ',
          )
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('factorRegimeStartedLifeDay: $factorRegimeStartedLifeDay, ')
          ..write('impactSignSnapshot: $impactSignSnapshot, ')
          ..write('ruleVersionSnapshot: $ruleVersionSnapshot, ')
          ..write('activityUpdatedAtSnapshot: $activityUpdatedAtSnapshot, ')
          ..write('direction: $direction, ')
          ..write('collectionSource: $collectionSource, ')
          ..write('samplingPolicyVersion: $samplingPolicyVersion, ')
          ..write('sampledAt: $sampledAt, ')
          ..write('sampleId: $sampleId, ')
          ..write('status: $status, ')
          ..write('invalidationReason: $invalidationReason, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    activityRecordId,
    lifeDay,
    subcategorySnapshot,
    durationSnapshot,
    theoreticalDeltaSnapshot,
    appliedDeltaSnapshot,
    defaultTheoreticalDeltaSnapshot,
    factorSnapshot,
    personalizedTheoreticalDeltaSnapshot,
    personalizationVersionId,
    factorRegimeStartedLifeDay,
    impactSignSnapshot,
    ruleVersionSnapshot,
    activityUpdatedAtSnapshot,
    direction,
    collectionSource,
    samplingPolicyVersion,
    sampledAt,
    sampleId,
    status,
    invalidationReason,
    observedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityFeedbackRow &&
          other.id == this.id &&
          other.activityRecordId == this.activityRecordId &&
          other.lifeDay == this.lifeDay &&
          other.subcategorySnapshot == this.subcategorySnapshot &&
          other.durationSnapshot == this.durationSnapshot &&
          other.theoreticalDeltaSnapshot == this.theoreticalDeltaSnapshot &&
          other.appliedDeltaSnapshot == this.appliedDeltaSnapshot &&
          other.defaultTheoreticalDeltaSnapshot ==
              this.defaultTheoreticalDeltaSnapshot &&
          other.factorSnapshot == this.factorSnapshot &&
          other.personalizedTheoreticalDeltaSnapshot ==
              this.personalizedTheoreticalDeltaSnapshot &&
          other.personalizationVersionId == this.personalizationVersionId &&
          other.factorRegimeStartedLifeDay == this.factorRegimeStartedLifeDay &&
          other.impactSignSnapshot == this.impactSignSnapshot &&
          other.ruleVersionSnapshot == this.ruleVersionSnapshot &&
          other.activityUpdatedAtSnapshot == this.activityUpdatedAtSnapshot &&
          other.direction == this.direction &&
          other.collectionSource == this.collectionSource &&
          other.samplingPolicyVersion == this.samplingPolicyVersion &&
          other.sampledAt == this.sampledAt &&
          other.sampleId == this.sampleId &&
          other.status == this.status &&
          other.invalidationReason == this.invalidationReason &&
          other.observedAt == this.observedAt);
}

class ActivityFeedbackTableCompanion
    extends UpdateCompanion<ActivityFeedbackRow> {
  final Value<String> id;
  final Value<String> activityRecordId;
  final Value<LifeDay> lifeDay;
  final Value<ActivitySubcategory> subcategorySnapshot;
  final Value<DurationSlot> durationSnapshot;
  final Value<int> theoreticalDeltaSnapshot;
  final Value<int> appliedDeltaSnapshot;
  final Value<int> defaultTheoreticalDeltaSnapshot;
  final Value<double> factorSnapshot;
  final Value<int> personalizedTheoreticalDeltaSnapshot;
  final Value<String?> personalizationVersionId;
  final Value<LifeDay?> factorRegimeStartedLifeDay;
  final Value<ActivityImpactSign> impactSignSnapshot;
  final Value<String> ruleVersionSnapshot;
  final Value<DateTime> activityUpdatedAtSnapshot;
  final Value<ActivityFeedbackDirection> direction;
  final Value<ActivityFeedbackCollectionSource> collectionSource;
  final Value<String?> samplingPolicyVersion;
  final Value<DateTime?> sampledAt;
  final Value<String?> sampleId;
  final Value<ActivityFeedbackStatus> status;
  final Value<ActivityFeedbackInvalidationReason?> invalidationReason;
  final Value<DateTime> observedAt;
  final Value<int> rowid;
  const ActivityFeedbackTableCompanion({
    this.id = const Value.absent(),
    this.activityRecordId = const Value.absent(),
    this.lifeDay = const Value.absent(),
    this.subcategorySnapshot = const Value.absent(),
    this.durationSnapshot = const Value.absent(),
    this.theoreticalDeltaSnapshot = const Value.absent(),
    this.appliedDeltaSnapshot = const Value.absent(),
    this.defaultTheoreticalDeltaSnapshot = const Value.absent(),
    this.factorSnapshot = const Value.absent(),
    this.personalizedTheoreticalDeltaSnapshot = const Value.absent(),
    this.personalizationVersionId = const Value.absent(),
    this.factorRegimeStartedLifeDay = const Value.absent(),
    this.impactSignSnapshot = const Value.absent(),
    this.ruleVersionSnapshot = const Value.absent(),
    this.activityUpdatedAtSnapshot = const Value.absent(),
    this.direction = const Value.absent(),
    this.collectionSource = const Value.absent(),
    this.samplingPolicyVersion = const Value.absent(),
    this.sampledAt = const Value.absent(),
    this.sampleId = const Value.absent(),
    this.status = const Value.absent(),
    this.invalidationReason = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityFeedbackTableCompanion.insert({
    required String id,
    required String activityRecordId,
    required LifeDay lifeDay,
    required ActivitySubcategory subcategorySnapshot,
    required DurationSlot durationSnapshot,
    required int theoreticalDeltaSnapshot,
    required int appliedDeltaSnapshot,
    this.defaultTheoreticalDeltaSnapshot = const Value.absent(),
    this.factorSnapshot = const Value.absent(),
    this.personalizedTheoreticalDeltaSnapshot = const Value.absent(),
    this.personalizationVersionId = const Value.absent(),
    this.factorRegimeStartedLifeDay = const Value.absent(),
    required ActivityImpactSign impactSignSnapshot,
    required String ruleVersionSnapshot,
    required DateTime activityUpdatedAtSnapshot,
    required ActivityFeedbackDirection direction,
    this.collectionSource = const Value.absent(),
    this.samplingPolicyVersion = const Value.absent(),
    this.sampledAt = const Value.absent(),
    this.sampleId = const Value.absent(),
    required ActivityFeedbackStatus status,
    this.invalidationReason = const Value.absent(),
    required DateTime observedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activityRecordId = Value(activityRecordId),
       lifeDay = Value(lifeDay),
       subcategorySnapshot = Value(subcategorySnapshot),
       durationSnapshot = Value(durationSnapshot),
       theoreticalDeltaSnapshot = Value(theoreticalDeltaSnapshot),
       appliedDeltaSnapshot = Value(appliedDeltaSnapshot),
       impactSignSnapshot = Value(impactSignSnapshot),
       ruleVersionSnapshot = Value(ruleVersionSnapshot),
       activityUpdatedAtSnapshot = Value(activityUpdatedAtSnapshot),
       direction = Value(direction),
       status = Value(status),
       observedAt = Value(observedAt);
  static Insertable<ActivityFeedbackRow> custom({
    Expression<String>? id,
    Expression<String>? activityRecordId,
    Expression<String>? lifeDay,
    Expression<String>? subcategorySnapshot,
    Expression<int>? durationSnapshot,
    Expression<int>? theoreticalDeltaSnapshot,
    Expression<int>? appliedDeltaSnapshot,
    Expression<int>? defaultTheoreticalDeltaSnapshot,
    Expression<double>? factorSnapshot,
    Expression<int>? personalizedTheoreticalDeltaSnapshot,
    Expression<String>? personalizationVersionId,
    Expression<String>? factorRegimeStartedLifeDay,
    Expression<String>? impactSignSnapshot,
    Expression<String>? ruleVersionSnapshot,
    Expression<DateTime>? activityUpdatedAtSnapshot,
    Expression<String>? direction,
    Expression<String>? collectionSource,
    Expression<String>? samplingPolicyVersion,
    Expression<DateTime>? sampledAt,
    Expression<String>? sampleId,
    Expression<String>? status,
    Expression<String>? invalidationReason,
    Expression<DateTime>? observedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityRecordId != null) 'activity_record_id': activityRecordId,
      if (lifeDay != null) 'life_day': lifeDay,
      if (subcategorySnapshot != null)
        'subcategory_snapshot': subcategorySnapshot,
      if (durationSnapshot != null)
        'duration_minutes_snapshot': durationSnapshot,
      if (theoreticalDeltaSnapshot != null)
        'theoretical_delta_snapshot': theoreticalDeltaSnapshot,
      if (appliedDeltaSnapshot != null)
        'applied_delta_snapshot': appliedDeltaSnapshot,
      if (defaultTheoreticalDeltaSnapshot != null)
        'default_theoretical_delta_snapshot': defaultTheoreticalDeltaSnapshot,
      if (factorSnapshot != null) 'factor_snapshot': factorSnapshot,
      if (personalizedTheoreticalDeltaSnapshot != null)
        'personalized_theoretical_delta_snapshot':
            personalizedTheoreticalDeltaSnapshot,
      if (personalizationVersionId != null)
        'personalization_version_id': personalizationVersionId,
      if (factorRegimeStartedLifeDay != null)
        'factor_regime_started_life_day': factorRegimeStartedLifeDay,
      if (impactSignSnapshot != null)
        'impact_sign_snapshot': impactSignSnapshot,
      if (ruleVersionSnapshot != null)
        'rule_version_snapshot': ruleVersionSnapshot,
      if (activityUpdatedAtSnapshot != null)
        'activity_updated_at_snapshot': activityUpdatedAtSnapshot,
      if (direction != null) 'direction': direction,
      if (collectionSource != null) 'collection_source': collectionSource,
      if (samplingPolicyVersion != null)
        'sampling_policy_version': samplingPolicyVersion,
      if (sampledAt != null) 'sampled_at': sampledAt,
      if (sampleId != null) 'sample_id': sampleId,
      if (status != null) 'status': status,
      if (invalidationReason != null) 'invalidation_reason': invalidationReason,
      if (observedAt != null) 'observed_at': observedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityFeedbackTableCompanion copyWith({
    Value<String>? id,
    Value<String>? activityRecordId,
    Value<LifeDay>? lifeDay,
    Value<ActivitySubcategory>? subcategorySnapshot,
    Value<DurationSlot>? durationSnapshot,
    Value<int>? theoreticalDeltaSnapshot,
    Value<int>? appliedDeltaSnapshot,
    Value<int>? defaultTheoreticalDeltaSnapshot,
    Value<double>? factorSnapshot,
    Value<int>? personalizedTheoreticalDeltaSnapshot,
    Value<String?>? personalizationVersionId,
    Value<LifeDay?>? factorRegimeStartedLifeDay,
    Value<ActivityImpactSign>? impactSignSnapshot,
    Value<String>? ruleVersionSnapshot,
    Value<DateTime>? activityUpdatedAtSnapshot,
    Value<ActivityFeedbackDirection>? direction,
    Value<ActivityFeedbackCollectionSource>? collectionSource,
    Value<String?>? samplingPolicyVersion,
    Value<DateTime?>? sampledAt,
    Value<String?>? sampleId,
    Value<ActivityFeedbackStatus>? status,
    Value<ActivityFeedbackInvalidationReason?>? invalidationReason,
    Value<DateTime>? observedAt,
    Value<int>? rowid,
  }) {
    return ActivityFeedbackTableCompanion(
      id: id ?? this.id,
      activityRecordId: activityRecordId ?? this.activityRecordId,
      lifeDay: lifeDay ?? this.lifeDay,
      subcategorySnapshot: subcategorySnapshot ?? this.subcategorySnapshot,
      durationSnapshot: durationSnapshot ?? this.durationSnapshot,
      theoreticalDeltaSnapshot:
          theoreticalDeltaSnapshot ?? this.theoreticalDeltaSnapshot,
      appliedDeltaSnapshot: appliedDeltaSnapshot ?? this.appliedDeltaSnapshot,
      defaultTheoreticalDeltaSnapshot:
          defaultTheoreticalDeltaSnapshot ??
          this.defaultTheoreticalDeltaSnapshot,
      factorSnapshot: factorSnapshot ?? this.factorSnapshot,
      personalizedTheoreticalDeltaSnapshot:
          personalizedTheoreticalDeltaSnapshot ??
          this.personalizedTheoreticalDeltaSnapshot,
      personalizationVersionId:
          personalizationVersionId ?? this.personalizationVersionId,
      factorRegimeStartedLifeDay:
          factorRegimeStartedLifeDay ?? this.factorRegimeStartedLifeDay,
      impactSignSnapshot: impactSignSnapshot ?? this.impactSignSnapshot,
      ruleVersionSnapshot: ruleVersionSnapshot ?? this.ruleVersionSnapshot,
      activityUpdatedAtSnapshot:
          activityUpdatedAtSnapshot ?? this.activityUpdatedAtSnapshot,
      direction: direction ?? this.direction,
      collectionSource: collectionSource ?? this.collectionSource,
      samplingPolicyVersion:
          samplingPolicyVersion ?? this.samplingPolicyVersion,
      sampledAt: sampledAt ?? this.sampledAt,
      sampleId: sampleId ?? this.sampleId,
      status: status ?? this.status,
      invalidationReason: invalidationReason ?? this.invalidationReason,
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
    if (activityRecordId.present) {
      map['activity_record_id'] = Variable<String>(activityRecordId.value);
    }
    if (lifeDay.present) {
      map['life_day'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterlifeDay.toSql(lifeDay.value),
      );
    }
    if (subcategorySnapshot.present) {
      map['subcategory_snapshot'] = Variable<String>(
        $ActivityFeedbackTableTable.$convertersubcategorySnapshot.toSql(
          subcategorySnapshot.value,
        ),
      );
    }
    if (durationSnapshot.present) {
      map['duration_minutes_snapshot'] = Variable<int>(
        $ActivityFeedbackTableTable.$converterdurationSnapshot.toSql(
          durationSnapshot.value,
        ),
      );
    }
    if (theoreticalDeltaSnapshot.present) {
      map['theoretical_delta_snapshot'] = Variable<int>(
        theoreticalDeltaSnapshot.value,
      );
    }
    if (appliedDeltaSnapshot.present) {
      map['applied_delta_snapshot'] = Variable<int>(appliedDeltaSnapshot.value);
    }
    if (defaultTheoreticalDeltaSnapshot.present) {
      map['default_theoretical_delta_snapshot'] = Variable<int>(
        defaultTheoreticalDeltaSnapshot.value,
      );
    }
    if (factorSnapshot.present) {
      map['factor_snapshot'] = Variable<double>(factorSnapshot.value);
    }
    if (personalizedTheoreticalDeltaSnapshot.present) {
      map['personalized_theoretical_delta_snapshot'] = Variable<int>(
        personalizedTheoreticalDeltaSnapshot.value,
      );
    }
    if (personalizationVersionId.present) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId.value,
      );
    }
    if (factorRegimeStartedLifeDay.present) {
      map['factor_regime_started_life_day'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterfactorRegimeStartedLifeDayn.toSql(
          factorRegimeStartedLifeDay.value,
        ),
      );
    }
    if (impactSignSnapshot.present) {
      map['impact_sign_snapshot'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterimpactSignSnapshot.toSql(
          impactSignSnapshot.value,
        ),
      );
    }
    if (ruleVersionSnapshot.present) {
      map['rule_version_snapshot'] = Variable<String>(
        ruleVersionSnapshot.value,
      );
    }
    if (activityUpdatedAtSnapshot.present) {
      map['activity_updated_at_snapshot'] = Variable<DateTime>(
        activityUpdatedAtSnapshot.value,
      );
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterdirection.toSql(direction.value),
      );
    }
    if (collectionSource.present) {
      map['collection_source'] = Variable<String>(
        $ActivityFeedbackTableTable.$convertercollectionSource.toSql(
          collectionSource.value,
        ),
      );
    }
    if (samplingPolicyVersion.present) {
      map['sampling_policy_version'] = Variable<String>(
        samplingPolicyVersion.value,
      );
    }
    if (sampledAt.present) {
      map['sampled_at'] = Variable<DateTime>(sampledAt.value);
    }
    if (sampleId.present) {
      map['sample_id'] = Variable<String>(sampleId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (invalidationReason.present) {
      map['invalidation_reason'] = Variable<String>(
        $ActivityFeedbackTableTable.$converterinvalidationReasonn.toSql(
          invalidationReason.value,
        ),
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
    return (StringBuffer('ActivityFeedbackTableCompanion(')
          ..write('id: $id, ')
          ..write('activityRecordId: $activityRecordId, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('subcategorySnapshot: $subcategorySnapshot, ')
          ..write('durationSnapshot: $durationSnapshot, ')
          ..write('theoreticalDeltaSnapshot: $theoreticalDeltaSnapshot, ')
          ..write('appliedDeltaSnapshot: $appliedDeltaSnapshot, ')
          ..write(
            'defaultTheoreticalDeltaSnapshot: $defaultTheoreticalDeltaSnapshot, ',
          )
          ..write('factorSnapshot: $factorSnapshot, ')
          ..write(
            'personalizedTheoreticalDeltaSnapshot: $personalizedTheoreticalDeltaSnapshot, ',
          )
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('factorRegimeStartedLifeDay: $factorRegimeStartedLifeDay, ')
          ..write('impactSignSnapshot: $impactSignSnapshot, ')
          ..write('ruleVersionSnapshot: $ruleVersionSnapshot, ')
          ..write('activityUpdatedAtSnapshot: $activityUpdatedAtSnapshot, ')
          ..write('direction: $direction, ')
          ..write('collectionSource: $collectionSource, ')
          ..write('samplingPolicyVersion: $samplingPolicyVersion, ')
          ..write('sampledAt: $sampledAt, ')
          ..write('sampleId: $sampleId, ')
          ..write('status: $status, ')
          ..write('invalidationReason: $invalidationReason, ')
          ..write('observedAt: $observedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningRunsTableTable extends LearningRunsTable
    with TableInfo<$LearningRunsTableTable, LearningRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningRunsTableTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<LearningParameterFamily, String>
  parameterFamily =
      GeneratedColumn<String>(
        'parameter_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LearningParameterFamily>(
        $LearningRunsTableTable.$converterparameterFamily,
      );
  static const VerificationMeta _sourceModelIdentityMeta =
      const VerificationMeta('sourceModelIdentity');
  @override
  late final GeneratedColumn<String> sourceModelIdentity =
      GeneratedColumn<String>(
        'source_model_identity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourcePersonalizationVersionIdMeta =
      const VerificationMeta('sourcePersonalizationVersionId');
  @override
  late final GeneratedColumn<String> sourcePersonalizationVersionId =
      GeneratedColumn<String>(
        'source_personalization_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LearningRunStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<LearningRunStatus>($LearningRunsTableTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<LearningRunResult?, String>
  result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LearningRunResult?>(
        $LearningRunsTableTable.$converterresultn,
      );
  static const VerificationMeta _evidenceSnapshotJsonMeta =
      const VerificationMeta('evidenceSnapshotJson');
  @override
  late final GeneratedColumn<String> evidenceSnapshotJson =
      GeneratedColumn<String>(
        'evidence_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _evidenceHashMeta = const VerificationMeta(
    'evidenceHash',
  );
  @override
  late final GeneratedColumn<String> evidenceHash = GeneratedColumn<String>(
    'evidence_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceHashVersionMeta =
      const VerificationMeta('evidenceHashVersion');
  @override
  late final GeneratedColumn<String> evidenceHashVersion =
      GeneratedColumn<String>(
        'evidence_hash_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _algorithmVersionMeta = const VerificationMeta(
    'algorithmVersion',
  );
  @override
  late final GeneratedColumn<String> algorithmVersion = GeneratedColumn<String>(
    'algorithm_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configVersionMeta = const VerificationMeta(
    'configVersion',
  );
  @override
  late final GeneratedColumn<String> configVersion = GeneratedColumn<String>(
    'config_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentValuesJsonMeta = const VerificationMeta(
    'currentValuesJson',
  );
  @override
  late final GeneratedColumn<String> currentValuesJson =
      GeneratedColumn<String>(
        'current_values_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _candidateValuesJsonMeta =
      const VerificationMeta('candidateValuesJson');
  @override
  late final GeneratedColumn<String> candidateValuesJson =
      GeneratedColumn<String>(
        'candidate_values_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reasonCodesJsonMeta = const VerificationMeta(
    'reasonCodesJson',
  );
  @override
  late final GeneratedColumn<String> reasonCodesJson = GeneratedColumn<String>(
    'reason_codes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggeredAtMeta = const VerificationMeta(
    'triggeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> triggeredAt = GeneratedColumn<DateTime>(
    'triggered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parameterFamily,
    sourceModelIdentity,
    sourcePersonalizationVersionId,
    status,
    result,
    evidenceSnapshotJson,
    evidenceHash,
    evidenceHashVersion,
    algorithmVersion,
    configVersion,
    currentValuesJson,
    candidateValuesJson,
    reasonCodesJson,
    triggeredAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_model_identity')) {
      context.handle(
        _sourceModelIdentityMeta,
        sourceModelIdentity.isAcceptableOrUnknown(
          data['source_model_identity']!,
          _sourceModelIdentityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceModelIdentityMeta);
    }
    if (data.containsKey('source_personalization_version_id')) {
      context.handle(
        _sourcePersonalizationVersionIdMeta,
        sourcePersonalizationVersionId.isAcceptableOrUnknown(
          data['source_personalization_version_id']!,
          _sourcePersonalizationVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('evidence_snapshot_json')) {
      context.handle(
        _evidenceSnapshotJsonMeta,
        evidenceSnapshotJson.isAcceptableOrUnknown(
          data['evidence_snapshot_json']!,
          _evidenceSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceSnapshotJsonMeta);
    }
    if (data.containsKey('evidence_hash')) {
      context.handle(
        _evidenceHashMeta,
        evidenceHash.isAcceptableOrUnknown(
          data['evidence_hash']!,
          _evidenceHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceHashMeta);
    }
    if (data.containsKey('evidence_hash_version')) {
      context.handle(
        _evidenceHashVersionMeta,
        evidenceHashVersion.isAcceptableOrUnknown(
          data['evidence_hash_version']!,
          _evidenceHashVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceHashVersionMeta);
    }
    if (data.containsKey('algorithm_version')) {
      context.handle(
        _algorithmVersionMeta,
        algorithmVersion.isAcceptableOrUnknown(
          data['algorithm_version']!,
          _algorithmVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_algorithmVersionMeta);
    }
    if (data.containsKey('config_version')) {
      context.handle(
        _configVersionMeta,
        configVersion.isAcceptableOrUnknown(
          data['config_version']!,
          _configVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configVersionMeta);
    }
    if (data.containsKey('current_values_json')) {
      context.handle(
        _currentValuesJsonMeta,
        currentValuesJson.isAcceptableOrUnknown(
          data['current_values_json']!,
          _currentValuesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentValuesJsonMeta);
    }
    if (data.containsKey('candidate_values_json')) {
      context.handle(
        _candidateValuesJsonMeta,
        candidateValuesJson.isAcceptableOrUnknown(
          data['candidate_values_json']!,
          _candidateValuesJsonMeta,
        ),
      );
    }
    if (data.containsKey('reason_codes_json')) {
      context.handle(
        _reasonCodesJsonMeta,
        reasonCodesJson.isAcceptableOrUnknown(
          data['reason_codes_json']!,
          _reasonCodesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reasonCodesJsonMeta);
    }
    if (data.containsKey('triggered_at')) {
      context.handle(
        _triggeredAtMeta,
        triggeredAt.isAcceptableOrUnknown(
          data['triggered_at']!,
          _triggeredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggeredAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parameterFamily: $LearningRunsTableTable.$converterparameterFamily
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}parameter_family'],
            )!,
          ),
      sourceModelIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_model_identity'],
      )!,
      sourcePersonalizationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_personalization_version_id'],
      ),
      status: $LearningRunsTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      result: $LearningRunsTableTable.$converterresultn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        ),
      ),
      evidenceSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_snapshot_json'],
      )!,
      evidenceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_hash'],
      )!,
      evidenceHashVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_hash_version'],
      )!,
      algorithmVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}algorithm_version'],
      )!,
      configVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_version'],
      )!,
      currentValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_values_json'],
      )!,
      candidateValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_values_json'],
      ),
      reasonCodesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_codes_json'],
      )!,
      triggeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}triggered_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $LearningRunsTableTable createAlias(String alias) {
    return $LearningRunsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LearningParameterFamily, String>
  $converterparameterFamily = const LearningParameterFamilyConverter();
  static TypeConverter<LearningRunStatus, String> $converterstatus =
      const LearningRunStatusConverter();
  static TypeConverter<LearningRunResult, String> $converterresult =
      const LearningRunResultConverter();
  static TypeConverter<LearningRunResult?, String?> $converterresultn =
      NullAwareTypeConverter.wrap($converterresult);
}

class LearningRunRow extends DataClass implements Insertable<LearningRunRow> {
  final String id;
  final LearningParameterFamily parameterFamily;
  final String sourceModelIdentity;
  final String? sourcePersonalizationVersionId;
  final LearningRunStatus status;
  final LearningRunResult? result;
  final String evidenceSnapshotJson;
  final String evidenceHash;
  final String evidenceHashVersion;
  final String algorithmVersion;
  final String configVersion;
  final String currentValuesJson;
  final String? candidateValuesJson;
  final String reasonCodesJson;
  final DateTime triggeredAt;
  final DateTime? completedAt;
  const LearningRunRow({
    required this.id,
    required this.parameterFamily,
    required this.sourceModelIdentity,
    this.sourcePersonalizationVersionId,
    required this.status,
    this.result,
    required this.evidenceSnapshotJson,
    required this.evidenceHash,
    required this.evidenceHashVersion,
    required this.algorithmVersion,
    required this.configVersion,
    required this.currentValuesJson,
    this.candidateValuesJson,
    required this.reasonCodesJson,
    required this.triggeredAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['parameter_family'] = Variable<String>(
        $LearningRunsTableTable.$converterparameterFamily.toSql(
          parameterFamily,
        ),
      );
    }
    map['source_model_identity'] = Variable<String>(sourceModelIdentity);
    if (!nullToAbsent || sourcePersonalizationVersionId != null) {
      map['source_personalization_version_id'] = Variable<String>(
        sourcePersonalizationVersionId,
      );
    }
    {
      map['status'] = Variable<String>(
        $LearningRunsTableTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(
        $LearningRunsTableTable.$converterresultn.toSql(result),
      );
    }
    map['evidence_snapshot_json'] = Variable<String>(evidenceSnapshotJson);
    map['evidence_hash'] = Variable<String>(evidenceHash);
    map['evidence_hash_version'] = Variable<String>(evidenceHashVersion);
    map['algorithm_version'] = Variable<String>(algorithmVersion);
    map['config_version'] = Variable<String>(configVersion);
    map['current_values_json'] = Variable<String>(currentValuesJson);
    if (!nullToAbsent || candidateValuesJson != null) {
      map['candidate_values_json'] = Variable<String>(candidateValuesJson);
    }
    map['reason_codes_json'] = Variable<String>(reasonCodesJson);
    map['triggered_at'] = Variable<DateTime>(triggeredAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  LearningRunsTableCompanion toCompanion(bool nullToAbsent) {
    return LearningRunsTableCompanion(
      id: Value(id),
      parameterFamily: Value(parameterFamily),
      sourceModelIdentity: Value(sourceModelIdentity),
      sourcePersonalizationVersionId:
          sourcePersonalizationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePersonalizationVersionId),
      status: Value(status),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
      evidenceSnapshotJson: Value(evidenceSnapshotJson),
      evidenceHash: Value(evidenceHash),
      evidenceHashVersion: Value(evidenceHashVersion),
      algorithmVersion: Value(algorithmVersion),
      configVersion: Value(configVersion),
      currentValuesJson: Value(currentValuesJson),
      candidateValuesJson: candidateValuesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(candidateValuesJson),
      reasonCodesJson: Value(reasonCodesJson),
      triggeredAt: Value(triggeredAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory LearningRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningRunRow(
      id: serializer.fromJson<String>(json['id']),
      parameterFamily: serializer.fromJson<LearningParameterFamily>(
        json['parameterFamily'],
      ),
      sourceModelIdentity: serializer.fromJson<String>(
        json['sourceModelIdentity'],
      ),
      sourcePersonalizationVersionId: serializer.fromJson<String?>(
        json['sourcePersonalizationVersionId'],
      ),
      status: serializer.fromJson<LearningRunStatus>(json['status']),
      result: serializer.fromJson<LearningRunResult?>(json['result']),
      evidenceSnapshotJson: serializer.fromJson<String>(
        json['evidenceSnapshotJson'],
      ),
      evidenceHash: serializer.fromJson<String>(json['evidenceHash']),
      evidenceHashVersion: serializer.fromJson<String>(
        json['evidenceHashVersion'],
      ),
      algorithmVersion: serializer.fromJson<String>(json['algorithmVersion']),
      configVersion: serializer.fromJson<String>(json['configVersion']),
      currentValuesJson: serializer.fromJson<String>(json['currentValuesJson']),
      candidateValuesJson: serializer.fromJson<String?>(
        json['candidateValuesJson'],
      ),
      reasonCodesJson: serializer.fromJson<String>(json['reasonCodesJson']),
      triggeredAt: serializer.fromJson<DateTime>(json['triggeredAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parameterFamily': serializer.toJson<LearningParameterFamily>(
        parameterFamily,
      ),
      'sourceModelIdentity': serializer.toJson<String>(sourceModelIdentity),
      'sourcePersonalizationVersionId': serializer.toJson<String?>(
        sourcePersonalizationVersionId,
      ),
      'status': serializer.toJson<LearningRunStatus>(status),
      'result': serializer.toJson<LearningRunResult?>(result),
      'evidenceSnapshotJson': serializer.toJson<String>(evidenceSnapshotJson),
      'evidenceHash': serializer.toJson<String>(evidenceHash),
      'evidenceHashVersion': serializer.toJson<String>(evidenceHashVersion),
      'algorithmVersion': serializer.toJson<String>(algorithmVersion),
      'configVersion': serializer.toJson<String>(configVersion),
      'currentValuesJson': serializer.toJson<String>(currentValuesJson),
      'candidateValuesJson': serializer.toJson<String?>(candidateValuesJson),
      'reasonCodesJson': serializer.toJson<String>(reasonCodesJson),
      'triggeredAt': serializer.toJson<DateTime>(triggeredAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  LearningRunRow copyWith({
    String? id,
    LearningParameterFamily? parameterFamily,
    String? sourceModelIdentity,
    Value<String?> sourcePersonalizationVersionId = const Value.absent(),
    LearningRunStatus? status,
    Value<LearningRunResult?> result = const Value.absent(),
    String? evidenceSnapshotJson,
    String? evidenceHash,
    String? evidenceHashVersion,
    String? algorithmVersion,
    String? configVersion,
    String? currentValuesJson,
    Value<String?> candidateValuesJson = const Value.absent(),
    String? reasonCodesJson,
    DateTime? triggeredAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => LearningRunRow(
    id: id ?? this.id,
    parameterFamily: parameterFamily ?? this.parameterFamily,
    sourceModelIdentity: sourceModelIdentity ?? this.sourceModelIdentity,
    sourcePersonalizationVersionId: sourcePersonalizationVersionId.present
        ? sourcePersonalizationVersionId.value
        : this.sourcePersonalizationVersionId,
    status: status ?? this.status,
    result: result.present ? result.value : this.result,
    evidenceSnapshotJson: evidenceSnapshotJson ?? this.evidenceSnapshotJson,
    evidenceHash: evidenceHash ?? this.evidenceHash,
    evidenceHashVersion: evidenceHashVersion ?? this.evidenceHashVersion,
    algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    configVersion: configVersion ?? this.configVersion,
    currentValuesJson: currentValuesJson ?? this.currentValuesJson,
    candidateValuesJson: candidateValuesJson.present
        ? candidateValuesJson.value
        : this.candidateValuesJson,
    reasonCodesJson: reasonCodesJson ?? this.reasonCodesJson,
    triggeredAt: triggeredAt ?? this.triggeredAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  LearningRunRow copyWithCompanion(LearningRunsTableCompanion data) {
    return LearningRunRow(
      id: data.id.present ? data.id.value : this.id,
      parameterFamily: data.parameterFamily.present
          ? data.parameterFamily.value
          : this.parameterFamily,
      sourceModelIdentity: data.sourceModelIdentity.present
          ? data.sourceModelIdentity.value
          : this.sourceModelIdentity,
      sourcePersonalizationVersionId:
          data.sourcePersonalizationVersionId.present
          ? data.sourcePersonalizationVersionId.value
          : this.sourcePersonalizationVersionId,
      status: data.status.present ? data.status.value : this.status,
      result: data.result.present ? data.result.value : this.result,
      evidenceSnapshotJson: data.evidenceSnapshotJson.present
          ? data.evidenceSnapshotJson.value
          : this.evidenceSnapshotJson,
      evidenceHash: data.evidenceHash.present
          ? data.evidenceHash.value
          : this.evidenceHash,
      evidenceHashVersion: data.evidenceHashVersion.present
          ? data.evidenceHashVersion.value
          : this.evidenceHashVersion,
      algorithmVersion: data.algorithmVersion.present
          ? data.algorithmVersion.value
          : this.algorithmVersion,
      configVersion: data.configVersion.present
          ? data.configVersion.value
          : this.configVersion,
      currentValuesJson: data.currentValuesJson.present
          ? data.currentValuesJson.value
          : this.currentValuesJson,
      candidateValuesJson: data.candidateValuesJson.present
          ? data.candidateValuesJson.value
          : this.candidateValuesJson,
      reasonCodesJson: data.reasonCodesJson.present
          ? data.reasonCodesJson.value
          : this.reasonCodesJson,
      triggeredAt: data.triggeredAt.present
          ? data.triggeredAt.value
          : this.triggeredAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningRunRow(')
          ..write('id: $id, ')
          ..write('parameterFamily: $parameterFamily, ')
          ..write('sourceModelIdentity: $sourceModelIdentity, ')
          ..write(
            'sourcePersonalizationVersionId: $sourcePersonalizationVersionId, ',
          )
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('evidenceSnapshotJson: $evidenceSnapshotJson, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('evidenceHashVersion: $evidenceHashVersion, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('configVersion: $configVersion, ')
          ..write('currentValuesJson: $currentValuesJson, ')
          ..write('candidateValuesJson: $candidateValuesJson, ')
          ..write('reasonCodesJson: $reasonCodesJson, ')
          ..write('triggeredAt: $triggeredAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parameterFamily,
    sourceModelIdentity,
    sourcePersonalizationVersionId,
    status,
    result,
    evidenceSnapshotJson,
    evidenceHash,
    evidenceHashVersion,
    algorithmVersion,
    configVersion,
    currentValuesJson,
    candidateValuesJson,
    reasonCodesJson,
    triggeredAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningRunRow &&
          other.id == this.id &&
          other.parameterFamily == this.parameterFamily &&
          other.sourceModelIdentity == this.sourceModelIdentity &&
          other.sourcePersonalizationVersionId ==
              this.sourcePersonalizationVersionId &&
          other.status == this.status &&
          other.result == this.result &&
          other.evidenceSnapshotJson == this.evidenceSnapshotJson &&
          other.evidenceHash == this.evidenceHash &&
          other.evidenceHashVersion == this.evidenceHashVersion &&
          other.algorithmVersion == this.algorithmVersion &&
          other.configVersion == this.configVersion &&
          other.currentValuesJson == this.currentValuesJson &&
          other.candidateValuesJson == this.candidateValuesJson &&
          other.reasonCodesJson == this.reasonCodesJson &&
          other.triggeredAt == this.triggeredAt &&
          other.completedAt == this.completedAt);
}

class LearningRunsTableCompanion extends UpdateCompanion<LearningRunRow> {
  final Value<String> id;
  final Value<LearningParameterFamily> parameterFamily;
  final Value<String> sourceModelIdentity;
  final Value<String?> sourcePersonalizationVersionId;
  final Value<LearningRunStatus> status;
  final Value<LearningRunResult?> result;
  final Value<String> evidenceSnapshotJson;
  final Value<String> evidenceHash;
  final Value<String> evidenceHashVersion;
  final Value<String> algorithmVersion;
  final Value<String> configVersion;
  final Value<String> currentValuesJson;
  final Value<String?> candidateValuesJson;
  final Value<String> reasonCodesJson;
  final Value<DateTime> triggeredAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const LearningRunsTableCompanion({
    this.id = const Value.absent(),
    this.parameterFamily = const Value.absent(),
    this.sourceModelIdentity = const Value.absent(),
    this.sourcePersonalizationVersionId = const Value.absent(),
    this.status = const Value.absent(),
    this.result = const Value.absent(),
    this.evidenceSnapshotJson = const Value.absent(),
    this.evidenceHash = const Value.absent(),
    this.evidenceHashVersion = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    this.configVersion = const Value.absent(),
    this.currentValuesJson = const Value.absent(),
    this.candidateValuesJson = const Value.absent(),
    this.reasonCodesJson = const Value.absent(),
    this.triggeredAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningRunsTableCompanion.insert({
    required String id,
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    this.sourcePersonalizationVersionId = const Value.absent(),
    required LearningRunStatus status,
    this.result = const Value.absent(),
    required String evidenceSnapshotJson,
    required String evidenceHash,
    required String evidenceHashVersion,
    required String algorithmVersion,
    required String configVersion,
    required String currentValuesJson,
    this.candidateValuesJson = const Value.absent(),
    required String reasonCodesJson,
    required DateTime triggeredAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       parameterFamily = Value(parameterFamily),
       sourceModelIdentity = Value(sourceModelIdentity),
       status = Value(status),
       evidenceSnapshotJson = Value(evidenceSnapshotJson),
       evidenceHash = Value(evidenceHash),
       evidenceHashVersion = Value(evidenceHashVersion),
       algorithmVersion = Value(algorithmVersion),
       configVersion = Value(configVersion),
       currentValuesJson = Value(currentValuesJson),
       reasonCodesJson = Value(reasonCodesJson),
       triggeredAt = Value(triggeredAt);
  static Insertable<LearningRunRow> custom({
    Expression<String>? id,
    Expression<String>? parameterFamily,
    Expression<String>? sourceModelIdentity,
    Expression<String>? sourcePersonalizationVersionId,
    Expression<String>? status,
    Expression<String>? result,
    Expression<String>? evidenceSnapshotJson,
    Expression<String>? evidenceHash,
    Expression<String>? evidenceHashVersion,
    Expression<String>? algorithmVersion,
    Expression<String>? configVersion,
    Expression<String>? currentValuesJson,
    Expression<String>? candidateValuesJson,
    Expression<String>? reasonCodesJson,
    Expression<DateTime>? triggeredAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parameterFamily != null) 'parameter_family': parameterFamily,
      if (sourceModelIdentity != null)
        'source_model_identity': sourceModelIdentity,
      if (sourcePersonalizationVersionId != null)
        'source_personalization_version_id': sourcePersonalizationVersionId,
      if (status != null) 'status': status,
      if (result != null) 'result': result,
      if (evidenceSnapshotJson != null)
        'evidence_snapshot_json': evidenceSnapshotJson,
      if (evidenceHash != null) 'evidence_hash': evidenceHash,
      if (evidenceHashVersion != null)
        'evidence_hash_version': evidenceHashVersion,
      if (algorithmVersion != null) 'algorithm_version': algorithmVersion,
      if (configVersion != null) 'config_version': configVersion,
      if (currentValuesJson != null) 'current_values_json': currentValuesJson,
      if (candidateValuesJson != null)
        'candidate_values_json': candidateValuesJson,
      if (reasonCodesJson != null) 'reason_codes_json': reasonCodesJson,
      if (triggeredAt != null) 'triggered_at': triggeredAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningRunsTableCompanion copyWith({
    Value<String>? id,
    Value<LearningParameterFamily>? parameterFamily,
    Value<String>? sourceModelIdentity,
    Value<String?>? sourcePersonalizationVersionId,
    Value<LearningRunStatus>? status,
    Value<LearningRunResult?>? result,
    Value<String>? evidenceSnapshotJson,
    Value<String>? evidenceHash,
    Value<String>? evidenceHashVersion,
    Value<String>? algorithmVersion,
    Value<String>? configVersion,
    Value<String>? currentValuesJson,
    Value<String?>? candidateValuesJson,
    Value<String>? reasonCodesJson,
    Value<DateTime>? triggeredAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return LearningRunsTableCompanion(
      id: id ?? this.id,
      parameterFamily: parameterFamily ?? this.parameterFamily,
      sourceModelIdentity: sourceModelIdentity ?? this.sourceModelIdentity,
      sourcePersonalizationVersionId:
          sourcePersonalizationVersionId ?? this.sourcePersonalizationVersionId,
      status: status ?? this.status,
      result: result ?? this.result,
      evidenceSnapshotJson: evidenceSnapshotJson ?? this.evidenceSnapshotJson,
      evidenceHash: evidenceHash ?? this.evidenceHash,
      evidenceHashVersion: evidenceHashVersion ?? this.evidenceHashVersion,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      configVersion: configVersion ?? this.configVersion,
      currentValuesJson: currentValuesJson ?? this.currentValuesJson,
      candidateValuesJson: candidateValuesJson ?? this.candidateValuesJson,
      reasonCodesJson: reasonCodesJson ?? this.reasonCodesJson,
      triggeredAt: triggeredAt ?? this.triggeredAt,
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
    if (parameterFamily.present) {
      map['parameter_family'] = Variable<String>(
        $LearningRunsTableTable.$converterparameterFamily.toSql(
          parameterFamily.value,
        ),
      );
    }
    if (sourceModelIdentity.present) {
      map['source_model_identity'] = Variable<String>(
        sourceModelIdentity.value,
      );
    }
    if (sourcePersonalizationVersionId.present) {
      map['source_personalization_version_id'] = Variable<String>(
        sourcePersonalizationVersionId.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $LearningRunsTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $LearningRunsTableTable.$converterresultn.toSql(result.value),
      );
    }
    if (evidenceSnapshotJson.present) {
      map['evidence_snapshot_json'] = Variable<String>(
        evidenceSnapshotJson.value,
      );
    }
    if (evidenceHash.present) {
      map['evidence_hash'] = Variable<String>(evidenceHash.value);
    }
    if (evidenceHashVersion.present) {
      map['evidence_hash_version'] = Variable<String>(
        evidenceHashVersion.value,
      );
    }
    if (algorithmVersion.present) {
      map['algorithm_version'] = Variable<String>(algorithmVersion.value);
    }
    if (configVersion.present) {
      map['config_version'] = Variable<String>(configVersion.value);
    }
    if (currentValuesJson.present) {
      map['current_values_json'] = Variable<String>(currentValuesJson.value);
    }
    if (candidateValuesJson.present) {
      map['candidate_values_json'] = Variable<String>(
        candidateValuesJson.value,
      );
    }
    if (reasonCodesJson.present) {
      map['reason_codes_json'] = Variable<String>(reasonCodesJson.value);
    }
    if (triggeredAt.present) {
      map['triggered_at'] = Variable<DateTime>(triggeredAt.value);
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
    return (StringBuffer('LearningRunsTableCompanion(')
          ..write('id: $id, ')
          ..write('parameterFamily: $parameterFamily, ')
          ..write('sourceModelIdentity: $sourceModelIdentity, ')
          ..write(
            'sourcePersonalizationVersionId: $sourcePersonalizationVersionId, ',
          )
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('evidenceSnapshotJson: $evidenceSnapshotJson, ')
          ..write('evidenceHash: $evidenceHash, ')
          ..write('evidenceHashVersion: $evidenceHashVersion, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('configVersion: $configVersion, ')
          ..write('currentValuesJson: $currentValuesJson, ')
          ..write('candidateValuesJson: $candidateValuesJson, ')
          ..write('reasonCodesJson: $reasonCodesJson, ')
          ..write('triggeredAt: $triggeredAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalizationVersionsTableTable extends PersonalizationVersionsTable
    with
        TableInfo<
          $PersonalizationVersionsTableTable,
          PersonalizationVersionRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalizationVersionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentVersionIdMeta = const VerificationMeta(
    'parentVersionId',
  );
  @override
  late final GeneratedColumn<String> parentVersionId = GeneratedColumn<String>(
    'parent_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectiveModelFingerprintMeta =
      const VerificationMeta('effectiveModelFingerprint');
  @override
  late final GeneratedColumn<String> effectiveModelFingerprint =
      GeneratedColumn<String>(
        'effective_model_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _modelRegimeEpochMeta = const VerificationMeta(
    'modelRegimeEpoch',
  );
  @override
  late final GeneratedColumn<String> modelRegimeEpoch = GeneratedColumn<String>(
    'model_regime_epoch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    PersonalizationCreationSource,
    String
  >
  creationSource =
      GeneratedColumn<String>(
        'creation_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PersonalizationCreationSource>(
        $PersonalizationVersionsTableTable.$convertercreationSource,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    PersonalizationScheduleSource?,
    String
  >
  scheduleSource =
      GeneratedColumn<String>(
        'schedule_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PersonalizationScheduleSource?>(
        $PersonalizationVersionsTableTable.$converterscheduleSourcen,
      );
  static const VerificationMeta _sourceLearningRunIdMeta =
      const VerificationMeta('sourceLearningRunId');
  @override
  late final GeneratedColumn<String> sourceLearningRunId =
      GeneratedColumn<String>(
        'source_learning_run_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _algorithmVersionMeta = const VerificationMeta(
    'algorithmVersion',
  );
  @override
  late final GeneratedColumn<String> algorithmVersion = GeneratedColumn<String>(
    'algorithm_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configVersionMeta = const VerificationMeta(
    'configVersion',
  );
  @override
  late final GeneratedColumn<String> configVersion = GeneratedColumn<String>(
    'config_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    PersonalizationChangedParameterFamily,
    String
  >
  changedParameterFamily =
      GeneratedColumn<String>(
        'changed_parameter_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PersonalizationChangedParameterFamily>(
        $PersonalizationVersionsTableTable.$converterchangedParameterFamily,
      );
  static const VerificationMeta _baseEnergyMeta = const VerificationMeta(
    'baseEnergy',
  );
  @override
  late final GeneratedColumn<int> baseEnergy = GeneratedColumn<int>(
    'base_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baselineAnchorEnergyMeta =
      const VerificationMeta('baselineAnchorEnergy');
  @override
  late final GeneratedColumn<int> baselineAnchorEnergy = GeneratedColumn<int>(
    'baseline_anchor_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    PersonalizationVersionStatus,
    String
  >
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PersonalizationVersionStatus>(
        $PersonalizationVersionsTableTable.$converterstatus,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay?, String>
  effectiveLifeDay =
      GeneratedColumn<String>(
        'effective_life_day',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LifeDay?>(
        $PersonalizationVersionsTableTable.$convertereffectiveLifeDayn,
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
  static const VerificationMeta _activatedAtMeta = const VerificationMeta(
    'activatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> activatedAt = GeneratedColumn<DateTime>(
    'activated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transitionReasonMeta = const VerificationMeta(
    'transitionReason',
  );
  @override
  late final GeneratedColumn<String> transitionReason = GeneratedColumn<String>(
    'transition_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentVersionId,
    effectiveModelFingerprint,
    modelRegimeEpoch,
    creationSource,
    scheduleSource,
    sourceLearningRunId,
    algorithmVersion,
    configVersion,
    changedParameterFamily,
    baseEnergy,
    baselineAnchorEnergy,
    status,
    effectiveLifeDay,
    createdAt,
    activatedAt,
    endedAt,
    transitionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personalization_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalizationVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_version_id')) {
      context.handle(
        _parentVersionIdMeta,
        parentVersionId.isAcceptableOrUnknown(
          data['parent_version_id']!,
          _parentVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('effective_model_fingerprint')) {
      context.handle(
        _effectiveModelFingerprintMeta,
        effectiveModelFingerprint.isAcceptableOrUnknown(
          data['effective_model_fingerprint']!,
          _effectiveModelFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveModelFingerprintMeta);
    }
    if (data.containsKey('model_regime_epoch')) {
      context.handle(
        _modelRegimeEpochMeta,
        modelRegimeEpoch.isAcceptableOrUnknown(
          data['model_regime_epoch']!,
          _modelRegimeEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelRegimeEpochMeta);
    }
    if (data.containsKey('source_learning_run_id')) {
      context.handle(
        _sourceLearningRunIdMeta,
        sourceLearningRunId.isAcceptableOrUnknown(
          data['source_learning_run_id']!,
          _sourceLearningRunIdMeta,
        ),
      );
    }
    if (data.containsKey('algorithm_version')) {
      context.handle(
        _algorithmVersionMeta,
        algorithmVersion.isAcceptableOrUnknown(
          data['algorithm_version']!,
          _algorithmVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_algorithmVersionMeta);
    }
    if (data.containsKey('config_version')) {
      context.handle(
        _configVersionMeta,
        configVersion.isAcceptableOrUnknown(
          data['config_version']!,
          _configVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configVersionMeta);
    }
    if (data.containsKey('base_energy')) {
      context.handle(
        _baseEnergyMeta,
        baseEnergy.isAcceptableOrUnknown(data['base_energy']!, _baseEnergyMeta),
      );
    } else if (isInserting) {
      context.missing(_baseEnergyMeta);
    }
    if (data.containsKey('baseline_anchor_energy')) {
      context.handle(
        _baselineAnchorEnergyMeta,
        baselineAnchorEnergy.isAcceptableOrUnknown(
          data['baseline_anchor_energy']!,
          _baselineAnchorEnergyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baselineAnchorEnergyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('activated_at')) {
      context.handle(
        _activatedAtMeta,
        activatedAt.isAcceptableOrUnknown(
          data['activated_at']!,
          _activatedAtMeta,
        ),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('transition_reason')) {
      context.handle(
        _transitionReasonMeta,
        transitionReason.isAcceptableOrUnknown(
          data['transition_reason']!,
          _transitionReasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transitionReasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceLearningRunId},
  ];
  @override
  PersonalizationVersionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalizationVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_version_id'],
      ),
      effectiveModelFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_model_fingerprint'],
      )!,
      modelRegimeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_regime_epoch'],
      )!,
      creationSource: $PersonalizationVersionsTableTable
          .$convertercreationSource
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}creation_source'],
            )!,
          ),
      scheduleSource: $PersonalizationVersionsTableTable
          .$converterscheduleSourcen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}schedule_source'],
            ),
          ),
      sourceLearningRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_learning_run_id'],
      ),
      algorithmVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}algorithm_version'],
      )!,
      configVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_version'],
      )!,
      changedParameterFamily: $PersonalizationVersionsTableTable
          .$converterchangedParameterFamily
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}changed_parameter_family'],
            )!,
          ),
      baseEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_energy'],
      )!,
      baselineAnchorEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}baseline_anchor_energy'],
      )!,
      status: $PersonalizationVersionsTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      effectiveLifeDay: $PersonalizationVersionsTableTable
          .$convertereffectiveLifeDayn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}effective_life_day'],
            ),
          ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      activatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activated_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      transitionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transition_reason'],
      )!,
    );
  }

  @override
  $PersonalizationVersionsTableTable createAlias(String alias) {
    return $PersonalizationVersionsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<PersonalizationCreationSource, String>
  $convertercreationSource = const PersonalizationCreationSourceConverter();
  static TypeConverter<PersonalizationScheduleSource, String>
  $converterscheduleSource = const PersonalizationScheduleSourceConverter();
  static TypeConverter<PersonalizationScheduleSource?, String?>
  $converterscheduleSourcen = NullAwareTypeConverter.wrap(
    $converterscheduleSource,
  );
  static TypeConverter<PersonalizationChangedParameterFamily, String>
  $converterchangedParameterFamily =
      const PersonalizationChangedParameterFamilyConverter();
  static TypeConverter<PersonalizationVersionStatus, String> $converterstatus =
      const PersonalizationVersionStatusConverter();
  static TypeConverter<LifeDay, String> $convertereffectiveLifeDay =
      const LifeDayConverter();
  static TypeConverter<LifeDay?, String?> $convertereffectiveLifeDayn =
      NullAwareTypeConverter.wrap($convertereffectiveLifeDay);
}

class PersonalizationVersionRow extends DataClass
    implements Insertable<PersonalizationVersionRow> {
  final String id;
  final String? parentVersionId;
  final String effectiveModelFingerprint;
  final String modelRegimeEpoch;
  final PersonalizationCreationSource creationSource;
  final PersonalizationScheduleSource? scheduleSource;
  final String? sourceLearningRunId;
  final String algorithmVersion;
  final String configVersion;
  final PersonalizationChangedParameterFamily changedParameterFamily;
  final int baseEnergy;
  final int baselineAnchorEnergy;
  final PersonalizationVersionStatus status;
  final LifeDay? effectiveLifeDay;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? endedAt;
  final String transitionReason;
  const PersonalizationVersionRow({
    required this.id,
    this.parentVersionId,
    required this.effectiveModelFingerprint,
    required this.modelRegimeEpoch,
    required this.creationSource,
    this.scheduleSource,
    this.sourceLearningRunId,
    required this.algorithmVersion,
    required this.configVersion,
    required this.changedParameterFamily,
    required this.baseEnergy,
    required this.baselineAnchorEnergy,
    required this.status,
    this.effectiveLifeDay,
    required this.createdAt,
    this.activatedAt,
    this.endedAt,
    required this.transitionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentVersionId != null) {
      map['parent_version_id'] = Variable<String>(parentVersionId);
    }
    map['effective_model_fingerprint'] = Variable<String>(
      effectiveModelFingerprint,
    );
    map['model_regime_epoch'] = Variable<String>(modelRegimeEpoch);
    {
      map['creation_source'] = Variable<String>(
        $PersonalizationVersionsTableTable.$convertercreationSource.toSql(
          creationSource,
        ),
      );
    }
    if (!nullToAbsent || scheduleSource != null) {
      map['schedule_source'] = Variable<String>(
        $PersonalizationVersionsTableTable.$converterscheduleSourcen.toSql(
          scheduleSource,
        ),
      );
    }
    if (!nullToAbsent || sourceLearningRunId != null) {
      map['source_learning_run_id'] = Variable<String>(sourceLearningRunId);
    }
    map['algorithm_version'] = Variable<String>(algorithmVersion);
    map['config_version'] = Variable<String>(configVersion);
    {
      map['changed_parameter_family'] = Variable<String>(
        $PersonalizationVersionsTableTable.$converterchangedParameterFamily
            .toSql(changedParameterFamily),
      );
    }
    map['base_energy'] = Variable<int>(baseEnergy);
    map['baseline_anchor_energy'] = Variable<int>(baselineAnchorEnergy);
    {
      map['status'] = Variable<String>(
        $PersonalizationVersionsTableTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || effectiveLifeDay != null) {
      map['effective_life_day'] = Variable<String>(
        $PersonalizationVersionsTableTable.$convertereffectiveLifeDayn.toSql(
          effectiveLifeDay,
        ),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || activatedAt != null) {
      map['activated_at'] = Variable<DateTime>(activatedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['transition_reason'] = Variable<String>(transitionReason);
    return map;
  }

  PersonalizationVersionsTableCompanion toCompanion(bool nullToAbsent) {
    return PersonalizationVersionsTableCompanion(
      id: Value(id),
      parentVersionId: parentVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentVersionId),
      effectiveModelFingerprint: Value(effectiveModelFingerprint),
      modelRegimeEpoch: Value(modelRegimeEpoch),
      creationSource: Value(creationSource),
      scheduleSource: scheduleSource == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleSource),
      sourceLearningRunId: sourceLearningRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLearningRunId),
      algorithmVersion: Value(algorithmVersion),
      configVersion: Value(configVersion),
      changedParameterFamily: Value(changedParameterFamily),
      baseEnergy: Value(baseEnergy),
      baselineAnchorEnergy: Value(baselineAnchorEnergy),
      status: Value(status),
      effectiveLifeDay: effectiveLifeDay == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveLifeDay),
      createdAt: Value(createdAt),
      activatedAt: activatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activatedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      transitionReason: Value(transitionReason),
    );
  }

  factory PersonalizationVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalizationVersionRow(
      id: serializer.fromJson<String>(json['id']),
      parentVersionId: serializer.fromJson<String?>(json['parentVersionId']),
      effectiveModelFingerprint: serializer.fromJson<String>(
        json['effectiveModelFingerprint'],
      ),
      modelRegimeEpoch: serializer.fromJson<String>(json['modelRegimeEpoch']),
      creationSource: serializer.fromJson<PersonalizationCreationSource>(
        json['creationSource'],
      ),
      scheduleSource: serializer.fromJson<PersonalizationScheduleSource?>(
        json['scheduleSource'],
      ),
      sourceLearningRunId: serializer.fromJson<String?>(
        json['sourceLearningRunId'],
      ),
      algorithmVersion: serializer.fromJson<String>(json['algorithmVersion']),
      configVersion: serializer.fromJson<String>(json['configVersion']),
      changedParameterFamily: serializer
          .fromJson<PersonalizationChangedParameterFamily>(
            json['changedParameterFamily'],
          ),
      baseEnergy: serializer.fromJson<int>(json['baseEnergy']),
      baselineAnchorEnergy: serializer.fromJson<int>(
        json['baselineAnchorEnergy'],
      ),
      status: serializer.fromJson<PersonalizationVersionStatus>(json['status']),
      effectiveLifeDay: serializer.fromJson<LifeDay?>(json['effectiveLifeDay']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      activatedAt: serializer.fromJson<DateTime?>(json['activatedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      transitionReason: serializer.fromJson<String>(json['transitionReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentVersionId': serializer.toJson<String?>(parentVersionId),
      'effectiveModelFingerprint': serializer.toJson<String>(
        effectiveModelFingerprint,
      ),
      'modelRegimeEpoch': serializer.toJson<String>(modelRegimeEpoch),
      'creationSource': serializer.toJson<PersonalizationCreationSource>(
        creationSource,
      ),
      'scheduleSource': serializer.toJson<PersonalizationScheduleSource?>(
        scheduleSource,
      ),
      'sourceLearningRunId': serializer.toJson<String?>(sourceLearningRunId),
      'algorithmVersion': serializer.toJson<String>(algorithmVersion),
      'configVersion': serializer.toJson<String>(configVersion),
      'changedParameterFamily': serializer
          .toJson<PersonalizationChangedParameterFamily>(
            changedParameterFamily,
          ),
      'baseEnergy': serializer.toJson<int>(baseEnergy),
      'baselineAnchorEnergy': serializer.toJson<int>(baselineAnchorEnergy),
      'status': serializer.toJson<PersonalizationVersionStatus>(status),
      'effectiveLifeDay': serializer.toJson<LifeDay?>(effectiveLifeDay),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'activatedAt': serializer.toJson<DateTime?>(activatedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'transitionReason': serializer.toJson<String>(transitionReason),
    };
  }

  PersonalizationVersionRow copyWith({
    String? id,
    Value<String?> parentVersionId = const Value.absent(),
    String? effectiveModelFingerprint,
    String? modelRegimeEpoch,
    PersonalizationCreationSource? creationSource,
    Value<PersonalizationScheduleSource?> scheduleSource = const Value.absent(),
    Value<String?> sourceLearningRunId = const Value.absent(),
    String? algorithmVersion,
    String? configVersion,
    PersonalizationChangedParameterFamily? changedParameterFamily,
    int? baseEnergy,
    int? baselineAnchorEnergy,
    PersonalizationVersionStatus? status,
    Value<LifeDay?> effectiveLifeDay = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> activatedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    String? transitionReason,
  }) => PersonalizationVersionRow(
    id: id ?? this.id,
    parentVersionId: parentVersionId.present
        ? parentVersionId.value
        : this.parentVersionId,
    effectiveModelFingerprint:
        effectiveModelFingerprint ?? this.effectiveModelFingerprint,
    modelRegimeEpoch: modelRegimeEpoch ?? this.modelRegimeEpoch,
    creationSource: creationSource ?? this.creationSource,
    scheduleSource: scheduleSource.present
        ? scheduleSource.value
        : this.scheduleSource,
    sourceLearningRunId: sourceLearningRunId.present
        ? sourceLearningRunId.value
        : this.sourceLearningRunId,
    algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    configVersion: configVersion ?? this.configVersion,
    changedParameterFamily:
        changedParameterFamily ?? this.changedParameterFamily,
    baseEnergy: baseEnergy ?? this.baseEnergy,
    baselineAnchorEnergy: baselineAnchorEnergy ?? this.baselineAnchorEnergy,
    status: status ?? this.status,
    effectiveLifeDay: effectiveLifeDay.present
        ? effectiveLifeDay.value
        : this.effectiveLifeDay,
    createdAt: createdAt ?? this.createdAt,
    activatedAt: activatedAt.present ? activatedAt.value : this.activatedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    transitionReason: transitionReason ?? this.transitionReason,
  );
  PersonalizationVersionRow copyWithCompanion(
    PersonalizationVersionsTableCompanion data,
  ) {
    return PersonalizationVersionRow(
      id: data.id.present ? data.id.value : this.id,
      parentVersionId: data.parentVersionId.present
          ? data.parentVersionId.value
          : this.parentVersionId,
      effectiveModelFingerprint: data.effectiveModelFingerprint.present
          ? data.effectiveModelFingerprint.value
          : this.effectiveModelFingerprint,
      modelRegimeEpoch: data.modelRegimeEpoch.present
          ? data.modelRegimeEpoch.value
          : this.modelRegimeEpoch,
      creationSource: data.creationSource.present
          ? data.creationSource.value
          : this.creationSource,
      scheduleSource: data.scheduleSource.present
          ? data.scheduleSource.value
          : this.scheduleSource,
      sourceLearningRunId: data.sourceLearningRunId.present
          ? data.sourceLearningRunId.value
          : this.sourceLearningRunId,
      algorithmVersion: data.algorithmVersion.present
          ? data.algorithmVersion.value
          : this.algorithmVersion,
      configVersion: data.configVersion.present
          ? data.configVersion.value
          : this.configVersion,
      changedParameterFamily: data.changedParameterFamily.present
          ? data.changedParameterFamily.value
          : this.changedParameterFamily,
      baseEnergy: data.baseEnergy.present
          ? data.baseEnergy.value
          : this.baseEnergy,
      baselineAnchorEnergy: data.baselineAnchorEnergy.present
          ? data.baselineAnchorEnergy.value
          : this.baselineAnchorEnergy,
      status: data.status.present ? data.status.value : this.status,
      effectiveLifeDay: data.effectiveLifeDay.present
          ? data.effectiveLifeDay.value
          : this.effectiveLifeDay,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      activatedAt: data.activatedAt.present
          ? data.activatedAt.value
          : this.activatedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      transitionReason: data.transitionReason.present
          ? data.transitionReason.value
          : this.transitionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalizationVersionRow(')
          ..write('id: $id, ')
          ..write('parentVersionId: $parentVersionId, ')
          ..write('effectiveModelFingerprint: $effectiveModelFingerprint, ')
          ..write('modelRegimeEpoch: $modelRegimeEpoch, ')
          ..write('creationSource: $creationSource, ')
          ..write('scheduleSource: $scheduleSource, ')
          ..write('sourceLearningRunId: $sourceLearningRunId, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('configVersion: $configVersion, ')
          ..write('changedParameterFamily: $changedParameterFamily, ')
          ..write('baseEnergy: $baseEnergy, ')
          ..write('baselineAnchorEnergy: $baselineAnchorEnergy, ')
          ..write('status: $status, ')
          ..write('effectiveLifeDay: $effectiveLifeDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('transitionReason: $transitionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentVersionId,
    effectiveModelFingerprint,
    modelRegimeEpoch,
    creationSource,
    scheduleSource,
    sourceLearningRunId,
    algorithmVersion,
    configVersion,
    changedParameterFamily,
    baseEnergy,
    baselineAnchorEnergy,
    status,
    effectiveLifeDay,
    createdAt,
    activatedAt,
    endedAt,
    transitionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalizationVersionRow &&
          other.id == this.id &&
          other.parentVersionId == this.parentVersionId &&
          other.effectiveModelFingerprint == this.effectiveModelFingerprint &&
          other.modelRegimeEpoch == this.modelRegimeEpoch &&
          other.creationSource == this.creationSource &&
          other.scheduleSource == this.scheduleSource &&
          other.sourceLearningRunId == this.sourceLearningRunId &&
          other.algorithmVersion == this.algorithmVersion &&
          other.configVersion == this.configVersion &&
          other.changedParameterFamily == this.changedParameterFamily &&
          other.baseEnergy == this.baseEnergy &&
          other.baselineAnchorEnergy == this.baselineAnchorEnergy &&
          other.status == this.status &&
          other.effectiveLifeDay == this.effectiveLifeDay &&
          other.createdAt == this.createdAt &&
          other.activatedAt == this.activatedAt &&
          other.endedAt == this.endedAt &&
          other.transitionReason == this.transitionReason);
}

class PersonalizationVersionsTableCompanion
    extends UpdateCompanion<PersonalizationVersionRow> {
  final Value<String> id;
  final Value<String?> parentVersionId;
  final Value<String> effectiveModelFingerprint;
  final Value<String> modelRegimeEpoch;
  final Value<PersonalizationCreationSource> creationSource;
  final Value<PersonalizationScheduleSource?> scheduleSource;
  final Value<String?> sourceLearningRunId;
  final Value<String> algorithmVersion;
  final Value<String> configVersion;
  final Value<PersonalizationChangedParameterFamily> changedParameterFamily;
  final Value<int> baseEnergy;
  final Value<int> baselineAnchorEnergy;
  final Value<PersonalizationVersionStatus> status;
  final Value<LifeDay?> effectiveLifeDay;
  final Value<DateTime> createdAt;
  final Value<DateTime?> activatedAt;
  final Value<DateTime?> endedAt;
  final Value<String> transitionReason;
  final Value<int> rowid;
  const PersonalizationVersionsTableCompanion({
    this.id = const Value.absent(),
    this.parentVersionId = const Value.absent(),
    this.effectiveModelFingerprint = const Value.absent(),
    this.modelRegimeEpoch = const Value.absent(),
    this.creationSource = const Value.absent(),
    this.scheduleSource = const Value.absent(),
    this.sourceLearningRunId = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    this.configVersion = const Value.absent(),
    this.changedParameterFamily = const Value.absent(),
    this.baseEnergy = const Value.absent(),
    this.baselineAnchorEnergy = const Value.absent(),
    this.status = const Value.absent(),
    this.effectiveLifeDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.transitionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalizationVersionsTableCompanion.insert({
    required String id,
    this.parentVersionId = const Value.absent(),
    required String effectiveModelFingerprint,
    required String modelRegimeEpoch,
    required PersonalizationCreationSource creationSource,
    this.scheduleSource = const Value.absent(),
    this.sourceLearningRunId = const Value.absent(),
    required String algorithmVersion,
    required String configVersion,
    required PersonalizationChangedParameterFamily changedParameterFamily,
    required int baseEnergy,
    required int baselineAnchorEnergy,
    required PersonalizationVersionStatus status,
    this.effectiveLifeDay = const Value.absent(),
    required DateTime createdAt,
    this.activatedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required String transitionReason,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       effectiveModelFingerprint = Value(effectiveModelFingerprint),
       modelRegimeEpoch = Value(modelRegimeEpoch),
       creationSource = Value(creationSource),
       algorithmVersion = Value(algorithmVersion),
       configVersion = Value(configVersion),
       changedParameterFamily = Value(changedParameterFamily),
       baseEnergy = Value(baseEnergy),
       baselineAnchorEnergy = Value(baselineAnchorEnergy),
       status = Value(status),
       createdAt = Value(createdAt),
       transitionReason = Value(transitionReason);
  static Insertable<PersonalizationVersionRow> custom({
    Expression<String>? id,
    Expression<String>? parentVersionId,
    Expression<String>? effectiveModelFingerprint,
    Expression<String>? modelRegimeEpoch,
    Expression<String>? creationSource,
    Expression<String>? scheduleSource,
    Expression<String>? sourceLearningRunId,
    Expression<String>? algorithmVersion,
    Expression<String>? configVersion,
    Expression<String>? changedParameterFamily,
    Expression<int>? baseEnergy,
    Expression<int>? baselineAnchorEnergy,
    Expression<String>? status,
    Expression<String>? effectiveLifeDay,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? activatedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? transitionReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentVersionId != null) 'parent_version_id': parentVersionId,
      if (effectiveModelFingerprint != null)
        'effective_model_fingerprint': effectiveModelFingerprint,
      if (modelRegimeEpoch != null) 'model_regime_epoch': modelRegimeEpoch,
      if (creationSource != null) 'creation_source': creationSource,
      if (scheduleSource != null) 'schedule_source': scheduleSource,
      if (sourceLearningRunId != null)
        'source_learning_run_id': sourceLearningRunId,
      if (algorithmVersion != null) 'algorithm_version': algorithmVersion,
      if (configVersion != null) 'config_version': configVersion,
      if (changedParameterFamily != null)
        'changed_parameter_family': changedParameterFamily,
      if (baseEnergy != null) 'base_energy': baseEnergy,
      if (baselineAnchorEnergy != null)
        'baseline_anchor_energy': baselineAnchorEnergy,
      if (status != null) 'status': status,
      if (effectiveLifeDay != null) 'effective_life_day': effectiveLifeDay,
      if (createdAt != null) 'created_at': createdAt,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (transitionReason != null) 'transition_reason': transitionReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalizationVersionsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentVersionId,
    Value<String>? effectiveModelFingerprint,
    Value<String>? modelRegimeEpoch,
    Value<PersonalizationCreationSource>? creationSource,
    Value<PersonalizationScheduleSource?>? scheduleSource,
    Value<String?>? sourceLearningRunId,
    Value<String>? algorithmVersion,
    Value<String>? configVersion,
    Value<PersonalizationChangedParameterFamily>? changedParameterFamily,
    Value<int>? baseEnergy,
    Value<int>? baselineAnchorEnergy,
    Value<PersonalizationVersionStatus>? status,
    Value<LifeDay?>? effectiveLifeDay,
    Value<DateTime>? createdAt,
    Value<DateTime?>? activatedAt,
    Value<DateTime?>? endedAt,
    Value<String>? transitionReason,
    Value<int>? rowid,
  }) {
    return PersonalizationVersionsTableCompanion(
      id: id ?? this.id,
      parentVersionId: parentVersionId ?? this.parentVersionId,
      effectiveModelFingerprint:
          effectiveModelFingerprint ?? this.effectiveModelFingerprint,
      modelRegimeEpoch: modelRegimeEpoch ?? this.modelRegimeEpoch,
      creationSource: creationSource ?? this.creationSource,
      scheduleSource: scheduleSource ?? this.scheduleSource,
      sourceLearningRunId: sourceLearningRunId ?? this.sourceLearningRunId,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      configVersion: configVersion ?? this.configVersion,
      changedParameterFamily:
          changedParameterFamily ?? this.changedParameterFamily,
      baseEnergy: baseEnergy ?? this.baseEnergy,
      baselineAnchorEnergy: baselineAnchorEnergy ?? this.baselineAnchorEnergy,
      status: status ?? this.status,
      effectiveLifeDay: effectiveLifeDay ?? this.effectiveLifeDay,
      createdAt: createdAt ?? this.createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
      endedAt: endedAt ?? this.endedAt,
      transitionReason: transitionReason ?? this.transitionReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentVersionId.present) {
      map['parent_version_id'] = Variable<String>(parentVersionId.value);
    }
    if (effectiveModelFingerprint.present) {
      map['effective_model_fingerprint'] = Variable<String>(
        effectiveModelFingerprint.value,
      );
    }
    if (modelRegimeEpoch.present) {
      map['model_regime_epoch'] = Variable<String>(modelRegimeEpoch.value);
    }
    if (creationSource.present) {
      map['creation_source'] = Variable<String>(
        $PersonalizationVersionsTableTable.$convertercreationSource.toSql(
          creationSource.value,
        ),
      );
    }
    if (scheduleSource.present) {
      map['schedule_source'] = Variable<String>(
        $PersonalizationVersionsTableTable.$converterscheduleSourcen.toSql(
          scheduleSource.value,
        ),
      );
    }
    if (sourceLearningRunId.present) {
      map['source_learning_run_id'] = Variable<String>(
        sourceLearningRunId.value,
      );
    }
    if (algorithmVersion.present) {
      map['algorithm_version'] = Variable<String>(algorithmVersion.value);
    }
    if (configVersion.present) {
      map['config_version'] = Variable<String>(configVersion.value);
    }
    if (changedParameterFamily.present) {
      map['changed_parameter_family'] = Variable<String>(
        $PersonalizationVersionsTableTable.$converterchangedParameterFamily
            .toSql(changedParameterFamily.value),
      );
    }
    if (baseEnergy.present) {
      map['base_energy'] = Variable<int>(baseEnergy.value);
    }
    if (baselineAnchorEnergy.present) {
      map['baseline_anchor_energy'] = Variable<int>(baselineAnchorEnergy.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PersonalizationVersionsTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (effectiveLifeDay.present) {
      map['effective_life_day'] = Variable<String>(
        $PersonalizationVersionsTableTable.$convertereffectiveLifeDayn.toSql(
          effectiveLifeDay.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<DateTime>(activatedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (transitionReason.present) {
      map['transition_reason'] = Variable<String>(transitionReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalizationVersionsTableCompanion(')
          ..write('id: $id, ')
          ..write('parentVersionId: $parentVersionId, ')
          ..write('effectiveModelFingerprint: $effectiveModelFingerprint, ')
          ..write('modelRegimeEpoch: $modelRegimeEpoch, ')
          ..write('creationSource: $creationSource, ')
          ..write('scheduleSource: $scheduleSource, ')
          ..write('sourceLearningRunId: $sourceLearningRunId, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('configVersion: $configVersion, ')
          ..write('changedParameterFamily: $changedParameterFamily, ')
          ..write('baseEnergy: $baseEnergy, ')
          ..write('baselineAnchorEnergy: $baselineAnchorEnergy, ')
          ..write('status: $status, ')
          ..write('effectiveLifeDay: $effectiveLifeDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('transitionReason: $transitionReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalizationActivityFactorsTableTable
    extends PersonalizationActivityFactorsTable
    with
        TableInfo<
          $PersonalizationActivityFactorsTableTable,
          PersonalizationActivityFactorRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalizationActivityFactorsTableTable(
    this.attachedDatabase, [
    this._alias,
  ]);
  static const VerificationMeta _personalizationVersionIdMeta =
      const VerificationMeta('personalizationVersionId');
  @override
  late final GeneratedColumn<String> personalizationVersionId =
      GeneratedColumn<String>(
        'personalization_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
        $PersonalizationActivityFactorsTableTable.$convertersubcategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityImpactSign, String>
  impactSign =
      GeneratedColumn<String>(
        'impact_sign',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityImpactSign>(
        $PersonalizationActivityFactorsTableTable.$converterimpactSign,
      );
  static const VerificationMeta _factorMeta = const VerificationMeta('factor');
  @override
  late final GeneratedColumn<double> factor = GeneratedColumn<double>(
    'factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseActivityRuleVersionMeta =
      const VerificationMeta('baseActivityRuleVersion');
  @override
  late final GeneratedColumn<String> baseActivityRuleVersion =
      GeneratedColumn<String>(
        'base_activity_rule_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceLearningRunIdMeta =
      const VerificationMeta('sourceLearningRunId');
  @override
  late final GeneratedColumn<String> sourceLearningRunId =
      GeneratedColumn<String>(
        'source_learning_run_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LifeDay, String>
  factorRegimeStartedLifeDay =
      GeneratedColumn<String>(
        'factor_regime_started_life_day',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LifeDay>(
        $PersonalizationActivityFactorsTableTable
            .$converterfactorRegimeStartedLifeDay,
      );
  @override
  List<GeneratedColumn> get $columns => [
    personalizationVersionId,
    subcategory,
    impactSign,
    factor,
    baseActivityRuleVersion,
    sourceLearningRunId,
    factorRegimeStartedLifeDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personalization_activity_factors';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalizationActivityFactorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('personalization_version_id')) {
      context.handle(
        _personalizationVersionIdMeta,
        personalizationVersionId.isAcceptableOrUnknown(
          data['personalization_version_id']!,
          _personalizationVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_personalizationVersionIdMeta);
    }
    if (data.containsKey('factor')) {
      context.handle(
        _factorMeta,
        factor.isAcceptableOrUnknown(data['factor']!, _factorMeta),
      );
    } else if (isInserting) {
      context.missing(_factorMeta);
    }
    if (data.containsKey('base_activity_rule_version')) {
      context.handle(
        _baseActivityRuleVersionMeta,
        baseActivityRuleVersion.isAcceptableOrUnknown(
          data['base_activity_rule_version']!,
          _baseActivityRuleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseActivityRuleVersionMeta);
    }
    if (data.containsKey('source_learning_run_id')) {
      context.handle(
        _sourceLearningRunIdMeta,
        sourceLearningRunId.isAcceptableOrUnknown(
          data['source_learning_run_id']!,
          _sourceLearningRunIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    personalizationVersionId,
    subcategory,
    impactSign,
  };
  @override
  PersonalizationActivityFactorRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalizationActivityFactorRow(
      personalizationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personalization_version_id'],
      )!,
      subcategory: $PersonalizationActivityFactorsTableTable
          .$convertersubcategory
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}subcategory'],
            )!,
          ),
      impactSign: $PersonalizationActivityFactorsTableTable.$converterimpactSign
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}impact_sign'],
            )!,
          ),
      factor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}factor'],
      )!,
      baseActivityRuleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_activity_rule_version'],
      )!,
      sourceLearningRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_learning_run_id'],
      ),
      factorRegimeStartedLifeDay: $PersonalizationActivityFactorsTableTable
          .$converterfactorRegimeStartedLifeDay
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}factor_regime_started_life_day'],
            )!,
          ),
    );
  }

  @override
  $PersonalizationActivityFactorsTableTable createAlias(String alias) {
    return $PersonalizationActivityFactorsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<ActivitySubcategory, String> $convertersubcategory =
      const ActivitySubcategoryConverter();
  static TypeConverter<ActivityImpactSign, String> $converterimpactSign =
      const ActivityImpactSignConverter();
  static TypeConverter<LifeDay, String> $converterfactorRegimeStartedLifeDay =
      const LifeDayConverter();
}

class PersonalizationActivityFactorRow extends DataClass
    implements Insertable<PersonalizationActivityFactorRow> {
  final String personalizationVersionId;
  final ActivitySubcategory subcategory;
  final ActivityImpactSign impactSign;
  final double factor;
  final String baseActivityRuleVersion;
  final String? sourceLearningRunId;
  final LifeDay factorRegimeStartedLifeDay;
  const PersonalizationActivityFactorRow({
    required this.personalizationVersionId,
    required this.subcategory,
    required this.impactSign,
    required this.factor,
    required this.baseActivityRuleVersion,
    this.sourceLearningRunId,
    required this.factorRegimeStartedLifeDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['personalization_version_id'] = Variable<String>(
      personalizationVersionId,
    );
    {
      map['subcategory'] = Variable<String>(
        $PersonalizationActivityFactorsTableTable.$convertersubcategory.toSql(
          subcategory,
        ),
      );
    }
    {
      map['impact_sign'] = Variable<String>(
        $PersonalizationActivityFactorsTableTable.$converterimpactSign.toSql(
          impactSign,
        ),
      );
    }
    map['factor'] = Variable<double>(factor);
    map['base_activity_rule_version'] = Variable<String>(
      baseActivityRuleVersion,
    );
    if (!nullToAbsent || sourceLearningRunId != null) {
      map['source_learning_run_id'] = Variable<String>(sourceLearningRunId);
    }
    {
      map['factor_regime_started_life_day'] = Variable<String>(
        $PersonalizationActivityFactorsTableTable
            .$converterfactorRegimeStartedLifeDay
            .toSql(factorRegimeStartedLifeDay),
      );
    }
    return map;
  }

  PersonalizationActivityFactorsTableCompanion toCompanion(bool nullToAbsent) {
    return PersonalizationActivityFactorsTableCompanion(
      personalizationVersionId: Value(personalizationVersionId),
      subcategory: Value(subcategory),
      impactSign: Value(impactSign),
      factor: Value(factor),
      baseActivityRuleVersion: Value(baseActivityRuleVersion),
      sourceLearningRunId: sourceLearningRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLearningRunId),
      factorRegimeStartedLifeDay: Value(factorRegimeStartedLifeDay),
    );
  }

  factory PersonalizationActivityFactorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalizationActivityFactorRow(
      personalizationVersionId: serializer.fromJson<String>(
        json['personalizationVersionId'],
      ),
      subcategory: serializer.fromJson<ActivitySubcategory>(
        json['subcategory'],
      ),
      impactSign: serializer.fromJson<ActivityImpactSign>(json['impactSign']),
      factor: serializer.fromJson<double>(json['factor']),
      baseActivityRuleVersion: serializer.fromJson<String>(
        json['baseActivityRuleVersion'],
      ),
      sourceLearningRunId: serializer.fromJson<String?>(
        json['sourceLearningRunId'],
      ),
      factorRegimeStartedLifeDay: serializer.fromJson<LifeDay>(
        json['factorRegimeStartedLifeDay'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personalizationVersionId': serializer.toJson<String>(
        personalizationVersionId,
      ),
      'subcategory': serializer.toJson<ActivitySubcategory>(subcategory),
      'impactSign': serializer.toJson<ActivityImpactSign>(impactSign),
      'factor': serializer.toJson<double>(factor),
      'baseActivityRuleVersion': serializer.toJson<String>(
        baseActivityRuleVersion,
      ),
      'sourceLearningRunId': serializer.toJson<String?>(sourceLearningRunId),
      'factorRegimeStartedLifeDay': serializer.toJson<LifeDay>(
        factorRegimeStartedLifeDay,
      ),
    };
  }

  PersonalizationActivityFactorRow copyWith({
    String? personalizationVersionId,
    ActivitySubcategory? subcategory,
    ActivityImpactSign? impactSign,
    double? factor,
    String? baseActivityRuleVersion,
    Value<String?> sourceLearningRunId = const Value.absent(),
    LifeDay? factorRegimeStartedLifeDay,
  }) => PersonalizationActivityFactorRow(
    personalizationVersionId:
        personalizationVersionId ?? this.personalizationVersionId,
    subcategory: subcategory ?? this.subcategory,
    impactSign: impactSign ?? this.impactSign,
    factor: factor ?? this.factor,
    baseActivityRuleVersion:
        baseActivityRuleVersion ?? this.baseActivityRuleVersion,
    sourceLearningRunId: sourceLearningRunId.present
        ? sourceLearningRunId.value
        : this.sourceLearningRunId,
    factorRegimeStartedLifeDay:
        factorRegimeStartedLifeDay ?? this.factorRegimeStartedLifeDay,
  );
  PersonalizationActivityFactorRow copyWithCompanion(
    PersonalizationActivityFactorsTableCompanion data,
  ) {
    return PersonalizationActivityFactorRow(
      personalizationVersionId: data.personalizationVersionId.present
          ? data.personalizationVersionId.value
          : this.personalizationVersionId,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      impactSign: data.impactSign.present
          ? data.impactSign.value
          : this.impactSign,
      factor: data.factor.present ? data.factor.value : this.factor,
      baseActivityRuleVersion: data.baseActivityRuleVersion.present
          ? data.baseActivityRuleVersion.value
          : this.baseActivityRuleVersion,
      sourceLearningRunId: data.sourceLearningRunId.present
          ? data.sourceLearningRunId.value
          : this.sourceLearningRunId,
      factorRegimeStartedLifeDay: data.factorRegimeStartedLifeDay.present
          ? data.factorRegimeStartedLifeDay.value
          : this.factorRegimeStartedLifeDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalizationActivityFactorRow(')
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('subcategory: $subcategory, ')
          ..write('impactSign: $impactSign, ')
          ..write('factor: $factor, ')
          ..write('baseActivityRuleVersion: $baseActivityRuleVersion, ')
          ..write('sourceLearningRunId: $sourceLearningRunId, ')
          ..write('factorRegimeStartedLifeDay: $factorRegimeStartedLifeDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    personalizationVersionId,
    subcategory,
    impactSign,
    factor,
    baseActivityRuleVersion,
    sourceLearningRunId,
    factorRegimeStartedLifeDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalizationActivityFactorRow &&
          other.personalizationVersionId == this.personalizationVersionId &&
          other.subcategory == this.subcategory &&
          other.impactSign == this.impactSign &&
          other.factor == this.factor &&
          other.baseActivityRuleVersion == this.baseActivityRuleVersion &&
          other.sourceLearningRunId == this.sourceLearningRunId &&
          other.factorRegimeStartedLifeDay == this.factorRegimeStartedLifeDay);
}

class PersonalizationActivityFactorsTableCompanion
    extends UpdateCompanion<PersonalizationActivityFactorRow> {
  final Value<String> personalizationVersionId;
  final Value<ActivitySubcategory> subcategory;
  final Value<ActivityImpactSign> impactSign;
  final Value<double> factor;
  final Value<String> baseActivityRuleVersion;
  final Value<String?> sourceLearningRunId;
  final Value<LifeDay> factorRegimeStartedLifeDay;
  final Value<int> rowid;
  const PersonalizationActivityFactorsTableCompanion({
    this.personalizationVersionId = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.impactSign = const Value.absent(),
    this.factor = const Value.absent(),
    this.baseActivityRuleVersion = const Value.absent(),
    this.sourceLearningRunId = const Value.absent(),
    this.factorRegimeStartedLifeDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalizationActivityFactorsTableCompanion.insert({
    required String personalizationVersionId,
    required ActivitySubcategory subcategory,
    required ActivityImpactSign impactSign,
    required double factor,
    required String baseActivityRuleVersion,
    this.sourceLearningRunId = const Value.absent(),
    required LifeDay factorRegimeStartedLifeDay,
    this.rowid = const Value.absent(),
  }) : personalizationVersionId = Value(personalizationVersionId),
       subcategory = Value(subcategory),
       impactSign = Value(impactSign),
       factor = Value(factor),
       baseActivityRuleVersion = Value(baseActivityRuleVersion),
       factorRegimeStartedLifeDay = Value(factorRegimeStartedLifeDay);
  static Insertable<PersonalizationActivityFactorRow> custom({
    Expression<String>? personalizationVersionId,
    Expression<String>? subcategory,
    Expression<String>? impactSign,
    Expression<double>? factor,
    Expression<String>? baseActivityRuleVersion,
    Expression<String>? sourceLearningRunId,
    Expression<String>? factorRegimeStartedLifeDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (personalizationVersionId != null)
        'personalization_version_id': personalizationVersionId,
      if (subcategory != null) 'subcategory': subcategory,
      if (impactSign != null) 'impact_sign': impactSign,
      if (factor != null) 'factor': factor,
      if (baseActivityRuleVersion != null)
        'base_activity_rule_version': baseActivityRuleVersion,
      if (sourceLearningRunId != null)
        'source_learning_run_id': sourceLearningRunId,
      if (factorRegimeStartedLifeDay != null)
        'factor_regime_started_life_day': factorRegimeStartedLifeDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalizationActivityFactorsTableCompanion copyWith({
    Value<String>? personalizationVersionId,
    Value<ActivitySubcategory>? subcategory,
    Value<ActivityImpactSign>? impactSign,
    Value<double>? factor,
    Value<String>? baseActivityRuleVersion,
    Value<String?>? sourceLearningRunId,
    Value<LifeDay>? factorRegimeStartedLifeDay,
    Value<int>? rowid,
  }) {
    return PersonalizationActivityFactorsTableCompanion(
      personalizationVersionId:
          personalizationVersionId ?? this.personalizationVersionId,
      subcategory: subcategory ?? this.subcategory,
      impactSign: impactSign ?? this.impactSign,
      factor: factor ?? this.factor,
      baseActivityRuleVersion:
          baseActivityRuleVersion ?? this.baseActivityRuleVersion,
      sourceLearningRunId: sourceLearningRunId ?? this.sourceLearningRunId,
      factorRegimeStartedLifeDay:
          factorRegimeStartedLifeDay ?? this.factorRegimeStartedLifeDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personalizationVersionId.present) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId.value,
      );
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(
        $PersonalizationActivityFactorsTableTable.$convertersubcategory.toSql(
          subcategory.value,
        ),
      );
    }
    if (impactSign.present) {
      map['impact_sign'] = Variable<String>(
        $PersonalizationActivityFactorsTableTable.$converterimpactSign.toSql(
          impactSign.value,
        ),
      );
    }
    if (factor.present) {
      map['factor'] = Variable<double>(factor.value);
    }
    if (baseActivityRuleVersion.present) {
      map['base_activity_rule_version'] = Variable<String>(
        baseActivityRuleVersion.value,
      );
    }
    if (sourceLearningRunId.present) {
      map['source_learning_run_id'] = Variable<String>(
        sourceLearningRunId.value,
      );
    }
    if (factorRegimeStartedLifeDay.present) {
      map['factor_regime_started_life_day'] = Variable<String>(
        $PersonalizationActivityFactorsTableTable
            .$converterfactorRegimeStartedLifeDay
            .toSql(factorRegimeStartedLifeDay.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalizationActivityFactorsTableCompanion(')
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('subcategory: $subcategory, ')
          ..write('impactSign: $impactSign, ')
          ..write('factor: $factor, ')
          ..write('baseActivityRuleVersion: $baseActivityRuleVersion, ')
          ..write('sourceLearningRunId: $sourceLearningRunId, ')
          ..write('factorRegimeStartedLifeDay: $factorRegimeStartedLifeDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityFeedbackSamplesTableTable extends ActivityFeedbackSamplesTable
    with
        TableInfo<
          $ActivityFeedbackSamplesTableTable,
          ActivityFeedbackSampleRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityFeedbackSamplesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityRecordIdMeta = const VerificationMeta(
    'activityRecordId',
  );
  @override
  late final GeneratedColumn<String> activityRecordId = GeneratedColumn<String>(
    'activity_record_id',
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
      ).withConverter<LifeDay>(
        $ActivityFeedbackSamplesTableTable.$converterlifeDay,
      );
  static const VerificationMeta _samplingPolicyVersionMeta =
      const VerificationMeta('samplingPolicyVersion');
  @override
  late final GeneratedColumn<String> samplingPolicyVersion =
      GeneratedColumn<String>(
        'sampling_policy_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    ActivityFeedbackSampleStatus,
    String
  >
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ActivityFeedbackSampleStatus>(
        $ActivityFeedbackSamplesTableTable.$converterstatus,
      );
  static const VerificationMeta _selectedAtMeta = const VerificationMeta(
    'selectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> selectedAt = GeneratedColumn<DateTime>(
    'selected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptedAtMeta = const VerificationMeta(
    'promptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> promptedAt = GeneratedColumn<DateTime>(
    'prompted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<DateTime> respondedAt = GeneratedColumn<DateTime>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedbackIdMeta = const VerificationMeta(
    'feedbackId',
  );
  @override
  late final GeneratedColumn<String> feedbackId = GeneratedColumn<String>(
    'feedback_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invalidatedAtMeta = const VerificationMeta(
    'invalidatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> invalidatedAt =
      GeneratedColumn<DateTime>(
        'invalidated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    ActivityFeedbackInvalidationReason?,
    String
  >
  invalidationReason =
      GeneratedColumn<String>(
        'invalidation_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ActivityFeedbackInvalidationReason?>(
        $ActivityFeedbackSamplesTableTable.$converterinvalidationReasonn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityRecordId,
    lifeDay,
    samplingPolicyVersion,
    status,
    selectedAt,
    promptedAt,
    respondedAt,
    feedbackId,
    invalidatedAt,
    invalidationReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_feedback_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityFeedbackSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_record_id')) {
      context.handle(
        _activityRecordIdMeta,
        activityRecordId.isAcceptableOrUnknown(
          data['activity_record_id']!,
          _activityRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityRecordIdMeta);
    }
    if (data.containsKey('sampling_policy_version')) {
      context.handle(
        _samplingPolicyVersionMeta,
        samplingPolicyVersion.isAcceptableOrUnknown(
          data['sampling_policy_version']!,
          _samplingPolicyVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_samplingPolicyVersionMeta);
    }
    if (data.containsKey('selected_at')) {
      context.handle(
        _selectedAtMeta,
        selectedAt.isAcceptableOrUnknown(data['selected_at']!, _selectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_selectedAtMeta);
    }
    if (data.containsKey('prompted_at')) {
      context.handle(
        _promptedAtMeta,
        promptedAt.isAcceptableOrUnknown(data['prompted_at']!, _promptedAtMeta),
      );
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    if (data.containsKey('feedback_id')) {
      context.handle(
        _feedbackIdMeta,
        feedbackId.isAcceptableOrUnknown(data['feedback_id']!, _feedbackIdMeta),
      );
    }
    if (data.containsKey('invalidated_at')) {
      context.handle(
        _invalidatedAtMeta,
        invalidatedAt.isAcceptableOrUnknown(
          data['invalidated_at']!,
          _invalidatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityFeedbackSampleRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityFeedbackSampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activityRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_record_id'],
      )!,
      lifeDay: $ActivityFeedbackSamplesTableTable.$converterlifeDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}life_day'],
        )!,
      ),
      samplingPolicyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sampling_policy_version'],
      )!,
      status: $ActivityFeedbackSamplesTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      selectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}selected_at'],
      )!,
      promptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}prompted_at'],
      ),
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}responded_at'],
      ),
      feedbackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback_id'],
      ),
      invalidatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invalidated_at'],
      ),
      invalidationReason: $ActivityFeedbackSamplesTableTable
          .$converterinvalidationReasonn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}invalidation_reason'],
            ),
          ),
    );
  }

  @override
  $ActivityFeedbackSamplesTableTable createAlias(String alias) {
    return $ActivityFeedbackSamplesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LifeDay, String> $converterlifeDay =
      const LifeDayConverter();
  static TypeConverter<ActivityFeedbackSampleStatus, String> $converterstatus =
      const ActivityFeedbackSampleStatusConverter();
  static TypeConverter<ActivityFeedbackInvalidationReason, String>
  $converterinvalidationReason =
      const ActivityFeedbackInvalidationReasonConverter();
  static TypeConverter<ActivityFeedbackInvalidationReason?, String?>
  $converterinvalidationReasonn = NullAwareTypeConverter.wrap(
    $converterinvalidationReason,
  );
}

class ActivityFeedbackSampleRow extends DataClass
    implements Insertable<ActivityFeedbackSampleRow> {
  final String id;
  final String activityRecordId;
  final LifeDay lifeDay;
  final String samplingPolicyVersion;
  final ActivityFeedbackSampleStatus status;
  final DateTime selectedAt;
  final DateTime? promptedAt;
  final DateTime? respondedAt;
  final String? feedbackId;
  final DateTime? invalidatedAt;
  final ActivityFeedbackInvalidationReason? invalidationReason;
  const ActivityFeedbackSampleRow({
    required this.id,
    required this.activityRecordId,
    required this.lifeDay,
    required this.samplingPolicyVersion,
    required this.status,
    required this.selectedAt,
    this.promptedAt,
    this.respondedAt,
    this.feedbackId,
    this.invalidatedAt,
    this.invalidationReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_record_id'] = Variable<String>(activityRecordId);
    {
      map['life_day'] = Variable<String>(
        $ActivityFeedbackSamplesTableTable.$converterlifeDay.toSql(lifeDay),
      );
    }
    map['sampling_policy_version'] = Variable<String>(samplingPolicyVersion);
    {
      map['status'] = Variable<String>(
        $ActivityFeedbackSamplesTableTable.$converterstatus.toSql(status),
      );
    }
    map['selected_at'] = Variable<DateTime>(selectedAt);
    if (!nullToAbsent || promptedAt != null) {
      map['prompted_at'] = Variable<DateTime>(promptedAt);
    }
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<DateTime>(respondedAt);
    }
    if (!nullToAbsent || feedbackId != null) {
      map['feedback_id'] = Variable<String>(feedbackId);
    }
    if (!nullToAbsent || invalidatedAt != null) {
      map['invalidated_at'] = Variable<DateTime>(invalidatedAt);
    }
    if (!nullToAbsent || invalidationReason != null) {
      map['invalidation_reason'] = Variable<String>(
        $ActivityFeedbackSamplesTableTable.$converterinvalidationReasonn.toSql(
          invalidationReason,
        ),
      );
    }
    return map;
  }

  ActivityFeedbackSamplesTableCompanion toCompanion(bool nullToAbsent) {
    return ActivityFeedbackSamplesTableCompanion(
      id: Value(id),
      activityRecordId: Value(activityRecordId),
      lifeDay: Value(lifeDay),
      samplingPolicyVersion: Value(samplingPolicyVersion),
      status: Value(status),
      selectedAt: Value(selectedAt),
      promptedAt: promptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(promptedAt),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
      feedbackId: feedbackId == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackId),
      invalidatedAt: invalidatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(invalidatedAt),
      invalidationReason: invalidationReason == null && nullToAbsent
          ? const Value.absent()
          : Value(invalidationReason),
    );
  }

  factory ActivityFeedbackSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityFeedbackSampleRow(
      id: serializer.fromJson<String>(json['id']),
      activityRecordId: serializer.fromJson<String>(json['activityRecordId']),
      lifeDay: serializer.fromJson<LifeDay>(json['lifeDay']),
      samplingPolicyVersion: serializer.fromJson<String>(
        json['samplingPolicyVersion'],
      ),
      status: serializer.fromJson<ActivityFeedbackSampleStatus>(json['status']),
      selectedAt: serializer.fromJson<DateTime>(json['selectedAt']),
      promptedAt: serializer.fromJson<DateTime?>(json['promptedAt']),
      respondedAt: serializer.fromJson<DateTime?>(json['respondedAt']),
      feedbackId: serializer.fromJson<String?>(json['feedbackId']),
      invalidatedAt: serializer.fromJson<DateTime?>(json['invalidatedAt']),
      invalidationReason: serializer
          .fromJson<ActivityFeedbackInvalidationReason?>(
            json['invalidationReason'],
          ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityRecordId': serializer.toJson<String>(activityRecordId),
      'lifeDay': serializer.toJson<LifeDay>(lifeDay),
      'samplingPolicyVersion': serializer.toJson<String>(samplingPolicyVersion),
      'status': serializer.toJson<ActivityFeedbackSampleStatus>(status),
      'selectedAt': serializer.toJson<DateTime>(selectedAt),
      'promptedAt': serializer.toJson<DateTime?>(promptedAt),
      'respondedAt': serializer.toJson<DateTime?>(respondedAt),
      'feedbackId': serializer.toJson<String?>(feedbackId),
      'invalidatedAt': serializer.toJson<DateTime?>(invalidatedAt),
      'invalidationReason': serializer
          .toJson<ActivityFeedbackInvalidationReason?>(invalidationReason),
    };
  }

  ActivityFeedbackSampleRow copyWith({
    String? id,
    String? activityRecordId,
    LifeDay? lifeDay,
    String? samplingPolicyVersion,
    ActivityFeedbackSampleStatus? status,
    DateTime? selectedAt,
    Value<DateTime?> promptedAt = const Value.absent(),
    Value<DateTime?> respondedAt = const Value.absent(),
    Value<String?> feedbackId = const Value.absent(),
    Value<DateTime?> invalidatedAt = const Value.absent(),
    Value<ActivityFeedbackInvalidationReason?> invalidationReason =
        const Value.absent(),
  }) => ActivityFeedbackSampleRow(
    id: id ?? this.id,
    activityRecordId: activityRecordId ?? this.activityRecordId,
    lifeDay: lifeDay ?? this.lifeDay,
    samplingPolicyVersion: samplingPolicyVersion ?? this.samplingPolicyVersion,
    status: status ?? this.status,
    selectedAt: selectedAt ?? this.selectedAt,
    promptedAt: promptedAt.present ? promptedAt.value : this.promptedAt,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
    feedbackId: feedbackId.present ? feedbackId.value : this.feedbackId,
    invalidatedAt: invalidatedAt.present
        ? invalidatedAt.value
        : this.invalidatedAt,
    invalidationReason: invalidationReason.present
        ? invalidationReason.value
        : this.invalidationReason,
  );
  ActivityFeedbackSampleRow copyWithCompanion(
    ActivityFeedbackSamplesTableCompanion data,
  ) {
    return ActivityFeedbackSampleRow(
      id: data.id.present ? data.id.value : this.id,
      activityRecordId: data.activityRecordId.present
          ? data.activityRecordId.value
          : this.activityRecordId,
      lifeDay: data.lifeDay.present ? data.lifeDay.value : this.lifeDay,
      samplingPolicyVersion: data.samplingPolicyVersion.present
          ? data.samplingPolicyVersion.value
          : this.samplingPolicyVersion,
      status: data.status.present ? data.status.value : this.status,
      selectedAt: data.selectedAt.present
          ? data.selectedAt.value
          : this.selectedAt,
      promptedAt: data.promptedAt.present
          ? data.promptedAt.value
          : this.promptedAt,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
      feedbackId: data.feedbackId.present
          ? data.feedbackId.value
          : this.feedbackId,
      invalidatedAt: data.invalidatedAt.present
          ? data.invalidatedAt.value
          : this.invalidatedAt,
      invalidationReason: data.invalidationReason.present
          ? data.invalidationReason.value
          : this.invalidationReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityFeedbackSampleRow(')
          ..write('id: $id, ')
          ..write('activityRecordId: $activityRecordId, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('samplingPolicyVersion: $samplingPolicyVersion, ')
          ..write('status: $status, ')
          ..write('selectedAt: $selectedAt, ')
          ..write('promptedAt: $promptedAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('feedbackId: $feedbackId, ')
          ..write('invalidatedAt: $invalidatedAt, ')
          ..write('invalidationReason: $invalidationReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityRecordId,
    lifeDay,
    samplingPolicyVersion,
    status,
    selectedAt,
    promptedAt,
    respondedAt,
    feedbackId,
    invalidatedAt,
    invalidationReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityFeedbackSampleRow &&
          other.id == this.id &&
          other.activityRecordId == this.activityRecordId &&
          other.lifeDay == this.lifeDay &&
          other.samplingPolicyVersion == this.samplingPolicyVersion &&
          other.status == this.status &&
          other.selectedAt == this.selectedAt &&
          other.promptedAt == this.promptedAt &&
          other.respondedAt == this.respondedAt &&
          other.feedbackId == this.feedbackId &&
          other.invalidatedAt == this.invalidatedAt &&
          other.invalidationReason == this.invalidationReason);
}

class ActivityFeedbackSamplesTableCompanion
    extends UpdateCompanion<ActivityFeedbackSampleRow> {
  final Value<String> id;
  final Value<String> activityRecordId;
  final Value<LifeDay> lifeDay;
  final Value<String> samplingPolicyVersion;
  final Value<ActivityFeedbackSampleStatus> status;
  final Value<DateTime> selectedAt;
  final Value<DateTime?> promptedAt;
  final Value<DateTime?> respondedAt;
  final Value<String?> feedbackId;
  final Value<DateTime?> invalidatedAt;
  final Value<ActivityFeedbackInvalidationReason?> invalidationReason;
  final Value<int> rowid;
  const ActivityFeedbackSamplesTableCompanion({
    this.id = const Value.absent(),
    this.activityRecordId = const Value.absent(),
    this.lifeDay = const Value.absent(),
    this.samplingPolicyVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.selectedAt = const Value.absent(),
    this.promptedAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.feedbackId = const Value.absent(),
    this.invalidatedAt = const Value.absent(),
    this.invalidationReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityFeedbackSamplesTableCompanion.insert({
    required String id,
    required String activityRecordId,
    required LifeDay lifeDay,
    required String samplingPolicyVersion,
    required ActivityFeedbackSampleStatus status,
    required DateTime selectedAt,
    this.promptedAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.feedbackId = const Value.absent(),
    this.invalidatedAt = const Value.absent(),
    this.invalidationReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activityRecordId = Value(activityRecordId),
       lifeDay = Value(lifeDay),
       samplingPolicyVersion = Value(samplingPolicyVersion),
       status = Value(status),
       selectedAt = Value(selectedAt);
  static Insertable<ActivityFeedbackSampleRow> custom({
    Expression<String>? id,
    Expression<String>? activityRecordId,
    Expression<String>? lifeDay,
    Expression<String>? samplingPolicyVersion,
    Expression<String>? status,
    Expression<DateTime>? selectedAt,
    Expression<DateTime>? promptedAt,
    Expression<DateTime>? respondedAt,
    Expression<String>? feedbackId,
    Expression<DateTime>? invalidatedAt,
    Expression<String>? invalidationReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityRecordId != null) 'activity_record_id': activityRecordId,
      if (lifeDay != null) 'life_day': lifeDay,
      if (samplingPolicyVersion != null)
        'sampling_policy_version': samplingPolicyVersion,
      if (status != null) 'status': status,
      if (selectedAt != null) 'selected_at': selectedAt,
      if (promptedAt != null) 'prompted_at': promptedAt,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (feedbackId != null) 'feedback_id': feedbackId,
      if (invalidatedAt != null) 'invalidated_at': invalidatedAt,
      if (invalidationReason != null) 'invalidation_reason': invalidationReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityFeedbackSamplesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? activityRecordId,
    Value<LifeDay>? lifeDay,
    Value<String>? samplingPolicyVersion,
    Value<ActivityFeedbackSampleStatus>? status,
    Value<DateTime>? selectedAt,
    Value<DateTime?>? promptedAt,
    Value<DateTime?>? respondedAt,
    Value<String?>? feedbackId,
    Value<DateTime?>? invalidatedAt,
    Value<ActivityFeedbackInvalidationReason?>? invalidationReason,
    Value<int>? rowid,
  }) {
    return ActivityFeedbackSamplesTableCompanion(
      id: id ?? this.id,
      activityRecordId: activityRecordId ?? this.activityRecordId,
      lifeDay: lifeDay ?? this.lifeDay,
      samplingPolicyVersion:
          samplingPolicyVersion ?? this.samplingPolicyVersion,
      status: status ?? this.status,
      selectedAt: selectedAt ?? this.selectedAt,
      promptedAt: promptedAt ?? this.promptedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      feedbackId: feedbackId ?? this.feedbackId,
      invalidatedAt: invalidatedAt ?? this.invalidatedAt,
      invalidationReason: invalidationReason ?? this.invalidationReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityRecordId.present) {
      map['activity_record_id'] = Variable<String>(activityRecordId.value);
    }
    if (lifeDay.present) {
      map['life_day'] = Variable<String>(
        $ActivityFeedbackSamplesTableTable.$converterlifeDay.toSql(
          lifeDay.value,
        ),
      );
    }
    if (samplingPolicyVersion.present) {
      map['sampling_policy_version'] = Variable<String>(
        samplingPolicyVersion.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ActivityFeedbackSamplesTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (selectedAt.present) {
      map['selected_at'] = Variable<DateTime>(selectedAt.value);
    }
    if (promptedAt.present) {
      map['prompted_at'] = Variable<DateTime>(promptedAt.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<DateTime>(respondedAt.value);
    }
    if (feedbackId.present) {
      map['feedback_id'] = Variable<String>(feedbackId.value);
    }
    if (invalidatedAt.present) {
      map['invalidated_at'] = Variable<DateTime>(invalidatedAt.value);
    }
    if (invalidationReason.present) {
      map['invalidation_reason'] = Variable<String>(
        $ActivityFeedbackSamplesTableTable.$converterinvalidationReasonn.toSql(
          invalidationReason.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityFeedbackSamplesTableCompanion(')
          ..write('id: $id, ')
          ..write('activityRecordId: $activityRecordId, ')
          ..write('lifeDay: $lifeDay, ')
          ..write('samplingPolicyVersion: $samplingPolicyVersion, ')
          ..write('status: $status, ')
          ..write('selectedAt: $selectedAt, ')
          ..write('promptedAt: $promptedAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('feedbackId: $feedbackId, ')
          ..write('invalidatedAt: $invalidatedAt, ')
          ..write('invalidationReason: $invalidationReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningConsentsTableTable extends LearningConsentsTable
    with TableInfo<$LearningConsentsTableTable, LearningConsentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningConsentsTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<LearningParameterFamily, String>
  parameterFamily =
      GeneratedColumn<String>(
        'parameter_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LearningParameterFamily>(
        $LearningConsentsTableTable.$converterparameterFamily,
      );
  static const VerificationMeta _disclosureVersionMeta = const VerificationMeta(
    'disclosureVersion',
  );
  @override
  late final GeneratedColumn<String> disclosureVersion =
      GeneratedColumn<String>(
        'disclosure_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
    'accepted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    parameterFamily,
    disclosureVersion,
    acceptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_consents';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningConsentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('disclosure_version')) {
      context.handle(
        _disclosureVersionMeta,
        disclosureVersion.isAcceptableOrUnknown(
          data['disclosure_version']!,
          _disclosureVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disclosureVersionMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acceptedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {parameterFamily, disclosureVersion};
  @override
  LearningConsentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningConsentRow(
      parameterFamily: $LearningConsentsTableTable.$converterparameterFamily
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}parameter_family'],
            )!,
          ),
      disclosureVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disclosure_version'],
      )!,
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accepted_at'],
      )!,
    );
  }

  @override
  $LearningConsentsTableTable createAlias(String alias) {
    return $LearningConsentsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LearningParameterFamily, String>
  $converterparameterFamily = const LearningParameterFamilyConverter();
}

class LearningConsentRow extends DataClass
    implements Insertable<LearningConsentRow> {
  final LearningParameterFamily parameterFamily;
  final String disclosureVersion;
  final DateTime acceptedAt;
  const LearningConsentRow({
    required this.parameterFamily,
    required this.disclosureVersion,
    required this.acceptedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['parameter_family'] = Variable<String>(
        $LearningConsentsTableTable.$converterparameterFamily.toSql(
          parameterFamily,
        ),
      );
    }
    map['disclosure_version'] = Variable<String>(disclosureVersion);
    map['accepted_at'] = Variable<DateTime>(acceptedAt);
    return map;
  }

  LearningConsentsTableCompanion toCompanion(bool nullToAbsent) {
    return LearningConsentsTableCompanion(
      parameterFamily: Value(parameterFamily),
      disclosureVersion: Value(disclosureVersion),
      acceptedAt: Value(acceptedAt),
    );
  }

  factory LearningConsentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningConsentRow(
      parameterFamily: serializer.fromJson<LearningParameterFamily>(
        json['parameterFamily'],
      ),
      disclosureVersion: serializer.fromJson<String>(json['disclosureVersion']),
      acceptedAt: serializer.fromJson<DateTime>(json['acceptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'parameterFamily': serializer.toJson<LearningParameterFamily>(
        parameterFamily,
      ),
      'disclosureVersion': serializer.toJson<String>(disclosureVersion),
      'acceptedAt': serializer.toJson<DateTime>(acceptedAt),
    };
  }

  LearningConsentRow copyWith({
    LearningParameterFamily? parameterFamily,
    String? disclosureVersion,
    DateTime? acceptedAt,
  }) => LearningConsentRow(
    parameterFamily: parameterFamily ?? this.parameterFamily,
    disclosureVersion: disclosureVersion ?? this.disclosureVersion,
    acceptedAt: acceptedAt ?? this.acceptedAt,
  );
  LearningConsentRow copyWithCompanion(LearningConsentsTableCompanion data) {
    return LearningConsentRow(
      parameterFamily: data.parameterFamily.present
          ? data.parameterFamily.value
          : this.parameterFamily,
      disclosureVersion: data.disclosureVersion.present
          ? data.disclosureVersion.value
          : this.disclosureVersion,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningConsentRow(')
          ..write('parameterFamily: $parameterFamily, ')
          ..write('disclosureVersion: $disclosureVersion, ')
          ..write('acceptedAt: $acceptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(parameterFamily, disclosureVersion, acceptedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningConsentRow &&
          other.parameterFamily == this.parameterFamily &&
          other.disclosureVersion == this.disclosureVersion &&
          other.acceptedAt == this.acceptedAt);
}

class LearningConsentsTableCompanion
    extends UpdateCompanion<LearningConsentRow> {
  final Value<LearningParameterFamily> parameterFamily;
  final Value<String> disclosureVersion;
  final Value<DateTime> acceptedAt;
  final Value<int> rowid;
  const LearningConsentsTableCompanion({
    this.parameterFamily = const Value.absent(),
    this.disclosureVersion = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningConsentsTableCompanion.insert({
    required LearningParameterFamily parameterFamily,
    required String disclosureVersion,
    required DateTime acceptedAt,
    this.rowid = const Value.absent(),
  }) : parameterFamily = Value(parameterFamily),
       disclosureVersion = Value(disclosureVersion),
       acceptedAt = Value(acceptedAt);
  static Insertable<LearningConsentRow> custom({
    Expression<String>? parameterFamily,
    Expression<String>? disclosureVersion,
    Expression<DateTime>? acceptedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (parameterFamily != null) 'parameter_family': parameterFamily,
      if (disclosureVersion != null) 'disclosure_version': disclosureVersion,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningConsentsTableCompanion copyWith({
    Value<LearningParameterFamily>? parameterFamily,
    Value<String>? disclosureVersion,
    Value<DateTime>? acceptedAt,
    Value<int>? rowid,
  }) {
    return LearningConsentsTableCompanion(
      parameterFamily: parameterFamily ?? this.parameterFamily,
      disclosureVersion: disclosureVersion ?? this.disclosureVersion,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (parameterFamily.present) {
      map['parameter_family'] = Variable<String>(
        $LearningConsentsTableTable.$converterparameterFamily.toSql(
          parameterFamily.value,
        ),
      );
    }
    if (disclosureVersion.present) {
      map['disclosure_version'] = Variable<String>(disclosureVersion.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningConsentsTableCompanion(')
          ..write('parameterFamily: $parameterFamily, ')
          ..write('disclosureVersion: $disclosureVersion, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningNoticesTableTable extends LearningNoticesTable
    with TableInfo<$LearningNoticesTableTable, LearningNoticeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningNoticesTableTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<LearningParameterFamily, String>
  parameterFamily =
      GeneratedColumn<String>(
        'parameter_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LearningParameterFamily>(
        $LearningNoticesTableTable.$converterparameterFamily,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LearningNoticeType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LearningNoticeType>(
        $LearningNoticesTableTable.$convertertype,
      );
  static const VerificationMeta _personalizationVersionIdMeta =
      const VerificationMeta('personalizationVersionId');
  @override
  late final GeneratedColumn<String> personalizationVersionId =
      GeneratedColumn<String>(
        'personalization_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _learningRunIdMeta = const VerificationMeta(
    'learningRunId',
  );
  @override
  late final GeneratedColumn<String> learningRunId = GeneratedColumn<String>(
    'learning_run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dedupKeyMeta = const VerificationMeta(
    'dedupKey',
  );
  @override
  late final GeneratedColumn<String> dedupKey = GeneratedColumn<String>(
    'dedup_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LearningNoticeStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LearningNoticeStatus>(
        $LearningNoticesTableTable.$converterstatus,
      );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
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
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<DateTime> seenAt = GeneratedColumn<DateTime>(
    'seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dismissedAtMeta = const VerificationMeta(
    'dismissedAt',
  );
  @override
  late final GeneratedColumn<DateTime> dismissedAt = GeneratedColumn<DateTime>(
    'dismissed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parameterFamily,
    type,
    personalizationVersionId,
    learningRunId,
    dedupKey,
    status,
    reasonCode,
    createdAt,
    seenAt,
    dismissedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_notices';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningNoticeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('personalization_version_id')) {
      context.handle(
        _personalizationVersionIdMeta,
        personalizationVersionId.isAcceptableOrUnknown(
          data['personalization_version_id']!,
          _personalizationVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('learning_run_id')) {
      context.handle(
        _learningRunIdMeta,
        learningRunId.isAcceptableOrUnknown(
          data['learning_run_id']!,
          _learningRunIdMeta,
        ),
      );
    }
    if (data.containsKey('dedup_key')) {
      context.handle(
        _dedupKeyMeta,
        dedupKey.isAcceptableOrUnknown(data['dedup_key']!, _dedupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dedupKeyMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    }
    if (data.containsKey('dismissed_at')) {
      context.handle(
        _dismissedAtMeta,
        dismissedAt.isAcceptableOrUnknown(
          data['dismissed_at']!,
          _dismissedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningNoticeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningNoticeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parameterFamily: $LearningNoticesTableTable.$converterparameterFamily
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}parameter_family'],
            )!,
          ),
      type: $LearningNoticesTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      personalizationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personalization_version_id'],
      ),
      learningRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_run_id'],
      ),
      dedupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedup_key'],
      )!,
      status: $LearningNoticesTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}seen_at'],
      ),
      dismissedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dismissed_at'],
      ),
    );
  }

  @override
  $LearningNoticesTableTable createAlias(String alias) {
    return $LearningNoticesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LearningParameterFamily, String>
  $converterparameterFamily = const LearningParameterFamilyConverter();
  static TypeConverter<LearningNoticeType, String> $convertertype =
      const LearningNoticeTypeConverter();
  static TypeConverter<LearningNoticeStatus, String> $converterstatus =
      const LearningNoticeStatusConverter();
}

class LearningNoticeRow extends DataClass
    implements Insertable<LearningNoticeRow> {
  final String id;
  final LearningParameterFamily parameterFamily;
  final LearningNoticeType type;
  final String? personalizationVersionId;
  final String? learningRunId;
  final String dedupKey;
  final LearningNoticeStatus status;
  final String reasonCode;
  final DateTime createdAt;
  final DateTime? seenAt;
  final DateTime? dismissedAt;
  const LearningNoticeRow({
    required this.id,
    required this.parameterFamily,
    required this.type,
    this.personalizationVersionId,
    this.learningRunId,
    required this.dedupKey,
    required this.status,
    required this.reasonCode,
    required this.createdAt,
    this.seenAt,
    this.dismissedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['parameter_family'] = Variable<String>(
        $LearningNoticesTableTable.$converterparameterFamily.toSql(
          parameterFamily,
        ),
      );
    }
    {
      map['type'] = Variable<String>(
        $LearningNoticesTableTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || personalizationVersionId != null) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId,
      );
    }
    if (!nullToAbsent || learningRunId != null) {
      map['learning_run_id'] = Variable<String>(learningRunId);
    }
    map['dedup_key'] = Variable<String>(dedupKey);
    {
      map['status'] = Variable<String>(
        $LearningNoticesTableTable.$converterstatus.toSql(status),
      );
    }
    map['reason_code'] = Variable<String>(reasonCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || seenAt != null) {
      map['seen_at'] = Variable<DateTime>(seenAt);
    }
    if (!nullToAbsent || dismissedAt != null) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt);
    }
    return map;
  }

  LearningNoticesTableCompanion toCompanion(bool nullToAbsent) {
    return LearningNoticesTableCompanion(
      id: Value(id),
      parameterFamily: Value(parameterFamily),
      type: Value(type),
      personalizationVersionId: personalizationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(personalizationVersionId),
      learningRunId: learningRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(learningRunId),
      dedupKey: Value(dedupKey),
      status: Value(status),
      reasonCode: Value(reasonCode),
      createdAt: Value(createdAt),
      seenAt: seenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(seenAt),
      dismissedAt: dismissedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dismissedAt),
    );
  }

  factory LearningNoticeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningNoticeRow(
      id: serializer.fromJson<String>(json['id']),
      parameterFamily: serializer.fromJson<LearningParameterFamily>(
        json['parameterFamily'],
      ),
      type: serializer.fromJson<LearningNoticeType>(json['type']),
      personalizationVersionId: serializer.fromJson<String?>(
        json['personalizationVersionId'],
      ),
      learningRunId: serializer.fromJson<String?>(json['learningRunId']),
      dedupKey: serializer.fromJson<String>(json['dedupKey']),
      status: serializer.fromJson<LearningNoticeStatus>(json['status']),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      seenAt: serializer.fromJson<DateTime?>(json['seenAt']),
      dismissedAt: serializer.fromJson<DateTime?>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parameterFamily': serializer.toJson<LearningParameterFamily>(
        parameterFamily,
      ),
      'type': serializer.toJson<LearningNoticeType>(type),
      'personalizationVersionId': serializer.toJson<String?>(
        personalizationVersionId,
      ),
      'learningRunId': serializer.toJson<String?>(learningRunId),
      'dedupKey': serializer.toJson<String>(dedupKey),
      'status': serializer.toJson<LearningNoticeStatus>(status),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'seenAt': serializer.toJson<DateTime?>(seenAt),
      'dismissedAt': serializer.toJson<DateTime?>(dismissedAt),
    };
  }

  LearningNoticeRow copyWith({
    String? id,
    LearningParameterFamily? parameterFamily,
    LearningNoticeType? type,
    Value<String?> personalizationVersionId = const Value.absent(),
    Value<String?> learningRunId = const Value.absent(),
    String? dedupKey,
    LearningNoticeStatus? status,
    String? reasonCode,
    DateTime? createdAt,
    Value<DateTime?> seenAt = const Value.absent(),
    Value<DateTime?> dismissedAt = const Value.absent(),
  }) => LearningNoticeRow(
    id: id ?? this.id,
    parameterFamily: parameterFamily ?? this.parameterFamily,
    type: type ?? this.type,
    personalizationVersionId: personalizationVersionId.present
        ? personalizationVersionId.value
        : this.personalizationVersionId,
    learningRunId: learningRunId.present
        ? learningRunId.value
        : this.learningRunId,
    dedupKey: dedupKey ?? this.dedupKey,
    status: status ?? this.status,
    reasonCode: reasonCode ?? this.reasonCode,
    createdAt: createdAt ?? this.createdAt,
    seenAt: seenAt.present ? seenAt.value : this.seenAt,
    dismissedAt: dismissedAt.present ? dismissedAt.value : this.dismissedAt,
  );
  LearningNoticeRow copyWithCompanion(LearningNoticesTableCompanion data) {
    return LearningNoticeRow(
      id: data.id.present ? data.id.value : this.id,
      parameterFamily: data.parameterFamily.present
          ? data.parameterFamily.value
          : this.parameterFamily,
      type: data.type.present ? data.type.value : this.type,
      personalizationVersionId: data.personalizationVersionId.present
          ? data.personalizationVersionId.value
          : this.personalizationVersionId,
      learningRunId: data.learningRunId.present
          ? data.learningRunId.value
          : this.learningRunId,
      dedupKey: data.dedupKey.present ? data.dedupKey.value : this.dedupKey,
      status: data.status.present ? data.status.value : this.status,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningNoticeRow(')
          ..write('id: $id, ')
          ..write('parameterFamily: $parameterFamily, ')
          ..write('type: $type, ')
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('learningRunId: $learningRunId, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('status: $status, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('seenAt: $seenAt, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parameterFamily,
    type,
    personalizationVersionId,
    learningRunId,
    dedupKey,
    status,
    reasonCode,
    createdAt,
    seenAt,
    dismissedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningNoticeRow &&
          other.id == this.id &&
          other.parameterFamily == this.parameterFamily &&
          other.type == this.type &&
          other.personalizationVersionId == this.personalizationVersionId &&
          other.learningRunId == this.learningRunId &&
          other.dedupKey == this.dedupKey &&
          other.status == this.status &&
          other.reasonCode == this.reasonCode &&
          other.createdAt == this.createdAt &&
          other.seenAt == this.seenAt &&
          other.dismissedAt == this.dismissedAt);
}

class LearningNoticesTableCompanion extends UpdateCompanion<LearningNoticeRow> {
  final Value<String> id;
  final Value<LearningParameterFamily> parameterFamily;
  final Value<LearningNoticeType> type;
  final Value<String?> personalizationVersionId;
  final Value<String?> learningRunId;
  final Value<String> dedupKey;
  final Value<LearningNoticeStatus> status;
  final Value<String> reasonCode;
  final Value<DateTime> createdAt;
  final Value<DateTime?> seenAt;
  final Value<DateTime?> dismissedAt;
  final Value<int> rowid;
  const LearningNoticesTableCompanion({
    this.id = const Value.absent(),
    this.parameterFamily = const Value.absent(),
    this.type = const Value.absent(),
    this.personalizationVersionId = const Value.absent(),
    this.learningRunId = const Value.absent(),
    this.dedupKey = const Value.absent(),
    this.status = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningNoticesTableCompanion.insert({
    required String id,
    required LearningParameterFamily parameterFamily,
    required LearningNoticeType type,
    this.personalizationVersionId = const Value.absent(),
    this.learningRunId = const Value.absent(),
    required String dedupKey,
    required LearningNoticeStatus status,
    required String reasonCode,
    required DateTime createdAt,
    this.seenAt = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       parameterFamily = Value(parameterFamily),
       type = Value(type),
       dedupKey = Value(dedupKey),
       status = Value(status),
       reasonCode = Value(reasonCode),
       createdAt = Value(createdAt);
  static Insertable<LearningNoticeRow> custom({
    Expression<String>? id,
    Expression<String>? parameterFamily,
    Expression<String>? type,
    Expression<String>? personalizationVersionId,
    Expression<String>? learningRunId,
    Expression<String>? dedupKey,
    Expression<String>? status,
    Expression<String>? reasonCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? seenAt,
    Expression<DateTime>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parameterFamily != null) 'parameter_family': parameterFamily,
      if (type != null) 'type': type,
      if (personalizationVersionId != null)
        'personalization_version_id': personalizationVersionId,
      if (learningRunId != null) 'learning_run_id': learningRunId,
      if (dedupKey != null) 'dedup_key': dedupKey,
      if (status != null) 'status': status,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (createdAt != null) 'created_at': createdAt,
      if (seenAt != null) 'seen_at': seenAt,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningNoticesTableCompanion copyWith({
    Value<String>? id,
    Value<LearningParameterFamily>? parameterFamily,
    Value<LearningNoticeType>? type,
    Value<String?>? personalizationVersionId,
    Value<String?>? learningRunId,
    Value<String>? dedupKey,
    Value<LearningNoticeStatus>? status,
    Value<String>? reasonCode,
    Value<DateTime>? createdAt,
    Value<DateTime?>? seenAt,
    Value<DateTime?>? dismissedAt,
    Value<int>? rowid,
  }) {
    return LearningNoticesTableCompanion(
      id: id ?? this.id,
      parameterFamily: parameterFamily ?? this.parameterFamily,
      type: type ?? this.type,
      personalizationVersionId:
          personalizationVersionId ?? this.personalizationVersionId,
      learningRunId: learningRunId ?? this.learningRunId,
      dedupKey: dedupKey ?? this.dedupKey,
      status: status ?? this.status,
      reasonCode: reasonCode ?? this.reasonCode,
      createdAt: createdAt ?? this.createdAt,
      seenAt: seenAt ?? this.seenAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parameterFamily.present) {
      map['parameter_family'] = Variable<String>(
        $LearningNoticesTableTable.$converterparameterFamily.toSql(
          parameterFamily.value,
        ),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $LearningNoticesTableTable.$convertertype.toSql(type.value),
      );
    }
    if (personalizationVersionId.present) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId.value,
      );
    }
    if (learningRunId.present) {
      map['learning_run_id'] = Variable<String>(learningRunId.value);
    }
    if (dedupKey.present) {
      map['dedup_key'] = Variable<String>(dedupKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $LearningNoticesTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<DateTime>(seenAt.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningNoticesTableCompanion(')
          ..write('id: $id, ')
          ..write('parameterFamily: $parameterFamily, ')
          ..write('type: $type, ')
          ..write('personalizationVersionId: $personalizationVersionId, ')
          ..write('learningRunId: $learningRunId, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('status: $status, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('seenAt: $seenAt, ')
          ..write('dismissedAt: $dismissedAt, ')
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
  @override
  late final GeneratedColumnWithTypeConverter<
    DailySummaryModelSnapshotSource,
    String
  >
  modelSnapshotSource =
      GeneratedColumn<String>(
        'model_snapshot_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DailySummaryModelSnapshotSource>(
        $DailySummariesTableTable.$convertermodelSnapshotSource,
      );
  static const VerificationMeta _personalizationVersionIdMeta =
      const VerificationMeta('personalizationVersionId');
  @override
  late final GeneratedColumn<String> personalizationVersionId =
      GeneratedColumn<String>(
        'personalization_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    modelSnapshotSource,
    personalizationVersionId,
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
    if (data.containsKey('personalization_version_id')) {
      context.handle(
        _personalizationVersionIdMeta,
        personalizationVersionId.isAcceptableOrUnknown(
          data['personalization_version_id']!,
          _personalizationVersionIdMeta,
        ),
      );
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
      modelSnapshotSource: $DailySummariesTableTable
          .$convertermodelSnapshotSource
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}model_snapshot_source'],
            )!,
          ),
      personalizationVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personalization_version_id'],
      ),
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
  static TypeConverter<DailySummaryModelSnapshotSource, String>
  $convertermodelSnapshotSource =
      const DailySummaryModelSnapshotSourceConverter();
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
  final DailySummaryModelSnapshotSource modelSnapshotSource;
  final String? personalizationVersionId;
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
    required this.modelSnapshotSource,
    this.personalizationVersionId,
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
    {
      map['model_snapshot_source'] = Variable<String>(
        $DailySummariesTableTable.$convertermodelSnapshotSource.toSql(
          modelSnapshotSource,
        ),
      );
    }
    if (!nullToAbsent || personalizationVersionId != null) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId,
      );
    }
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
      modelSnapshotSource: Value(modelSnapshotSource),
      personalizationVersionId: personalizationVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(personalizationVersionId),
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
      modelSnapshotSource: serializer.fromJson<DailySummaryModelSnapshotSource>(
        json['modelSnapshotSource'],
      ),
      personalizationVersionId: serializer.fromJson<String?>(
        json['personalizationVersionId'],
      ),
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
      'modelSnapshotSource': serializer.toJson<DailySummaryModelSnapshotSource>(
        modelSnapshotSource,
      ),
      'personalizationVersionId': serializer.toJson<String?>(
        personalizationVersionId,
      ),
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
    DailySummaryModelSnapshotSource? modelSnapshotSource,
    Value<String?> personalizationVersionId = const Value.absent(),
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
    modelSnapshotSource: modelSnapshotSource ?? this.modelSnapshotSource,
    personalizationVersionId: personalizationVersionId.present
        ? personalizationVersionId.value
        : this.personalizationVersionId,
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
      modelSnapshotSource: data.modelSnapshotSource.present
          ? data.modelSnapshotSource.value
          : this.modelSnapshotSource,
      personalizationVersionId: data.personalizationVersionId.present
          ? data.personalizationVersionId.value
          : this.personalizationVersionId,
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
          ..write('modelSnapshotSource: $modelSnapshotSource, ')
          ..write('personalizationVersionId: $personalizationVersionId, ')
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
    modelSnapshotSource,
    personalizationVersionId,
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
          other.modelSnapshotSource == this.modelSnapshotSource &&
          other.personalizationVersionId == this.personalizationVersionId &&
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
  final Value<DailySummaryModelSnapshotSource> modelSnapshotSource;
  final Value<String?> personalizationVersionId;
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
    this.modelSnapshotSource = const Value.absent(),
    this.personalizationVersionId = const Value.absent(),
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
    required DailySummaryModelSnapshotSource modelSnapshotSource,
    this.personalizationVersionId = const Value.absent(),
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
       modelSnapshotSource = Value(modelSnapshotSource),
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
    Expression<String>? modelSnapshotSource,
    Expression<String>? personalizationVersionId,
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
      if (modelSnapshotSource != null)
        'model_snapshot_source': modelSnapshotSource,
      if (personalizationVersionId != null)
        'personalization_version_id': personalizationVersionId,
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
    Value<DailySummaryModelSnapshotSource>? modelSnapshotSource,
    Value<String?>? personalizationVersionId,
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
      modelSnapshotSource: modelSnapshotSource ?? this.modelSnapshotSource,
      personalizationVersionId:
          personalizationVersionId ?? this.personalizationVersionId,
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
    if (modelSnapshotSource.present) {
      map['model_snapshot_source'] = Variable<String>(
        $DailySummariesTableTable.$convertermodelSnapshotSource.toSql(
          modelSnapshotSource.value,
        ),
      );
    }
    if (personalizationVersionId.present) {
      map['personalization_version_id'] = Variable<String>(
        personalizationVersionId.value,
      );
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
          ..write('modelSnapshotSource: $modelSnapshotSource, ')
          ..write('personalizationVersionId: $personalizationVersionId, ')
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
  late final $ActivityFeedbackTableTable activityFeedbackTable =
      $ActivityFeedbackTableTable(this);
  late final $LearningRunsTableTable learningRunsTable =
      $LearningRunsTableTable(this);
  late final $PersonalizationVersionsTableTable personalizationVersionsTable =
      $PersonalizationVersionsTableTable(this);
  late final $PersonalizationActivityFactorsTableTable
  personalizationActivityFactorsTable =
      $PersonalizationActivityFactorsTableTable(this);
  late final $ActivityFeedbackSamplesTableTable activityFeedbackSamplesTable =
      $ActivityFeedbackSamplesTableTable(this);
  late final $LearningConsentsTableTable learningConsentsTable =
      $LearningConsentsTableTable(this);
  late final $LearningNoticesTableTable learningNoticesTable =
      $LearningNoticesTableTable(this);
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
  late final Index energyObservationsContractLookup = Index(
    'energy_observations_contract_lookup',
    'CREATE INDEX energy_observations_contract_lookup ON energy_observations (life_day, type, contract_version)',
  );
  late final Index activityFeedbackActivityOrder = Index(
    'activity_feedback_activity_order',
    'CREATE INDEX activity_feedback_activity_order ON activity_feedback (activity_record_id, observed_at, id)',
  );
  late final Index activityFeedbackLifeDayStatus = Index(
    'activity_feedback_life_day_status',
    'CREATE INDEX activity_feedback_life_day_status ON activity_feedback (life_day, status, observed_at, id)',
  );
  late final Index personalizationActivityFactorsSource = Index(
    'personalization_activity_factors_source',
    'CREATE INDEX personalization_activity_factors_source ON personalization_activity_factors (source_learning_run_id)',
  );
  late final Index activityFeedbackSamplesActivityDay = Index(
    'activity_feedback_samples_activity_day',
    'CREATE INDEX activity_feedback_samples_activity_day ON activity_feedback_samples (activity_record_id, life_day, selected_at)',
  );
  late final Index learningRunsIdempotency = Index(
    'learning_runs_idempotency',
    'CREATE UNIQUE INDEX learning_runs_idempotency ON learning_runs (parameter_family, source_model_identity, algorithm_version, config_version, evidence_hash)',
  );
  late final Index learningRunsSourceTime = Index(
    'learning_runs_source_time',
    'CREATE INDEX learning_runs_source_time ON learning_runs (parameter_family, source_model_identity, triggered_at, id)',
  );
  late final Index learningRunsStatusTime = Index(
    'learning_runs_status_time',
    'CREATE INDEX learning_runs_status_time ON learning_runs (status, triggered_at, id)',
  );
  late final Index personalizationVersionsParent = Index(
    'personalization_versions_parent',
    'CREATE INDEX personalization_versions_parent ON personalization_versions (parent_version_id)',
  );
  late final Index personalizationVersionsStatusTime = Index(
    'personalization_versions_status_time',
    'CREATE INDEX personalization_versions_status_time ON personalization_versions (status, created_at, id)',
  );
  late final Index learningNoticesStatusTime = Index(
    'learning_notices_status_time',
    'CREATE INDEX learning_notices_status_time ON learning_notices (status, created_at, id)',
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
  late final ActivityFeedbackDao activityFeedbackDao = ActivityFeedbackDao(
    this as AppDatabase,
  );
  late final PersonalizationActivityFactorsDao
  personalizationActivityFactorsDao = PersonalizationActivityFactorsDao(
    this as AppDatabase,
  );
  late final ActivityFeedbackSamplesDao activityFeedbackSamplesDao =
      ActivityFeedbackSamplesDao(this as AppDatabase);
  late final LearningRunsDao learningRunsDao = LearningRunsDao(
    this as AppDatabase,
  );
  late final PersonalizationVersionsDao personalizationVersionsDao =
      PersonalizationVersionsDao(this as AppDatabase);
  late final LearningConsentsDao learningConsentsDao = LearningConsentsDao(
    this as AppDatabase,
  );
  late final LearningNoticesDao learningNoticesDao = LearningNoticesDao(
    this as AppDatabase,
  );
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
    activityFeedbackTable,
    learningRunsTable,
    personalizationVersionsTable,
    personalizationActivityFactorsTable,
    activityFeedbackSamplesTable,
    learningConsentsTable,
    learningNoticesTable,
    dailySummariesTable,
    promptReceiptsTable,
    activityRecordsLifeDayOrder,
    energyObservationsLifeDayTime,
    energyObservationsContractLookup,
    activityFeedbackActivityOrder,
    activityFeedbackLifeDayStatus,
    personalizationActivityFactorsSource,
    activityFeedbackSamplesActivityDay,
    learningRunsIdempotency,
    learningRunsSourceTime,
    learningRunsStatusTime,
    personalizationVersionsParent,
    personalizationVersionsStatusTime,
    learningNoticesStatusTime,
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
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $EnergyObservationsTableTable get energyObservationsTable =>
      attachedDatabase.energyObservationsTable;
}
mixin _$ActivityFeedbackDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $ActivityRecordsTableTable get activityRecordsTable =>
      attachedDatabase.activityRecordsTable;
  $ActivityFeedbackTableTable get activityFeedbackTable =>
      attachedDatabase.activityFeedbackTable;
}
mixin _$PersonalizationActivityFactorsDaoMixin
    on DatabaseAccessor<AppDatabase> {
  $LearningRunsTableTable get learningRunsTable =>
      attachedDatabase.learningRunsTable;
  $PersonalizationVersionsTableTable get personalizationVersionsTable =>
      attachedDatabase.personalizationVersionsTable;
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $PersonalizationActivityFactorsTableTable
  get personalizationActivityFactorsTable =>
      attachedDatabase.personalizationActivityFactorsTable;
}
mixin _$ActivityFeedbackSamplesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $ActivityRecordsTableTable get activityRecordsTable =>
      attachedDatabase.activityRecordsTable;
  $ActivityFeedbackSamplesTableTable get activityFeedbackSamplesTable =>
      attachedDatabase.activityFeedbackSamplesTable;
}
mixin _$LearningRunsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningRunsTableTable get learningRunsTable =>
      attachedDatabase.learningRunsTable;
}
mixin _$PersonalizationVersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningRunsTableTable get learningRunsTable =>
      attachedDatabase.learningRunsTable;
  $PersonalizationVersionsTableTable get personalizationVersionsTable =>
      attachedDatabase.personalizationVersionsTable;
}
mixin _$LearningConsentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningConsentsTableTable get learningConsentsTable =>
      attachedDatabase.learningConsentsTable;
}
mixin _$LearningNoticesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningRunsTableTable get learningRunsTable =>
      attachedDatabase.learningRunsTable;
  $PersonalizationVersionsTableTable get personalizationVersionsTable =>
      attachedDatabase.personalizationVersionsTable;
  $LearningNoticesTableTable get learningNoticesTable =>
      attachedDatabase.learningNoticesTable;
}
mixin _$DailySummariesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RuleConfigVersionsTableTable get ruleConfigVersionsTable =>
      attachedDatabase.ruleConfigVersionsTable;
  $LearningRunsTableTable get learningRunsTable =>
      attachedDatabase.learningRunsTable;
  $PersonalizationVersionsTableTable get personalizationVersionsTable =>
      attachedDatabase.personalizationVersionsTable;
  $DailySummariesTableTable get dailySummariesTable =>
      attachedDatabase.dailySummariesTable;
}
mixin _$PromptReceiptsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromptReceiptsTableTable get promptReceiptsTable =>
      attachedDatabase.promptReceiptsTable;
}
