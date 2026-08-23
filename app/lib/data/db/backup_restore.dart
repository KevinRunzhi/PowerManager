part of 'app_database.dart';

typedef RestoreFailureHook = Future<void> Function(String checkpoint);

extension BackupRestoreDatabase on AppDatabase {
  Future<void> replaceWithBackup(
    PowerManagerExportDto backup, {
    RestoreFailureHook? failureHook,
  }) {
    return transaction(() async {
      await customStatement('PRAGMA defer_foreign_keys = ON');
      await _dropProtectionTriggers();
      try {
        await _clearBusinessTables();
        await failureHook?.call('after-clear');
        await _insertBackup(backup, failureHook: failureHook);
        await _createProtectionTriggers();
        await _verifyBackup(backup);
      } finally {
        await _createProtectionTriggers();
      }
    });
  }

  Future<void> _dropProtectionTriggers() async {
    for (final name in _protectionTriggerNames) {
      await customStatement('DROP TRIGGER IF EXISTS $name');
    }
  }

  Future<void> _clearBusinessTables() async {
    await delete(learningNoticesTable).go();
    await delete(learningConsentsTable).go();
    await delete(promptReceiptsTable).go();
    await delete(energyObservationsTable).go();
    await delete(morningCheckInsTable).go();
    await delete(activityFeedbackSamplesTable).go();
    await delete(activityFeedbackTable).go();
    await delete(activityRecordsTable).go();
    await delete(personalizationActivityFactorsTable).go();
    await delete(dailySummariesTable).go();
    await delete(appSettingsTable).go();
    await delete(personalizationVersionsTable).go();
    await delete(learningRunsTable).go();
    await delete(ruleConfigVersionsTable).go();
  }

