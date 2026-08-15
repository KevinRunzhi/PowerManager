part of 'app_database.dart';

@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
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
  TextColumn get baselineLearningMode => text()
      .named('baseline_learning_mode')
      .map(const LearningModeConverter())
      .withDefault(const Constant('off'))();
  TextColumn get activityImpactLearningMode => text()
      .named('activity_impact_learning_mode')
      .map(const LearningModeConverter())
      .withDefault(const Constant('off'))();
  BoolColumn get baselineLearningSuspended => boolean()
      .named('baseline_learning_suspended')
      .withDefault(const Constant(false))();
  DateTimeColumn get baselineLearningSuspendedAt =>
      dateTime().named('baseline_learning_suspended_at').nullable()();
  TextColumn get baselineLearningSuspensionReason =>
      text().named('baseline_learning_suspension_reason').nullable()();
  BoolColumn get activityImpactLearningSuspended => boolean()
      .named('activity_impact_learning_suspended')
      .withDefault(const Constant(false))();
  DateTimeColumn get activityImpactLearningSuspendedAt =>
      dateTime().named('activity_impact_learning_suspended_at').nullable()();
  TextColumn get activityImpactLearningSuspensionReason =>
      text().named('activity_impact_learning_suspension_reason').nullable()();
  DateTimeColumn get baselineLearningCooldownUntil =>
      dateTime().named('baseline_learning_cooldown_until').nullable()();
  DateTimeColumn get activityImpactLearningCooldownUntil =>
      dateTime().named('activity_impact_learning_cooldown_until').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (id = 1)',
    "CHECK (baseline_learning_mode IN ('off', 'review', 'automatic'))",
    "CHECK (activity_impact_learning_mode IN ('off', 'review', 'automatic'))",
    "CHECK ((baseline_learning_suspended = 0 AND baseline_learning_suspended_at IS NULL AND baseline_learning_suspension_reason IS NULL) OR (baseline_learning_suspended = 1 AND baseline_learning_suspended_at IS NOT NULL AND length(trim(baseline_learning_suspension_reason)) > 0))",
    "CHECK ((activity_impact_learning_suspended = 0 AND activity_impact_learning_suspended_at IS NULL AND activity_impact_learning_suspension_reason IS NULL) OR (activity_impact_learning_suspended = 1 AND activity_impact_learning_suspended_at IS NOT NULL AND length(trim(activity_impact_learning_suspension_reason)) > 0))",
    'CHECK ((pending_rule_version IS NULL AND pending_rule_effective_life_day IS NULL) OR (pending_rule_version IS NOT NULL AND pending_rule_effective_life_day IS NOT NULL))',
    'FOREIGN KEY (active_rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY (pending_rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
}

@DataClassName('PersonalizationVersionRow')
@TableIndex(
  name: 'personalization_versions_parent',
  columns: {#parentVersionId},
)
@TableIndex(
  name: 'personalization_versions_status_time',
  columns: {#status, #createdAt, #id},
)
class PersonalizationVersionsTable extends Table {
  @override
  String get tableName => 'personalization_versions';

  TextColumn get id => text()();
  TextColumn get parentVersionId =>
      text().named('parent_version_id').nullable()();
  TextColumn get effectiveModelFingerprint =>
      text().named('effective_model_fingerprint')();
  TextColumn get modelRegimeEpoch =>
      text().named('model_regime_epoch').unique()();
  TextColumn get creationSource => text()
      .named('creation_source')
      .map(const PersonalizationCreationSourceConverter())();
  TextColumn get scheduleSource => text()
      .named('schedule_source')
      .map(const PersonalizationScheduleSourceConverter())
      .nullable()();
  TextColumn get sourceLearningRunId =>
      text().named('source_learning_run_id').nullable()();
  TextColumn get algorithmVersion => text().named('algorithm_version')();
  TextColumn get configVersion => text().named('config_version')();
  TextColumn get changedParameterFamily => text()
      .named('changed_parameter_family')
      .map(const PersonalizationChangedParameterFamilyConverter())();
  IntColumn get baseEnergy => integer().named('base_energy')();
  IntColumn get baselineAnchorEnergy =>
      integer().named('baseline_anchor_energy')();
  TextColumn get status =>
      text().map(const PersonalizationVersionStatusConverter())();
  TextColumn get effectiveLifeDay => text()
      .named('effective_life_day')
      .map(const LifeDayConverter())
      .nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get activatedAt =>
      dateTime().named('activated_at').nullable()();
  DateTimeColumn get endedAt => dateTime().named('ended_at').nullable()();
  TextColumn get transitionReason => text().named('transition_reason')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceLearningRunId},
  ];

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (parent_version_id IS NULL OR length(trim(parent_version_id)) > 0)",
    "CHECK (length(trim(effective_model_fingerprint)) > 0)",
    "CHECK (length(trim(model_regime_epoch)) > 0)",
    "CHECK (creation_source IN ('initial', 'learningRun', 'manual', 'legacyManualPending', 'revert'))",
    "CHECK (schedule_source IS NULL OR schedule_source IN ('automatic', 'reviewAccepted', 'manual', 'legacyManualPending', 'revert'))",
    "CHECK (source_learning_run_id IS NULL OR length(trim(source_learning_run_id)) > 0)",
    "CHECK (length(trim(algorithm_version)) > 0)",
    "CHECK (length(trim(config_version)) > 0)",
    "CHECK (changed_parameter_family IN ('none', 'baseline', 'activityImpact'))",
    'CHECK (base_energy BETWEEN 60 AND 140)',
    'CHECK (baseline_anchor_energy BETWEEN 60 AND 140)',
    "CHECK (status IN ('candidate', 'awaitingReview', 'deferred', 'scheduled', 'active', 'superseded', 'rejected', 'reverted', 'canceled', 'invalidated'))",
    "CHECK (length(trim(transition_reason)) > 0)",
    "CHECK ((creation_source = 'initial' AND parent_version_id IS NULL AND schedule_source IS NULL AND source_learning_run_id IS NULL AND changed_parameter_family = 'none') OR (creation_source != 'initial' AND parent_version_id IS NOT NULL AND changed_parameter_family != 'none'))",
    "CHECK ((creation_source = 'learningRun' AND source_learning_run_id IS NOT NULL) OR (creation_source != 'learningRun' AND source_learning_run_id IS NULL))",
    "CHECK ((status IN ('candidate', 'awaitingReview', 'deferred') AND effective_life_day IS NULL AND activated_at IS NULL AND ended_at IS NULL) OR (status = 'scheduled' AND schedule_source IS NOT NULL AND effective_life_day IS NOT NULL AND activated_at IS NULL AND ended_at IS NULL) OR (status = 'active' AND activated_at IS NOT NULL AND ended_at IS NULL AND (creation_source = 'initial' OR effective_life_day IS NOT NULL)) OR (status IN ('superseded', 'reverted') AND activated_at IS NOT NULL AND ended_at IS NOT NULL AND (creation_source = 'initial' OR effective_life_day IS NOT NULL)) OR (status IN ('rejected', 'canceled', 'invalidated') AND activated_at IS NULL AND ended_at IS NOT NULL))",
    'FOREIGN KEY (parent_version_id) REFERENCES personalization_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY (source_learning_run_id) REFERENCES learning_runs(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
}

