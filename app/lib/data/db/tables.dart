part of 'app_database.dart';

@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get baseEstimatedEnergy =>
      integer().named('base_energy').withDefault(const Constant(100))();
  IntColumn get pendingBaseEstimatedEnergy =>
      integer().named('pending_base_energy').nullable()();
  TextColumn get baseEnergyEffectiveLifeDay => text()
      .named('base_energy_effective_life_day')
      .map(const LifeDayConverter())
      .nullable()();
  TextColumn get activeRuleVersion => text().named('active_rule_version')();
  TextColumn get pendingRuleVersion =>
      text().named('pending_rule_version').nullable()();
  BoolColumn get onboardingCompleted => boolean()
      .named('onboarding_completed')
      .withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (id = 1)',
    'CHECK (base_energy BETWEEN 60 AND 140)',
    'CHECK (pending_base_energy IS NULL OR pending_base_energy BETWEEN 60 AND 140)',
    'CHECK ((pending_base_energy IS NULL AND base_energy_effective_life_day IS NULL) OR (pending_base_energy IS NOT NULL AND base_energy_effective_life_day IS NOT NULL))',
    'FOREIGN KEY (active_rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY (pending_rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
}

@DataClassName('RuleConfigVersionRow')
class RuleConfigVersionsTable extends Table {
  @override
  String get tableName => 'rule_config_versions';

  TextColumn get version => text()();
  TextColumn get valuesJson => text().named('values_json')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {version};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(version)) > 0)",
    'CHECK (json_valid(values_json))',
  ];
}

@DataClassName('MorningCheckInRow')
class MorningCheckInsTable extends Table {
  @override
  String get tableName => 'morning_check_ins';

  TextColumn get id => text()();
  TextColumn get lifeDay =>
      text().named('life_day').unique().map(const LifeDayConverter())();
  TextColumn get overallState =>
      text().named('overall_state').map(const MorningOverallStateConverter())();
  TextColumn get freeTimeLevel =>
      text().named('free_time_level').map(const FreeTimeLevelConverter())();
  TextColumn get pressureSource =>
      text().named('pressure_source').map(const PressureSourceConverter())();
  TextColumn get sleepRecovery =>
      text().named('sleep_recovery').map(const SleepRecoveryConverter())();
  IntColumn get morningAdjustment => integer().named('morning_adjustment')();
  DateTimeColumn get completedAt => dateTime().named('completed_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (overall_state IN ('bad', 'normal', 'good'))",
    "CHECK (free_time_level IN ('low', 'medium', 'high'))",
    "CHECK (pressure_source IN ('study', 'practice', 'both', 'low'))",
    "CHECK (sleep_recovery IN ('bad', 'normal', 'good'))",
    "CHECK ((overall_state = 'bad' AND morning_adjustment = -6) OR (overall_state = 'normal' AND morning_adjustment = 0) OR (overall_state = 'good' AND morning_adjustment = 6))",
  ];
}