  Future<void> _insertBackup(
    PowerManagerExportDto backup, {
    RestoreFailureHook? failureHook,
  }) async {
    for (final version in backup.ruleVersions) {
      await into(ruleConfigVersionsTable).insert(
        RuleConfigVersionsTableCompanion.insert(
          version: version.version,
          valuesJson: jsonEncode(version.values),
          createdAt: version.createdAt.toUtc(),
        ),
      );
    }
    final settings = backup.appSettings;
    await into(appSettingsTable).insert(
      AppSettingsTableCompanion.insert(
        id: const Value(1),
        activeRuleVersion: settings.activeRuleVersion,
        pendingRuleVersion: Value(settings.pendingRuleVersion),
        pendingRuleEffectiveLifeDay: Value(
          settings.pendingRuleEffectiveLifeDay,
        ),
        onboardingCompleted: Value(settings.onboardingCompleted),
        baselineLearningMode: Value(settings.baselineLearningMode),
        activityImpactLearningMode: Value(settings.activityImpactLearningMode),
        baselineLearningSuspended: Value(settings.baselineLearningSuspended),
        baselineLearningSuspendedAt: Value(
          settings.baselineLearningSuspendedAt?.toUtc(),
        ),
        baselineLearningSuspensionReason: Value(
          settings.baselineLearningSuspensionReason,
        ),
        activityImpactLearningSuspended: Value(
          settings.activityImpactLearningSuspended,
        ),
        activityImpactLearningSuspendedAt: Value(
          settings.activityImpactLearningSuspendedAt?.toUtc(),
        ),
        activityImpactLearningSuspensionReason: Value(
          settings.activityImpactLearningSuspensionReason,
        ),
        baselineLearningCooldownUntil: Value(
          settings.baselineLearningCooldownUntil?.toUtc(),
        ),
        activityImpactLearningCooldownUntil: Value(
          settings.activityImpactLearningCooldownUntil?.toUtc(),
        ),
        createdAt: settings.createdAt.toUtc(),
        updatedAt: settings.updatedAt.toUtc(),
      ),
    );
    await failureHook?.call('after-settings');

    for (final morning in backup.morningCheckIns) {
      await into(morningCheckInsTable).insert(
        MorningCheckInsTableCompanion.insert(
          id: morning.id,
          lifeDay: morning.lifeDay,
          overallState: morning.overallState,
          freeTimeLevel: morning.freeTimeLevel,
          pressureSource: morning.pressureSource,
          sleepRecovery: morning.sleepRecovery,
          morningAdjustment: morning.morningAdjustment,
          completedAt: morning.completedAt.toUtc(),
        ),
      );
    }
    for (final activity in backup.activityRecords) {
      await into(activityRecordsTable).insert(
        ActivityRecordsTableCompanion.insert(
          id: activity.id,
          lifeDay: activity.lifeDay,
          completedAt: activity.completedAt.toUtc(),
          createdAt: activity.createdAt.toUtc(),
          updatedAt: activity.updatedAt.toUtc(),
          category: activity.category,
          subcategory: activity.subcategory,
          duration: activity.duration,
          theoreticalDelta: activity.theoreticalDelta,
          appliedDelta: activity.appliedDelta,
          defaultTheoreticalDelta: Value(activity.defaultTheoreticalDelta),
          factor: Value(activity.factor),
          personalizedTheoreticalDelta: Value(
            activity.personalizedTheoreticalDelta,
          ),
          personalizationVersionId: Value(activity.personalizationVersionId),
          factorRegimeStartedLifeDay: Value(
            activity.factorRegimeStartedLifeDay,
          ),
          ruleVersion: activity.ruleVersion,
          status: activity.status,
          deletedAt: Value(activity.deletedAt?.toUtc()),
        ),
      );
    }
    await failureHook?.call('after-activities');

    for (final feedback in backup.activityFeedback) {
      await into(activityFeedbackTable).insert(
        ActivityFeedbackTableCompanion.insert(
          id: feedback.id,
          activityRecordId: feedback.activityRecordId,
          lifeDay: feedback.lifeDay,
          subcategorySnapshot: feedback.subcategorySnapshot,
          durationSnapshot: feedback.durationSnapshot,
          theoreticalDeltaSnapshot: feedback.theoreticalDeltaSnapshot,
          appliedDeltaSnapshot: feedback.appliedDeltaSnapshot,
          impactSignSnapshot: feedback.impactSignSnapshot,
          ruleVersionSnapshot: feedback.ruleVersionSnapshot,
          activityUpdatedAtSnapshot: feedback.activityUpdatedAtSnapshot.toUtc(),
          direction: feedback.direction,
          status: feedback.status,
          invalidationReason: Value(feedback.invalidationReason),
          defaultTheoreticalDeltaSnapshot: Value(
            feedback.defaultTheoreticalDeltaSnapshot,
          ),
          factorSnapshot: Value(feedback.factorSnapshot),
          personalizedTheoreticalDeltaSnapshot: Value(
            feedback.personalizedTheoreticalDeltaSnapshot,
          ),
          personalizationVersionId: Value(feedback.personalizationVersionId),
          factorRegimeStartedLifeDay: Value(
            feedback.factorRegimeStartedLifeDay,
          ),
          collectionSource: Value(feedback.collectionSource),
          samplingPolicyVersion: Value(feedback.samplingPolicyVersion),
          sampledAt: Value(feedback.sampledAt?.toUtc()),
          sampleId: Value(feedback.sampleId),
          observedAt: feedback.observedAt.toUtc(),
        ),
      );
    }
    await failureHook?.call('after-feedback');

    for (final sample in backup.activityFeedbackSamples) {
      await into(activityFeedbackSamplesTable).insert(
        ActivityFeedbackSamplesTableCompanion.insert(
          id: sample.id,
          activityRecordId: sample.activityRecordId,
          lifeDay: sample.lifeDay,
          samplingPolicyVersion: sample.samplingPolicyVersion,
          status: sample.status,
          selectedAt: sample.selectedAt.toUtc(),
          promptedAt: Value(sample.promptedAt?.toUtc()),
          respondedAt: Value(sample.respondedAt?.toUtc()),
          feedbackId: Value(sample.feedbackId),
          invalidatedAt: Value(sample.invalidatedAt?.toUtc()),
          invalidationReason: Value(sample.invalidationReason),
        ),
      );
    }

    for (final observation in backup.energyObservations) {
      await into(energyObservationsTable).insert(
        EnergyObservationsTableCompanion.insert(
          id: observation.id,
          lifeDay: observation.lifeDay,
          type: observation.type,
          absoluteState: Value(observation.absoluteState),
          relativeState: Value(observation.relativeState),
          estimateAtObservation: Value(observation.estimateAtObservation),
          contractVersion: Value(observation.contractVersion),
          referenceType: Value(observation.referenceType),
          initialEstimateAtObservation: Value(
            observation.initialEstimateAtObservation,
          ),
          estimatedOrdinalAtObservation: Value(
            observation.estimatedOrdinalAtObservation,
          ),
          baseEnergyAtObservation: Value(observation.baseEnergyAtObservation),
          ruleVersionAtObservation: Value(observation.ruleVersionAtObservation),
          comparisonBandVersion: Value(observation.comparisonBandVersion),
          personalizationVersionAtObservation: Value(
            observation.personalizationVersionAtObservation,
          ),
          effectiveModelFingerprintAtObservation: Value(
            observation.effectiveModelFingerprintAtObservation,
          ),
          modelRegimeEpochAtObservation: Value(
            observation.modelRegimeEpochAtObservation,
          ),
          activeActivityCountAtObservation: Value(
            observation.activeActivityCountAtObservation,
          ),
          coverageState: Value(observation.coverageState),
          modelRegimeKey: Value(observation.modelRegimeKey),
          observedAt: observation.observedAt.toUtc(),
        ),
      );
    }
    for (final version in backup.personalizationVersions) {
      await into(personalizationVersionsTable).insert(
        PersonalizationVersionsTableCompanion.insert(
          id: version.id,
          parentVersionId: Value(version.parentVersionId),
          effectiveModelFingerprint: version.effectiveModelFingerprint,
          modelRegimeEpoch: version.modelRegimeEpoch,
          creationSource: version.creationSource,
          scheduleSource: Value(version.scheduleSource),
          sourceLearningRunId: Value(version.sourceLearningRunId),
          algorithmVersion: version.algorithmVersion,
          configVersion: version.configVersion,
          changedParameterFamily: version.changedParameterFamily,
          baseEnergy: version.baseEnergy,
          baselineAnchorEnergy: version.baselineAnchorEnergy,
          status: version.status,
          effectiveLifeDay: Value(version.effectiveLifeDay),
          createdAt: version.createdAt.toUtc(),
          activatedAt: Value(version.activatedAt?.toUtc()),
          endedAt: Value(version.endedAt?.toUtc()),
          transitionReason: version.transitionReason,
        ),
      );
    }
    for (final run in backup.learningRuns) {
      await into(learningRunsTable).insert(
        LearningRunsTableCompanion.insert(
          id: run.id,
          parameterFamily: run.parameterFamily,
          sourceModelIdentity: run.sourceModelIdentity,
          sourcePersonalizationVersionId: Value(
            run.sourcePersonalizationVersionId,
          ),
          status: run.status,
          result: Value(run.result),
          evidenceSnapshotJson: run.evidenceSnapshotJson,
          evidenceHash: run.evidenceHash,
          evidenceHashVersion: run.evidenceHashVersion,
          algorithmVersion: run.algorithmVersion,
          configVersion: run.configVersion,
          currentValuesJson: run.currentValuesJson,
          candidateValuesJson: Value(run.candidateValuesJson),
          reasonCodesJson: run.reasonCodesJson,
          triggeredAt: run.triggeredAt.toUtc(),
          completedAt: Value(run.completedAt?.toUtc()),
        ),
      );
    }
    for (final factor in backup.activityFactors) {
      await into(personalizationActivityFactorsTable).insert(
        PersonalizationActivityFactorsTableCompanion.insert(
          personalizationVersionId: factor.personalizationVersionId,
          subcategory: factor.subcategory,
          impactSign: factor.impactSign,
          factor: factor.factor,
          baseActivityRuleVersion: factor.baseActivityRuleVersion,
          sourceLearningRunId: Value(factor.sourceLearningRunId),
          factorRegimeStartedLifeDay: factor.factorRegimeStartedLifeDay,
        ),
      );
    }
    for (final summary in backup.dailySummaries) {
      await into(dailySummariesTable).insert(
        DailySummariesTableCompanion.insert(
          lifeDay: summary.lifeDay,
          baseEstimatedEnergy: summary.baseEstimatedEnergy,
          ruleVersion: summary.ruleVersion,
          morningAdjustment: summary.morningAdjustment,
          shortTermAdjustment: summary.shortTermAdjustment,
          initialEstimatedEnergy: summary.initialEstimatedEnergy,
          finalEstimatedEnergy: summary.finalEstimatedEnergy,
          totalConsumption: summary.totalConsumption,
          totalRecovery: summary.totalRecovery,
          categorySummaryJson: jsonEncode({
            for (final entry in summary.categorySummaries.entries)
              entry.key.code: {
                'durationMinutes': entry.value.durationMinutes,
                'netDelta': entry.value.netDelta,
                'grossDelta': entry.value.grossDelta,
              },
          }),
          isStandardEffectiveDay: summary.isStandardEffectiveDay,
          isWeakEffectiveDay: summary.isWeakEffectiveDay,
          modelSnapshotSource: summary.modelSnapshotSource,
          personalizationVersionId: Value(summary.personalizationVersionId),
          settledAt: summary.settledAt.toUtc(),
        ),
      );
    }
    for (final receipt in backup.promptReceipts) {
      await into(promptReceiptsTable).insert(
        PromptReceiptsTableCompanion.insert(
          id: receipt.id,
          type: receipt.type,
          scopeKey: receipt.scopeKey,
          action: receipt.action,
          occurredAt: receipt.occurredAt.toUtc(),
        ),
      );
    }
    for (final consent in backup.learningConsents) {
      await into(learningConsentsTable).insert(
        LearningConsentsTableCompanion.insert(
          parameterFamily: consent.parameterFamily,
          disclosureVersion: consent.disclosureVersion,
          acceptedAt: consent.acceptedAt.toUtc(),
        ),
      );
    }
    for (final notice in backup.learningNotices) {
      await into(learningNoticesTable).insert(
        LearningNoticesTableCompanion.insert(
          id: notice.id,
          parameterFamily: notice.parameterFamily,
          type: notice.type,
          personalizationVersionId: Value(notice.personalizationVersionId),
          learningRunId: Value(notice.learningRunId),
          dedupKey: notice.dedupKey,
          status: notice.status,
          reasonCode: notice.reasonCode,
          createdAt: notice.createdAt.toUtc(),
          seenAt: Value(notice.seenAt?.toUtc()),
          dismissedAt: Value(notice.dismissedAt?.toUtc()),
        ),
      );
    }
    await failureHook?.call('after-learning-runs');
  }

