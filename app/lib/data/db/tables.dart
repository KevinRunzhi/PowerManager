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
  TextColumn get pendingRuleEffectiveLifeDay => text()
      .named('pending_rule_effective_life_day')
      .map(const LifeDayConverter())
      .nullable()();
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
    'CHECK ((pending_rule_version IS NULL AND pending_rule_effective_life_day IS NULL) OR (pending_rule_version IS NOT NULL AND pending_rule_effective_life_day IS NOT NULL))',
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
@TableIndex(
  name: 'energy_observations_contract_lookup',
  columns: {#lifeDay, #type, #contractVersion},
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
  TextColumn get contractVersion =>
      text().named('contract_version').nullable()();
  TextColumn get referenceType => text()
      .named('reference_type')
      .map(const ObservationReferenceTypeConverter())
      .nullable()();
  IntColumn get initialEstimateAtObservation =>
      integer().named('initial_estimate_at_observation').nullable()();
  IntColumn get estimatedOrdinalAtObservation =>
      integer().named('estimated_ordinal_at_observation').nullable()();
  IntColumn get baseEnergyAtObservation =>
      integer().named('base_energy_at_observation').nullable()();
  TextColumn get ruleVersionAtObservation =>
      text().named('rule_version_at_observation').nullable()();
  TextColumn get comparisonBandVersion =>
      text().named('comparison_band_version').nullable()();
  TextColumn get personalizationVersionAtObservation =>
      text().named('personalization_version_at_observation').nullable()();
  TextColumn get effectiveModelFingerprintAtObservation =>
      text().named('effective_model_fingerprint_at_observation').nullable()();
  TextColumn get modelRegimeEpochAtObservation =>
      text().named('model_regime_epoch_at_observation').nullable()();
  IntColumn get activeActivityCountAtObservation =>
      integer().named('active_activity_count_at_observation').nullable()();
  TextColumn get coverageState => text()
      .named('coverage_state')
      .map(const ObservationCoverageStateConverter())
      .nullable()();
  TextColumn get modelRegimeKey =>
      text().named('model_regime_key').nullable()();
  DateTimeColumn get observedAt => dateTime().named('observed_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (type IN ('dailyAbsolute', 'relativeCorrection'))",
    "CHECK (absolute_state IS NULL OR absolute_state IN ('exhausted', 'low', 'okay', 'good', 'full'))",
    "CHECK (relative_state IS NULL OR relative_state IN ('lower', 'aboutRight', 'higher'))",
    "CHECK (contract_version IS NULL OR contract_version = 'mvp-b-observation-v1')",
    "CHECK (reference_type IS NULL OR reference_type IN ('currentMoment', 'previousLifeDayEnd'))",
    'CHECK (initial_estimate_at_observation IS NULL OR initial_estimate_at_observation > 0)',
    'CHECK (estimated_ordinal_at_observation IS NULL OR estimated_ordinal_at_observation BETWEEN 0 AND 4)',
    'CHECK (base_energy_at_observation IS NULL OR base_energy_at_observation BETWEEN 60 AND 140)',
    'CHECK (active_activity_count_at_observation IS NULL OR active_activity_count_at_observation >= 0)',
    "CHECK (coverage_state IS NULL OR coverage_state IN ('confirmed', 'uncertain', 'legacyUnknown'))",
    "CHECK (rule_version_at_observation IS NULL OR length(trim(rule_version_at_observation)) > 0)",
    "CHECK (comparison_band_version IS NULL OR length(trim(comparison_band_version)) > 0)",
    "CHECK (personalization_version_at_observation IS NULL OR length(trim(personalization_version_at_observation)) > 0)",
    "CHECK (effective_model_fingerprint_at_observation IS NULL OR length(trim(effective_model_fingerprint_at_observation)) > 0)",
    "CHECK (model_regime_epoch_at_observation IS NULL OR length(trim(model_regime_epoch_at_observation)) > 0)",
    "CHECK (model_regime_key IS NULL OR length(trim(model_regime_key)) > 0)",
    "CHECK ((type = 'dailyAbsolute' AND absolute_state IS NOT NULL AND relative_state IS NULL AND (((contract_version IS NULL) AND reference_type IS NULL AND initial_estimate_at_observation IS NULL AND estimated_ordinal_at_observation IS NULL AND base_energy_at_observation IS NULL AND rule_version_at_observation IS NULL AND comparison_band_version IS NULL AND personalization_version_at_observation IS NULL AND effective_model_fingerprint_at_observation IS NULL AND model_regime_epoch_at_observation IS NULL AND active_activity_count_at_observation IS NULL AND (coverage_state IS NULL OR coverage_state = 'legacyUnknown') AND model_regime_key IS NULL) OR (contract_version = 'mvp-b-observation-v1' AND estimate_at_observation IS NOT NULL AND reference_type IS NOT NULL AND initial_estimate_at_observation IS NOT NULL AND estimated_ordinal_at_observation IS NOT NULL AND base_energy_at_observation IS NOT NULL AND rule_version_at_observation IS NOT NULL AND comparison_band_version IS NOT NULL AND personalization_version_at_observation IS NOT NULL AND effective_model_fingerprint_at_observation IS NOT NULL AND model_regime_epoch_at_observation IS NOT NULL AND active_activity_count_at_observation IS NOT NULL AND coverage_state IN ('confirmed', 'uncertain') AND model_regime_key IS NOT NULL))) OR (type = 'relativeCorrection' AND absolute_state IS NULL AND relative_state IS NOT NULL AND estimate_at_observation IS NOT NULL AND contract_version IS NULL AND reference_type IS NULL AND initial_estimate_at_observation IS NULL AND estimated_ordinal_at_observation IS NULL AND base_energy_at_observation IS NULL AND rule_version_at_observation IS NULL AND comparison_band_version IS NULL AND personalization_version_at_observation IS NULL AND effective_model_fingerprint_at_observation IS NULL AND model_regime_epoch_at_observation IS NULL AND active_activity_count_at_observation IS NULL AND (coverage_state IS NULL OR coverage_state = 'legacyUnknown') AND model_regime_key IS NULL))",
    'FOREIGN KEY (rule_version_at_observation) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
}

@DataClassName('ActivityFeedbackRow')
@TableIndex(
  name: 'activity_feedback_activity_order',
  columns: {#activityRecordId, #observedAt, #id},
)
@TableIndex(
  name: 'activity_feedback_life_day_status',
  columns: {#lifeDay, #status, #observedAt, #id},
)
class ActivityFeedbackTable extends Table {
  @override
  String get tableName => 'activity_feedback';

  TextColumn get id => text()();
  TextColumn get activityRecordId => text().named('activity_record_id')();
  TextColumn get lifeDay =>
      text().named('life_day').map(const LifeDayConverter())();
  TextColumn get subcategorySnapshot => text()
      .named('subcategory_snapshot')
      .map(const ActivitySubcategoryConverter())();
  IntColumn get durationSnapshot => integer()
      .named('duration_minutes_snapshot')
      .map(const DurationSlotConverter())();
  IntColumn get theoreticalDeltaSnapshot =>
      integer().named('theoretical_delta_snapshot')();
  IntColumn get appliedDeltaSnapshot =>
      integer().named('applied_delta_snapshot')();
  TextColumn get impactSignSnapshot => text()
      .named('impact_sign_snapshot')
      .map(const ActivityImpactSignConverter())();
  TextColumn get ruleVersionSnapshot => text().named('rule_version_snapshot')();
  DateTimeColumn get activityUpdatedAtSnapshot =>
      dateTime().named('activity_updated_at_snapshot')();
  TextColumn get direction =>
      text().map(const ActivityFeedbackDirectionConverter())();
  TextColumn get status =>
      text().map(const ActivityFeedbackStatusConverter())();
  TextColumn get invalidationReason => text()
      .named('invalidation_reason')
      .map(const ActivityFeedbackInvalidationReasonConverter())
      .nullable()();
  DateTimeColumn get observedAt => dateTime().named('observed_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (length(trim(activity_record_id)) > 0)",
    "CHECK (subcategory_snapshot IN ('classAttendance', 'selfStudyOrThesis', 'homework', 'reviewOrExamPrep', 'organizeOrSummarize', 'otherStudy', 'implementationOrDevelopment', 'experiment', 'projectProgress', 'debuggingOrRevision', 'organizationOrAdministration', 'otherPractice', 'nap', 'lightActivity', 'mentalReset', 'exerciseRecovery', 'lifeMaintenance', 'otherRecovery', 'gaming', 'shortVideo', 'seriesOrMovie', 'chatOrSocial', 'hobbyEntertainment', 'otherLeisure'))",
    'CHECK (duration_minutes_snapshot IN (15, 30, 45, 60, 90, 120))',
    "CHECK (impact_sign_snapshot IN ('consumption', 'recovery', 'zero'))",
    "CHECK ((impact_sign_snapshot = 'consumption' AND theoretical_delta_snapshot < 0) OR (impact_sign_snapshot = 'recovery' AND theoretical_delta_snapshot > 0) OR (impact_sign_snapshot = 'zero' AND theoretical_delta_snapshot = 0))",
    "CHECK (length(trim(rule_version_snapshot)) > 0)",
    "CHECK (direction IN ('strongerImpact', 'aboutRight', 'weakerImpact', 'directionMismatch'))",
    "CHECK (status IN ('active', 'invalidated'))",
    "CHECK (invalidation_reason IS NULL OR invalidation_reason IN ('activityDeleted', 'activityEdited', 'integrityFailure'))",
    "CHECK ((status = 'active' AND invalidation_reason IS NULL) OR (status = 'invalidated' AND invalidation_reason IS NOT NULL))",
    'FOREIGN KEY (activity_record_id) REFERENCES activity_records(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY (rule_version_snapshot) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
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
