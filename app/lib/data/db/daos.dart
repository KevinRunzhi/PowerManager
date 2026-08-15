part of 'app_database.dart';

@DriftAccessor(tables: [AppSettingsTable])
final class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.attachedDatabase);

  Future<AppSettingsRow> getSettings() => select(appSettingsTable).getSingle();

  Future<int> updateSettings(AppSettingsTableCompanion changes) {
    return (update(
      appSettingsTable,
    )..where((row) => row.id.equals(1))).write(changes);
  }
}

@DriftAccessor(tables: [PersonalizationVersionsTable])
final class PersonalizationVersionsDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalizationVersionsDaoMixin {
  PersonalizationVersionsDao(super.attachedDatabase);

  Future<void> insertVersion(
    PersonalizationVersionsTableCompanion version,
  ) async {
    await into(personalizationVersionsTable).insert(version);
  }

  Future<PersonalizationVersionRow?> findById(String id) {
    return (select(
      personalizationVersionsTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<PersonalizationVersionRow> getActive() {
    return (select(personalizationVersionsTable)..where(
          (row) => row.status.equalsValue(PersonalizationVersionStatus.active),
        ))
        .getSingle();
  }

  Future<PersonalizationVersionRow?> findPending() {
    const statuses = {
      PersonalizationVersionStatus.candidate,
      PersonalizationVersionStatus.awaitingReview,
      PersonalizationVersionStatus.deferred,
      PersonalizationVersionStatus.scheduled,
    };
    return (select(
      personalizationVersionsTable,
    )..where((row) => row.status.isInValues(statuses))).getSingleOrNull();
  }

  Future<List<PersonalizationVersionRow>> listAll() {
    return (select(personalizationVersionsTable)..orderBy([
          (row) => OrderingTerm.asc(row.createdAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }

  Future<int> updateById(
    String id,
    PersonalizationVersionsTableCompanion changes,
  ) {
    return (update(
      personalizationVersionsTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }

  Future<int> updateByIdAndStatus(
    String id,
    PersonalizationVersionStatus expectedStatus,
    PersonalizationVersionsTableCompanion changes,
  ) {
    return (update(personalizationVersionsTable)..where(
          (row) => row.id.equals(id) & row.status.equalsValue(expectedStatus),
        ))
        .write(changes);
  }
}

@DriftAccessor(tables: [LearningConsentsTable])
final class LearningConsentsDao extends DatabaseAccessor<AppDatabase>
    with _$LearningConsentsDaoMixin {
  LearningConsentsDao(super.attachedDatabase);

  Future<void> insertConsent(LearningConsentsTableCompanion consent) async {
    await into(
      learningConsentsTable,
    ).insert(consent, mode: InsertMode.insertOrIgnore);
  }

  Future<bool> exists({
    required LearningParameterFamily parameterFamily,
    required String disclosureVersion,
  }) async {
    final row =
        await (select(learningConsentsTable)
              ..where(
                (row) =>
                    row.parameterFamily.equalsValue(parameterFamily) &
                    row.disclosureVersion.equals(disclosureVersion),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<List<LearningConsentRow>> listAll() {
    return (select(learningConsentsTable)..orderBy([
          (row) => OrderingTerm.asc(row.parameterFamily),
          (row) => OrderingTerm.asc(row.disclosureVersion),
        ]))
        .get();
  }
}

@DriftAccessor(tables: [LearningNoticesTable])
final class LearningNoticesDao extends DatabaseAccessor<AppDatabase>
    with _$LearningNoticesDaoMixin {
  LearningNoticesDao(super.attachedDatabase);

  Future<void> insertNotice(LearningNoticesTableCompanion notice) async {
    await into(learningNoticesTable).insert(notice);
  }

  Future<LearningNoticeRow?> findById(String id) {
    return (select(
      learningNoticesTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<List<LearningNoticeRow>> listAll() {
    return (select(learningNoticesTable)..orderBy([
          (row) => OrderingTerm.asc(row.createdAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }

  Future<int> updateById(String id, LearningNoticesTableCompanion changes) {
    return (update(
      learningNoticesTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }
}

@DriftAccessor(tables: [RuleConfigVersionsTable])
final class RuleConfigVersionsDao extends DatabaseAccessor<AppDatabase>
    with _$RuleConfigVersionsDaoMixin {
  RuleConfigVersionsDao(super.attachedDatabase);

  Future<void> insertVersion(RuleConfigVersionsTableCompanion version) async {
    await into(ruleConfigVersionsTable).insert(version);
  }

  Future<RuleConfigVersionRow?> findVersion(String version) {
    return (select(
      ruleConfigVersionsTable,
    )..where((row) => row.version.equals(version))).getSingleOrNull();
  }

  Future<List<RuleConfigVersionRow>> listVersions() {
    return (select(
      ruleConfigVersionsTable,
    )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();
  }
}

@DriftAccessor(tables: [MorningCheckInsTable])
final class MorningCheckInsDao extends DatabaseAccessor<AppDatabase>
    with _$MorningCheckInsDaoMixin {
  MorningCheckInsDao(super.attachedDatabase);

  Future<void> insertCheckIn(MorningCheckInsTableCompanion checkIn) async {
    await into(morningCheckInsTable).insert(checkIn);
  }

  Future<MorningCheckInRow?> findByLifeDay(LifeDay lifeDay) {
    return (select(
      morningCheckInsTable,
    )..where((row) => row.lifeDay.equalsValue(lifeDay))).getSingleOrNull();
  }

  Future<List<MorningCheckInRow>> listAll() {
    return (select(
      morningCheckInsTable,
    )..orderBy([(row) => OrderingTerm.asc(row.lifeDay)])).get();
  }

  Future<int> updateById(String id, MorningCheckInsTableCompanion changes) {
    return (update(
      morningCheckInsTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }

  Future<int> deleteById(String id) {
    return (delete(
      morningCheckInsTable,
    )..where((row) => row.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [ActivityRecordsTable])
final class ActivityRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityRecordsDaoMixin {
  ActivityRecordsDao(super.attachedDatabase);

  Future<void> insertRecord(ActivityRecordsTableCompanion record) async {
    await into(activityRecordsTable).insert(record);
  }

  Future<ActivityRecordRow?> findById(String id) {
    return (select(
      activityRecordsTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<List<ActivityRecordRow>> listActiveForLifeDay(LifeDay lifeDay) {
    return (select(activityRecordsTable)
          ..where(
            (row) =>
                row.lifeDay.equalsValue(lifeDay) &
                row.status.equalsValue(ActivityRecordStatus.active),
          )
          ..orderBy([
            (row) => OrderingTerm.asc(row.completedAt),
            (row) => OrderingTerm.asc(row.createdAt),
            (row) => OrderingTerm.asc(row.id),
          ]))
        .get();
  }

  Future<List<ActivityRecordRow>> listAllForLifeDay(LifeDay lifeDay) {
    return (select(activityRecordsTable)
          ..where((row) => row.lifeDay.equalsValue(lifeDay))
          ..orderBy([
            (row) => OrderingTerm.asc(row.completedAt),
            (row) => OrderingTerm.asc(row.createdAt),
            (row) => OrderingTerm.asc(row.id),
          ]))
        .get();
  }

  Future<List<ActivityRecordRow>> listAllForExport() {
    return (select(activityRecordsTable)..orderBy([
          (row) => OrderingTerm.asc(row.lifeDay),
          (row) => OrderingTerm.asc(row.completedAt),
          (row) => OrderingTerm.asc(row.createdAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }

  Future<int> updateById(String id, ActivityRecordsTableCompanion changes) {
    return (update(
      activityRecordsTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }
}

@DriftAccessor(tables: [EnergyObservationsTable])
final class EnergyObservationsDao extends DatabaseAccessor<AppDatabase>
    with _$EnergyObservationsDaoMixin {
  EnergyObservationsDao(super.attachedDatabase);

  Future<void> insertObservation(
    EnergyObservationsTableCompanion observation,
  ) async {
    await into(energyObservationsTable).insert(observation);
  }

  Future<EnergyObservationRow?> findById(String id) {
    return (select(
      energyObservationsTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<int> updateById(String id, EnergyObservationsTableCompanion changes) {
    return (update(
      energyObservationsTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }

  Future<List<EnergyObservationRow>> listForLifeDay(LifeDay lifeDay) {
    return (select(energyObservationsTable)
          ..where((row) => row.lifeDay.equalsValue(lifeDay))
          ..orderBy([
            (row) => OrderingTerm.asc(row.observedAt),
            (row) => OrderingTerm.asc(row.id),
          ]))
        .get();
  }

  Future<List<EnergyObservationRow>> listAll() {
    return (select(energyObservationsTable)..orderBy([
          (row) => OrderingTerm.asc(row.lifeDay),
          (row) => OrderingTerm.asc(row.observedAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }
}

@DriftAccessor(tables: [ActivityFeedbackTable])
final class ActivityFeedbackDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityFeedbackDaoMixin {
  ActivityFeedbackDao(super.attachedDatabase);

  Future<void> insertFeedback(ActivityFeedbackTableCompanion feedback) async {
    await into(activityFeedbackTable).insert(feedback);
  }

  Future<ActivityFeedbackRow?> findById(String id) {
    return (select(
      activityFeedbackTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<ActivityFeedbackRow?> findActiveForActivity(String activityRecordId) {
    return (select(activityFeedbackTable)..where(
          (row) =>
              row.activityRecordId.equals(activityRecordId) &
              row.status.equalsValue(ActivityFeedbackStatus.active),
        ))
        .getSingleOrNull();
  }

  Future<List<ActivityFeedbackRow>> listForActivity(String activityRecordId) {
    return (select(activityFeedbackTable)
          ..where((row) => row.activityRecordId.equals(activityRecordId))
          ..orderBy([
            (row) => OrderingTerm.asc(row.observedAt),
            (row) => OrderingTerm.asc(row.id),
          ]))
        .get();
  }

  Future<List<ActivityFeedbackRow>> listAll() {
    return (select(activityFeedbackTable)..orderBy([
          (row) => OrderingTerm.asc(row.lifeDay),
          (row) => OrderingTerm.asc(row.observedAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }

  Future<int> updateById(String id, ActivityFeedbackTableCompanion changes) {
    return (update(
      activityFeedbackTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }
}

@DriftAccessor(tables: [PersonalizationActivityFactorsTable])
final class PersonalizationActivityFactorsDao
    extends DatabaseAccessor<AppDatabase>
    with _$PersonalizationActivityFactorsDaoMixin {
  PersonalizationActivityFactorsDao(super.attachedDatabase);

  Future<void> insertFactor(
    PersonalizationActivityFactorsTableCompanion factor,
  ) => into(personalizationActivityFactorsTable).insert(factor);

  Future<PersonalizationActivityFactorRow?> findByKey({
    required String personalizationVersionId,
    required ActivitySubcategory subcategory,
    required ActivityImpactSign impactSign,
  }) {
    return (select(personalizationActivityFactorsTable)..where(
          (row) =>
              row.personalizationVersionId.equals(personalizationVersionId) &
              row.subcategory.equalsValue(subcategory) &
              row.impactSign.equalsValue(impactSign),
        ))
        .getSingleOrNull();
  }

  Future<List<PersonalizationActivityFactorRow>> listForVersion(
    String personalizationVersionId,
  ) {
    return (select(personalizationActivityFactorsTable)
          ..where(
            (row) =>
                row.personalizationVersionId.equals(personalizationVersionId),
          )
          ..orderBy([
            (row) => OrderingTerm.asc(row.subcategory),
            (row) => OrderingTerm.asc(row.impactSign),
          ]))
        .get();
  }

  Future<List<PersonalizationActivityFactorRow>> listAll() {
    return (select(personalizationActivityFactorsTable)..orderBy([
          (row) => OrderingTerm.asc(row.personalizationVersionId),
          (row) => OrderingTerm.asc(row.subcategory),
          (row) => OrderingTerm.asc(row.impactSign),
        ]))
        .get();
  }

  Future<int> updateByKey(
    String personalizationVersionId,
    ActivitySubcategory subcategory,
    ActivityImpactSign impactSign,
    PersonalizationActivityFactorsTableCompanion changes,
  ) {
    return (update(personalizationActivityFactorsTable)..where(
          (row) =>
              row.personalizationVersionId.equals(personalizationVersionId) &
              row.subcategory.equalsValue(subcategory) &
              row.impactSign.equalsValue(impactSign),
        ))
        .write(changes);
  }
}

@DriftAccessor(tables: [ActivityFeedbackSamplesTable])
final class ActivityFeedbackSamplesDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityFeedbackSamplesDaoMixin {
  ActivityFeedbackSamplesDao(super.attachedDatabase);

  Future<void> insertSample(ActivityFeedbackSamplesTableCompanion sample) =>
      into(activityFeedbackSamplesTable).insert(sample);

  Future<ActivityFeedbackSampleRow?> findById(String id) {
    return (select(
      activityFeedbackSamplesTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<ActivityFeedbackSampleRow?> findActiveForActivityPolicy({
    required String activityRecordId,
    required String samplingPolicyVersion,
  }) {
    return (select(activityFeedbackSamplesTable)..where(
          (row) =>
              row.activityRecordId.equals(activityRecordId) &
              row.samplingPolicyVersion.equals(samplingPolicyVersion) &
              row.status
                  .equalsValue(ActivityFeedbackSampleStatus.invalidated)
                  .not(),
        ))
        .getSingleOrNull();
  }

  Future<List<ActivityFeedbackSampleRow>> listAll() {
    return (select(activityFeedbackSamplesTable)..orderBy([
          (row) => OrderingTerm.asc(row.lifeDay),
          (row) => OrderingTerm.asc(row.selectedAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }

  Future<int> updateById(
    String id,
    ActivityFeedbackSamplesTableCompanion changes,
  ) {
    return (update(
      activityFeedbackSamplesTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }
}

@DriftAccessor(tables: [LearningRunsTable])
final class LearningRunsDao extends DatabaseAccessor<AppDatabase>
    with _$LearningRunsDaoMixin {
  LearningRunsDao(super.attachedDatabase);

  Future<void> insertRun(LearningRunsTableCompanion run) async {
    await into(learningRunsTable).insert(run);
  }

  Future<LearningRunRow?> findById(String id) {
    return (select(
      learningRunsTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<LearningRunRow?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) {
    return (select(learningRunsTable)..where(
          (row) =>
              row.parameterFamily.equalsValue(parameterFamily) &
              row.sourceModelIdentity.equals(sourceModelIdentity) &
              row.algorithmVersion.equals(algorithmVersion) &
              row.configVersion.equals(configVersion) &
              row.evidenceHash.equals(evidenceHash),
        ))
        .getSingleOrNull();
  }

  Future<List<LearningRunRow>> listAll() {
    return (select(learningRunsTable)..orderBy([
          (row) => OrderingTerm.asc(row.triggeredAt),
          (row) => OrderingTerm.asc(row.id),
        ]))
        .get();
  }

  Future<int> updateById(String id, LearningRunsTableCompanion changes) {
    return (update(
      learningRunsTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }
}

@DriftAccessor(tables: [DailySummariesTable])
final class DailySummariesDao extends DatabaseAccessor<AppDatabase>
    with _$DailySummariesDaoMixin {
  DailySummariesDao(super.attachedDatabase);

  Future<DailySummaryRow> insertOrGet(DailySummariesTableCompanion summary) {
    return attachedDatabase.transaction(() async {
      await into(
        dailySummariesTable,
      ).insert(summary, mode: InsertMode.insertOrIgnore);
      final lifeDay = summary.lifeDay.value;
      return (select(
        dailySummariesTable,
      )..where((row) => row.lifeDay.equalsValue(lifeDay))).getSingle();
    });
  }

  Future<DailySummaryRow?> findByLifeDay(LifeDay lifeDay) {
    return (select(
      dailySummariesTable,
    )..where((row) => row.lifeDay.equalsValue(lifeDay))).getSingleOrNull();
  }

  Future<List<DailySummaryRow>> listAll() {
    return (select(
      dailySummariesTable,
    )..orderBy([(row) => OrderingTerm.asc(row.lifeDay)])).get();
  }
}

@DriftAccessor(tables: [PromptReceiptsTable])
final class PromptReceiptsDao extends DatabaseAccessor<AppDatabase>
    with _$PromptReceiptsDaoMixin {
  PromptReceiptsDao(super.attachedDatabase);

  Future<void> insertReceipt(PromptReceiptsTableCompanion receipt) async {
    await into(promptReceiptsTable).insert(receipt);
  }

  Future<bool> exists({
    required PromptReceiptType type,
    required String scopeKey,
    required PromptReceiptAction action,
  }) async {
    final row =
        await (select(promptReceiptsTable)
              ..where(
                (row) =>
                    row.type.equalsValue(type) &
                    row.scopeKey.equals(scopeKey) &
                    row.action.equalsValue(action),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<List<PromptReceiptRow>> listAll() {
    return (select(
      promptReceiptsTable,
    )..orderBy([(row) => OrderingTerm.asc(row.occurredAt)])).get();
  }
}