@DataClassName('LearningConsentRow')
class LearningConsentsTable extends Table {
  @override
  String get tableName => 'learning_consents';

  TextColumn get parameterFamily => text()
      .named('parameter_family')
      .map(const LearningParameterFamilyConverter())();
  TextColumn get disclosureVersion => text().named('disclosure_version')();
  DateTimeColumn get acceptedAt => dateTime().named('accepted_at')();

  @override
  Set<Column> get primaryKey => {parameterFamily, disclosureVersion};

  @override
  List<String> get customConstraints => const [
    "CHECK (parameter_family IN ('baseline', 'activityImpact'))",
    "CHECK (length(trim(disclosure_version)) > 0)",
  ];
}

@DataClassName('LearningNoticeRow')
@TableIndex(
  name: 'learning_notices_status_time',
  columns: {#status, #createdAt, #id},
)
class LearningNoticesTable extends Table {
  @override
  String get tableName => 'learning_notices';

  TextColumn get id => text()();
  TextColumn get parameterFamily => text()
      .named('parameter_family')
      .map(const LearningParameterFamilyConverter())();
  TextColumn get type => text().map(const LearningNoticeTypeConverter())();
  TextColumn get personalizationVersionId =>
      text().named('personalization_version_id').nullable()();
  TextColumn get learningRunId =>
      text().named('learning_run_id').nullable()();
  TextColumn get dedupKey => text().named('dedup_key').unique()();
  TextColumn get status =>
      text().map(const LearningNoticeStatusConverter())();
  TextColumn get reasonCode => text().named('reason_code')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get seenAt => dateTime().named('seen_at').nullable()();
  DateTimeColumn get dismissedAt =>
      dateTime().named('dismissed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (parameter_family IN ('baseline', 'activityImpact'))",
    "CHECK (type IN ('candidateAvailable', 'changeScheduled', 'changeActivated', 'learningSuspended', 'changeCanceled', 'changeReverted'))",
    "CHECK (length(trim(dedup_key)) > 0)",
    "CHECK (status IN ('unseen', 'seen', 'dismissed'))",
    "CHECK (length(trim(reason_code)) > 0)",
    "CHECK ((status = 'unseen' AND seen_at IS NULL AND dismissed_at IS NULL) OR (status = 'seen' AND seen_at IS NOT NULL AND dismissed_at IS NULL) OR (status = 'dismissed' AND seen_at IS NOT NULL AND dismissed_at IS NOT NULL))",
    "CHECK ((type IN ('candidateAvailable', 'changeScheduled', 'changeActivated', 'changeCanceled', 'changeReverted') AND personalization_version_id IS NOT NULL) OR type = 'learningSuspended')",
    'FOREIGN KEY (personalization_version_id) REFERENCES personalization_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY (learning_run_id) REFERENCES learning_runs(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
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

@DataClassName('LearningRunRow')
@TableIndex(
  name: 'learning_runs_idempotency',
  columns: {
    #parameterFamily,
    #sourceModelIdentity,
    #algorithmVersion,
    #configVersion,
    #evidenceHash,
  },
  unique: true,
)
@TableIndex(
  name: 'learning_runs_source_time',
  columns: {#parameterFamily, #sourceModelIdentity, #triggeredAt, #id},
)
@TableIndex(
  name: 'learning_runs_status_time',
  columns: {#status, #triggeredAt, #id},
)
class LearningRunsTable extends Table {
  @override
  String get tableName => 'learning_runs';

  TextColumn get id => text()();
  TextColumn get parameterFamily => text()
      .named('parameter_family')
      .map(const LearningParameterFamilyConverter())();
  TextColumn get sourceModelIdentity => text().named('source_model_identity')();
  TextColumn get sourcePersonalizationVersionId =>
      text().named('source_personalization_version_id').nullable()();
  TextColumn get status => text().map(const LearningRunStatusConverter())();
  TextColumn get result =>
      text().map(const LearningRunResultConverter()).nullable()();
  TextColumn get evidenceSnapshotJson =>
      text().named('evidence_snapshot_json')();
  TextColumn get evidenceHash => text().named('evidence_hash')();
  TextColumn get evidenceHashVersion => text().named('evidence_hash_version')();
  TextColumn get algorithmVersion => text().named('algorithm_version')();
  TextColumn get configVersion => text().named('config_version')();
  TextColumn get currentValuesJson => text().named('current_values_json')();
  TextColumn get candidateValuesJson =>
      text().named('candidate_values_json').nullable()();
  TextColumn get reasonCodesJson => text().named('reason_codes_json')();
  DateTimeColumn get triggeredAt => dateTime().named('triggered_at')();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (length(trim(id)) > 0)",
    "CHECK (parameter_family IN ('baseline', 'activityImpact'))",
    "CHECK (length(trim(source_model_identity)) > 0)",
    "CHECK (status IN ('pending', 'running', 'completed', 'retryableFailure', 'terminalFailure'))",
    "CHECK (result IS NULL OR result IN ('insufficientEvidence', 'readyForAudit', 'unstable', 'noChange', 'candidate', 'configurationBlocked', 'improved', 'worsened'))",
    "CHECK (json_valid(evidence_snapshot_json) AND json_type(evidence_snapshot_json) = 'object')",
    "CHECK (length(evidence_hash) = 64 AND evidence_hash = lower(evidence_hash) AND evidence_hash NOT GLOB '*[^0-9a-f]*')",
    "CHECK (length(trim(evidence_hash_version)) > 0)",
    "CHECK (length(trim(algorithm_version)) > 0)",
    "CHECK (length(trim(config_version)) > 0)",
    "CHECK (json_valid(current_values_json) AND json_type(current_values_json) = 'object')",
    "CHECK (json_type(current_values_json, '\$.baseEnergy') = 'integer' AND json_extract(current_values_json, '\$.baseEnergy') BETWEEN 60 AND 140)",
    "CHECK (current_values_json = json_object('baseEnergy', json_extract(current_values_json, '\$.baseEnergy')))",
    "CHECK ((result = 'candidate' AND parameter_family = 'baseline' AND status = 'completed' AND candidate_values_json IS NOT NULL AND json_valid(candidate_values_json) AND json_type(candidate_values_json) = 'object' AND json_type(candidate_values_json, '\$.baseEnergy') = 'integer' AND json_extract(candidate_values_json, '\$.baseEnergy') BETWEEN 60 AND 140 AND candidate_values_json = json_object('baseEnergy', json_extract(candidate_values_json, '\$.baseEnergy'))) OR (result IS NULL OR result != 'candidate') AND candidate_values_json IS NULL)",
    "CHECK (json_valid(reason_codes_json) AND json_type(reason_codes_json) = 'array')",
    "CHECK (((status IN ('pending', 'running')) AND result IS NULL AND completed_at IS NULL) OR (status = 'completed' AND result IS NOT NULL AND completed_at IS NOT NULL) OR (status IN ('retryableFailure', 'terminalFailure') AND result IS NULL AND completed_at IS NOT NULL))",
    "CHECK ((algorithm_version = 'evidence-shadow-v1' AND source_personalization_version_id IS NULL AND candidate_values_json IS NULL) OR (algorithm_version != 'evidence-shadow-v1' AND source_personalization_version_id IS NOT NULL))",
    'FOREIGN KEY (source_personalization_version_id) REFERENCES personalization_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
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
  TextColumn get modelSnapshotSource => text()
      .named('model_snapshot_source')
      .map(const DailySummaryModelSnapshotSourceConverter())();
  TextColumn get personalizationVersionId =>
      text().named('personalization_version_id').nullable()();
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
    "CHECK ((model_snapshot_source = 'legacyInline' AND personalization_version_id IS NULL) OR (model_snapshot_source = 'personalizationVersion' AND personalization_version_id IS NOT NULL))",
    'FOREIGN KEY (rule_version) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY (personalization_version_id) REFERENCES personalization_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT',
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