@DataClassName('ActivityRecordRow')
@TableIndex(
  name: 'activity_records_life_day_order',
  columns: {#lifeDay, #completedAt, #createdAt, #id},
)
class ActivityRecordsTable extends Table {
  @override
  String get tableName => 'activity_records';

  TextColumn get id => text()();
  TextColumn get lifeDay =>
      text().named('life_day').map(const LifeDayConverter())();
  DateTimeColumn get completedAt => dateTime().named('completed_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  TextColumn get category => text().map(const ActivityCategoryConverter())();
  TextColumn get subcategory =>
      text().map(const ActivitySubcategoryConverter())();
  IntColumn get duration =>
      integer().named('duration_minutes').map(const DurationSlotConverter())();
  IntColumn get theoreticalDelta => integer().named('theoretical_delta')();
  IntColumn get appliedDelta => integer().named('applied_delta')();
  TextColumn get ruleVersion => text().named('rule_version')();
  TextColumn get status => text().map(const ActivityRecordStatusConverter())();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    'CHECK (duration_minutes IN (15, 30, 45, 60, 90, 120))',
    "CHECK (status IN ('active', 'deleted'))",
    "CHECK ((status = 'active' AND deleted_at IS NULL) OR (status = 'deleted' AND deleted_at IS NOT NULL))",
    "CHECK ((category = 'study' AND subcategory IN ('classAttendance', 'selfStudyOrThesis', 'homework', 'reviewOrExamPrep', 'organizeOrSummarize', 'otherStudy')) OR (category = 'practice' AND subcategory IN ('implementationOrDevelopment', 'experiment', 'projectProgress', 'debuggingOrRevision', 'organizationOrAdministration', 'otherPractice')) OR (category = 'recovery' AND subcategory IN ('nap', 'lightActivity', 'mentalReset', 'exerciseRecovery', 'lifeMaintenance', 'otherRecovery')) OR (category = 'leisure' AND subcategory IN ('gaming', 'shortVideo', 'seriesOrMovie', 'chatOrSocial', 'hobbyEntertainment', 'otherLeisure')))",
    'FOREIGN KEY (rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
}

@DataClassName('EnergyObservationRow')
@TableIndex(
  name: 'energy_observations_life_day_time',
  columns: {#lifeDay, #observedAt, #id},
)
class EnergyObservationsTable extends Table {
  @override
  String get tableName => 'energy_observations';

  TextColumn get id => text()();
  TextColumn get lifeDay =>
      text().named('life_day').map(const LifeDayConverter())();
  TextColumn get type => text().map(const EnergyObservationTypeConverter())();
  TextColumn get absoluteState => text()
      .named('absolute_state')
      .map(const AbsoluteEnergyStateConverter())
      .nullable()();
  TextColumn get relativeState => text()
      .named('relative_state')
      .map(const RelativeCorrectionConverter())
      .nullable()();
  IntColumn get estimateAtObservation =>
      integer().named('estimate_at_observation').nullable()();
  DateTimeColumn get observedAt => dateTime().named('observed_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (type IN ('dailyAbsolute', 'relativeCorrection'))",
    "CHECK (absolute_state IS NULL OR absolute_state IN ('exhausted', 'low', 'okay', 'good', 'full'))",
    "CHECK (relative_state IS NULL OR relative_state IN ('lower', 'aboutRight', 'higher'))",
    "CHECK ((type = 'dailyAbsolute' AND absolute_state IS NOT NULL AND relative_state IS NULL) OR (type = 'relativeCorrection' AND absolute_state IS NULL AND relative_state IS NOT NULL AND estimate_at_observation IS NOT NULL))",
  ];
}

@DataClassName('DailySummaryRow')
class DailySummariesTable extends Table {
  @override
  String get tableName => 'daily_summaries';

  TextColumn get lifeDay =>
      text().named('life_day').map(const LifeDayConverter())();
  IntColumn get baseEstimatedEnergy => integer().named('base_energy')();
  TextColumn get ruleVersion => text().named('rule_version')();
  IntColumn get morningAdjustment => integer().named('morning_adjustment')();
  IntColumn get shortTermAdjustment =>
      integer().named('short_term_adjustment')();
  IntColumn get initialEstimatedEnergy =>
      integer().named('initial_estimated_energy')();
  IntColumn get finalEstimatedEnergy =>
      integer().named('final_estimated_energy')();
  IntColumn get totalConsumption => integer().named('total_consumption')();
  IntColumn get totalRecovery => integer().named('total_recovery')();
  TextColumn get categorySummaryJson => text().named('category_summary_json')();
  BoolColumn get isStandardEffectiveDay =>
      boolean().named('is_standard_effective_day')();
  BoolColumn get isWeakEffectiveDay =>
      boolean().named('is_weak_effective_day')();
  DateTimeColumn get settledAt => dateTime().named('settled_at')();

  @override
  Set<Column> get primaryKey => {lifeDay};

  @override
  List<String> get customConstraints => const [
    'CHECK (base_energy BETWEEN 60 AND 140)',
    'CHECK (morning_adjustment IN (-6, 0, 6))',
    'CHECK (short_term_adjustment BETWEEN -4 AND 0)',
    'CHECK (total_consumption >= 0)',
    'CHECK (total_recovery >= 0)',
    'CHECK (json_valid(category_summary_json))',
    'CHECK (NOT (is_standard_effective_day = 1 AND is_weak_effective_day = 1))',
    'FOREIGN KEY (rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
}

@DataClassName('PromptReceiptRow')
class PromptReceiptsTable extends Table {
  @override
  String get tableName => 'prompt_receipts';

  TextColumn get id => text()();
  TextColumn get type => text().map(const PromptReceiptTypeConverter())();
  TextColumn get scopeKey => text().named('scope_key')();
  TextColumn get action => text().map(const PromptReceiptActionConverter())();
  DateTimeColumn get occurredAt => dateTime().named('occurred_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {type, scopeKey, action},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (length(trim(scope_key)) > 0)",
    "CHECK (type IN ('onboarding', 'morning', 'dailyObservation', 'yesterday', 'energyBand'))",
    "CHECK (\"action\" IN ('shown', 'skipped', 'dismissed'))",
  ];
}