  Future<void> _verifyBackup(PowerManagerExportDto backup) async {
    final foreignKeyIssues = await customSelect(
      'PRAGMA foreign_key_check',
    ).get();
    if (foreignKeyIssues.isNotEmpty) {
      throw StateError('Restored backup violates foreign keys');
    }
    final integrity = await customSelect('PRAGMA integrity_check').get();
    if (integrity.length != 1 || integrity.single.data.values.single != 'ok') {
      throw StateError('Restored backup failed integrity_check');
    }
    final expected = <String, int>{
      'rule_config_versions': backup.ruleVersions.length,
      'app_settings': 1,
      'morning_check_ins': backup.morningCheckIns.length,
      'activity_records': backup.activityRecords.length,
      'energy_observations': backup.energyObservations.length,
      'activity_feedback': backup.activityFeedback.length,
      'activity_feedback_samples': backup.activityFeedbackSamples.length,
      'learning_runs': backup.learningRuns.length,
      'personalization_versions': backup.personalizationVersions.length,
      'personalization_activity_factors': backup.activityFactors.length,
      'learning_consents': backup.learningConsents.length,
      'learning_notices': backup.learningNotices.length,
      'daily_summaries': backup.dailySummaries.length,
      'prompt_receipts': backup.promptReceipts.length,
    };
    for (final entry in expected.entries) {
      final row = await customSelect(
        'SELECT COUNT(*) AS row_count FROM ${entry.key}',
      ).getSingle();
      final count = row.read<int>('row_count');
      if (count != entry.value) {
        throw StateError('Restored backup row count mismatch');
      }
    }
    final active = await customSelect('''
      SELECT COUNT(*) AS row_count
      FROM personalization_versions
      WHERE status = 'active'
    ''').getSingle();
    if (active.read<int>('row_count') != 1) {
      throw StateError('Restored backup must contain exactly one active model');
    }
  }
}

const _protectionTriggerNames = [
  'daily_summaries_reject_update',
  'app_settings_reject_delete',
  'daily_summaries_reject_delete',
  'referenced_rule_versions_reject_update',
  'referenced_rule_versions_reject_update_v5',
  'learning_runs_reject_final_update',
  'personalization_versions_reject_delete',
  'personalization_versions_reject_identity_update',
  'personalization_versions_reject_terminal_update',
  'learning_consents_reject_update',
  'learning_consents_reject_delete',
  'learning_notices_reject_identity_update',
];
