import 'dart:convert';

import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../db/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftAppSettingsRepository settingsRepository;
  late DriftRuleConfigVersionsRepository rulesRepository;
  late DriftMorningCheckInsRepository checkInsRepository;
  late DriftActivityRecordsRepository activitiesRepository;
  late DriftEnergyObservationsRepository observationsRepository;
  late DriftDailySummariesRepository summariesRepository;
  late DriftPromptReceiptsRepository receiptsRepository;

  setUp(() {
    database = createTestDatabase();
    settingsRepository = DriftAppSettingsRepository(AppSettingsDao(database));
    rulesRepository = DriftRuleConfigVersionsRepository(
      RuleConfigVersionsDao(database),
    );
    checkInsRepository = DriftMorningCheckInsRepository(
      MorningCheckInsDao(database),
    );
    activitiesRepository = DriftActivityRecordsRepository(
      ActivityRecordsDao(database),
    );
    observationsRepository = DriftEnergyObservationsRepository(
      EnergyObservationsDao(database),
    );
    summariesRepository = DriftDailySummariesRepository(
      DailySummariesDao(database),
    );
    receiptsRepository = DriftPromptReceiptsRepository(
      PromptReceiptsDao(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('repositories return domain entities instead of Drift rows', () async {
    final settings = await settingsRepository.get();
    final rules = await rulesRepository.list();

    expect(settings, isA<AppSettings>());
    expect(rules.single, isA<RuleConfigVersion>());
    expect(settings, isNot(isA<AppSettingsRow>()));
    expect(rules.single, isNot(isA<RuleConfigVersionRow>()));
  });

  test('settings and morning check-in CRUD map UTC and enum values', () async {
    final original = await settingsRepository.get();
    await settingsRepository.save(
      AppSettings(
        baseEstimatedEnergy: 110,
        pendingBaseEstimatedEnergy: 108,
        baseEnergyEffectiveLifeDay: LifeDay(2026, 7, 27),
        activeRuleVersion: original.activeRuleVersion,
        pendingRuleVersion: null,
        pendingRuleEffectiveLifeDay: null,
        onboardingCompleted: true,
        createdAt: original.createdAt,
        updatedAt: DateTime.utc(2026, 7, 26, 13),
      ),
    );
    final checkIn = _checkIn();
    await checkInsRepository.insert(checkIn);

    final updatedSettings = await settingsRepository.get();
    final storedCheckIn = await checkInsRepository.findByLifeDay(
      checkIn.lifeDay,
    );
    expect(updatedSettings.baseEstimatedEnergy, 110);
    expect(updatedSettings.baseEnergyEffectiveLifeDay, LifeDay(2026, 7, 27));
    expect(updatedSettings.updatedAt.isUtc, isTrue);
    expect(storedCheckIn, isA<MorningCheckIn>());
    expect(storedCheckIn!.overallState, MorningOverallState.good);
    expect(storedCheckIn.completedAt.isUtc, isTrue);

    final changedCheckIn = MorningCheckIn(
      id: checkIn.id,
      lifeDay: checkIn.lifeDay,
      overallState: MorningOverallState.bad,
      freeTimeLevel: FreeTimeLevel.low,
      pressureSource: PressureSource.study,
      sleepRecovery: SleepRecovery.bad,
      morningAdjustment: -6,
      completedAt: DateTime.utc(2026, 7, 26, 12, 5),
    );
    await checkInsRepository.update(changedCheckIn);
    expect(
      (await checkInsRepository.findByLifeDay(checkIn.lifeDay))!.overallState,
      MorningOverallState.bad,
    );
    await checkInsRepository.delete(checkIn.id);
    expect(await checkInsRepository.list(), isEmpty);
  });

  test(
    'activity queries hide logical deletes but export retains them',
    () async {
      final first = _activity(
        id: 'activity-1',
        completedAt: DateTime.utc(2026, 7, 26, 10),
      );
      final second = _activity(
        id: 'activity-2',
        completedAt: DateTime.utc(2026, 7, 26, 11),
      );
      await activitiesRepository.insert(first);
      await activitiesRepository.insert(second);
      await activitiesRepository.logicallyDelete(
        first.id,
        DateTime.utc(2026, 7, 26, 12),
      );

      final active = await activitiesRepository.listActiveForLifeDay(
        first.lifeDay,
      );
      final all = await activitiesRepository.listAllForLifeDay(first.lifeDay);
      final exported = await activitiesRepository.listAllForExport();

      expect(active.map((activity) => activity.id), ['activity-2']);
      expect(all, hasLength(2));
      expect(exported, hasLength(2));
      expect(
        exported.singleWhere((activity) => activity.id == first.id).status,
        ActivityRecordStatus.deleted,
      );
      expect(
        exported.singleWhere((activity) => activity.id == first.id).deletedAt,
        DateTime.utc(2026, 7, 26, 12),
      );
    },
  );

  test(
    'activity repository creates, reads, updates, and rejects duplicate ids',
    () async {
      final original = _activity(
        id: 'activity-crud',
        completedAt: DateTime.utc(2026, 7, 26, 10),
      );
      await activitiesRepository.insert(original);

      final updated = StoredEstimatedActivity(
        id: original.id,
        lifeDay: original.lifeDay,
        completedAt: DateTime.utc(2026, 7, 26, 10, 30),
        createdAt: original.createdAt,
        updatedAt: DateTime.utc(2026, 7, 26, 12),
        category: ActivityCategory.recovery,
        subcategory: ActivitySubcategory.nap,
        duration: DurationSlot.minutes30,
        theoreticalDelta: 10,
        appliedDelta: 10,
        ruleVersion: original.ruleVersion,
        status: ActivityRecordStatus.active,
        deletedAt: null,
      );
      await activitiesRepository.update(updated);
      final stored = await activitiesRepository.find(original.id);

      expect(stored, isA<StoredEstimatedActivity>());
      expect(stored!.subcategory, ActivitySubcategory.nap);
      expect(stored.duration, DurationSlot.minutes30);
      expect(stored.updatedAt, DateTime.utc(2026, 7, 26, 12));
      await expectLater(
        activitiesRepository.insert(original),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('activity repository rejects mismatched category before SQL', () async {
    final valid = _activity(
      id: 'mismatch',
      completedAt: DateTime.utc(2026, 7, 26, 10),
    );
    final invalid = StoredEstimatedActivity(
      id: valid.id,
      lifeDay: valid.lifeDay,
      completedAt: valid.completedAt,
      createdAt: valid.createdAt,
      updatedAt: valid.updatedAt,
      category: ActivityCategory.leisure,
      subcategory: ActivitySubcategory.classAttendance,
      duration: valid.duration,
      theoreticalDelta: valid.theoreticalDelta,
      appliedDelta: valid.appliedDelta,
      ruleVersion: valid.ruleVersion,
      status: valid.status,
      deletedAt: valid.deletedAt,
    );

    expect(() => activitiesRepository.insert(invalid), throwsArgumentError);
  });

  test(
    'observation, summary, receipt, and rule repositories round-trip',
    () async {
      final observation = _observation();
      final summary = _summary();
      final receipt = _receipt();
      await observationsRepository.insert(observation);
      await summariesRepository.insertOrGet(summary);
      await receiptsRepository.insert(receipt);

      expect(
        await observationsRepository.find(observation.id),
        isA<EnergyObservation>(),
      );
      expect(
        (await summariesRepository.findByLifeDay(
          summary.lifeDay,
        ))!.categorySummaries[ActivityCategory.study]!.grossDelta,
        20,
      );
      expect(
        await receiptsRepository.exists(
          type: receipt.type,
          scopeKey: receipt.scopeKey,
          action: receipt.action,
        ),
        isTrue,
      );
      expect(
        (await rulesRepository.find(energyRulesV2MvpAVersion))!.values,
        contains('activityRules'),
      );
    },
  );

  test(
    'an unreferenced future rule version can be inserted and read',
    () async {
      final futureRule = RuleConfigVersion(
        version: 'energy-rules-future-test',
        values: {
          'ruleVersion': 'energy-rules-future-test',
          'activityRules': <String, Object?>{},
        },
        createdAt: DateTime.utc(2026, 7, 27),
      );
      await rulesRepository.insert(futureRule);

      final stored = await rulesRepository.find(futureRule.version);
      expect(stored, isA<RuleConfigVersion>());
      expect(stored!.version, futureRule.version);
      expect(stored.createdAt.isUtc, isTrue);
      expect(await rulesRepository.list(), hasLength(2));
      await expectLater(
        rulesRepository.insert(futureRule),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('export DTO contains seven data groups and logical deletes', () async {
    final activity = _activity(
      id: 'deleted-export',
      completedAt: DateTime.utc(2026, 7, 26, 10),
    );
    await activitiesRepository.insert(activity);
    await activitiesRepository.logicallyDelete(
      activity.id,
      DateTime.utc(2026, 7, 26, 11),
    );

    final dto = PowerManagerExportDto(
      schemaVersion: database.schemaVersion,
      exportedAt: testNow,
      appVersion: '0.1.0+1',
      appSettings: await settingsRepository.get(),
      ruleVersions: await rulesRepository.list(),
      morningCheckIns: await checkInsRepository.list(),
      activityRecords: await activitiesRepository.listAllForExport(),
      energyObservations: await observationsRepository.list(),
      dailySummaries: await summariesRepository.list(),
      promptReceipts: await receiptsRepository.list(),
    );
    final json = dto.toJson();
    final activityJson =
        (json['activityRecords']! as List<Object?>).single!
            as Map<String, Object?>;

    expect(
      json.keys,
      containsAll([
        'schemaVersion',
        'exportedAt',
        'appVersion',
        'appSettings',
        'ruleConfigVersions',
        'morningCheckIns',
        'activityRecords',
        'energyObservations',
        'dailySummaries',
        'promptReceipts',
      ]),
    );
    expect(activityJson['status'], 'deleted');
    expect(activityJson['deletedAt'], isNotNull);
    expect(jsonDecode(jsonEncode(json)), isA<Map<String, Object?>>());
  });

  test(
    'JSON export service emits parseable versioned backup with deletes',
    () async {
      final activity = _activity(
        id: 'service-deleted-export',
        completedAt: DateTime.utc(2026, 7, 26, 10),
      );
      await activitiesRepository.insert(activity);
      await activitiesRepository.logicallyDelete(
        activity.id,
        DateTime.utc(2026, 7, 26, 11),
      );
      final service = JsonExportService(
        settings: settingsRepository,
        rules: rulesRepository,
        mornings: checkInsRepository,
        activities: activitiesRepository,
        observations: observationsRepository,
        summaries: summariesRepository,
        receipts: receiptsRepository,
        appVersionLoader: () async => '0.1.0+1',
      );

      final result = await service.create(exportedAt: testNow);
      final json = jsonDecode(result.contents) as Map<String, Object?>;
      final records = json['activityRecords']! as List<Object?>;
      final deleted = records.single as Map<String, Object?>;

      expect(result.fileName, 'powermanager-20260726-120000Z.json');
      expect(json['schemaVersion'], 1);
      expect(json['appVersion'], '0.1.0+1');
      expect(json['exportedAt'], testNow.toIso8601String());
      expect(json['ruleConfigVersions'], isA<List<Object?>>());
      expect(deleted['status'], 'deleted');
      expect(deleted, isNot(contains('rowid')));
      expect(deleted, isNot(contains('internalId')));
      expect(json, isNot(contains('deviceId')));
    },
  );
}

MorningCheckIn _checkIn() {
  return MorningCheckIn(
    id: 'check-in-1',
    lifeDay: LifeDay(2026, 7, 26),
    overallState: MorningOverallState.good,
    freeTimeLevel: FreeTimeLevel.medium,
    pressureSource: PressureSource.low,
    sleepRecovery: SleepRecovery.normal,
    morningAdjustment: 6,
    completedAt: testNow,
  );
}

StoredEstimatedActivity _activity({
  required String id,
  required DateTime completedAt,
}) {
  return StoredEstimatedActivity(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    completedAt: completedAt,
    createdAt: completedAt.add(const Duration(minutes: 1)),
    updatedAt: completedAt.add(const Duration(minutes: 1)),
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.classAttendance,
    duration: DurationSlot.minutes15,
    theoreticalDelta: -5,
    appliedDelta: -5,
    ruleVersion: energyRulesV2MvpAVersion,
    status: ActivityRecordStatus.active,
    deletedAt: null,
  );
}

EnergyObservation _observation() {
  return EnergyObservation(
    id: 'observation-1',
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.relativeCorrection,
    absoluteState: null,
    relativeState: RelativeCorrection.aboutRight,
    estimateAtObservation: 80,
    observedAt: testNow,
  );
}

DailySummary _summary() {
  return DailySummary(
    lifeDay: LifeDay(2026, 7, 25),
    baseEstimatedEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: 80,
    totalConsumption: 20,
    totalRecovery: 0,
    categorySummaries: {
      ActivityCategory.study: const CategoryEstimatedSummary(
        category: ActivityCategory.study,
        durationMinutes: 60,
        netDelta: -20,
        grossDelta: 20,
      ),
    },
    isStandardEffectiveDay: true,
    isWeakEffectiveDay: false,
    settledAt: testNow,
  );
}

PromptReceipt _receipt() {
  return PromptReceipt(
    id: 'receipt-1',
    type: PromptReceiptType.morning,
    scopeKey: '2026-07-26',
    action: PromptReceiptAction.shown,
    occurredAt: testNow,
  );
}
