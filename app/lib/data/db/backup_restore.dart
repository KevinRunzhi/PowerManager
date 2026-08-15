part of 'app_database.dart';

typedef RestoreFailureHook = Future<void> Function(String checkpoint);

extension BackupRestoreDatabase on AppDatabase {
  Future<void> replaceWithBackup(
    PowerManagerExportDto backup, {
    RestoreFailureHook? failureHook,
  }) {
    return transaction(() async {
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
    await delete(promptReceiptsTable).go();
    await delete(energyObservationsTable).go();
    await delete(morningCheckInsTable).go();
    await delete(activityFeedbackTable).go();
    await delete(activityRecordsTable).go();
    await delete(dailySummariesTable).go();
    await delete(appSettingsTable).go();
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
        baseEstimatedEnergy: Value(settings.baseEstimatedEnergy),
        pendingBaseEstimatedEnergy: Value(settings.pendingBaseEstimatedEnergy),
        baseEnergyEffectiveLifeDay: Value(settings.baseEnergyEffectiveLifeDay),
        activeRuleVersion: settings.activeRuleVersion,
        pendingRuleVersion: Value(settings.pendingRuleVersion),
        pendingRuleEffectiveLifeDay: Value(
          settings.pendingRuleEffectiveLifeDay,
        ),
        onboardingCompleted: Value(settings.onboardingCompleted),
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
          observedAt: feedback.observedAt.toUtc(),
        ),
      );
    }
    await failureHook?.call('after-feedback');

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
  }
}

const _protectionTriggerNames = [
  'daily_summaries_reject_update',
  'app_settings_reject_delete',
  'daily_summaries_reject_delete',
  'referenced_rule_versions_reject_update',
];
