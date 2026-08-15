import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settings_service.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

void main() {
  test('60 and 140 are accepted for the next life day', () async {
    final repository = _MemorySettings(_settings());
    final versions = _MemoryVersions(_initialVersion());
    final service = _service(repository, versions);

    await service.scheduleBaseEstimate(60);
    final lower = await versions.findPending();
    expect((await versions.getActive()).baseEnergy, 100);
    expect(lower!.baseEnergy, 60);
    expect(lower.effectiveLifeDay, LifeDay(2026, 7, 27));

    await service.scheduleBaseEstimate(140);
    final upper = await versions.findPending();
    expect((await versions.getActive()).baseEnergy, 100);
    expect(upper!.baseEnergy, 140);
    expect(upper.effectiveLifeDay, LifeDay(2026, 7, 27));
    expect(
      (await versions.find(lower.id))!.status,
      PersonalizationVersionStatus.invalidated,
    );
  });

  test('59 and 141 are rejected before persistence', () {
    final repository = _MemorySettings(_settings());
    final versions = _MemoryVersions(_initialVersion());
    final service = _service(repository, versions);

    expect(() => service.scheduleBaseEstimate(59), throwsRangeError);
    expect(() => service.scheduleBaseEstimate(141), throwsRangeError);
    expect(repository.saveCount, 0);
  });

  test('onboarding completion is idempotent', () async {
    final repository = _MemorySettings(_settings());
    final versions = _MemoryVersions(_initialVersion());
    final service = _service(repository, versions);

    expect((await service.completeOnboarding()).onboardingCompleted, isTrue);
    expect((await service.completeOnboarding()).onboardingCompleted, isTrue);
    expect(repository.saveCount, 1);
  });
}

SettingsService _service(_MemorySettings repository, _MemoryVersions versions) {
  const transactionRunner = _ImmediateTransactionRunner();
  return SettingsService(
    transactionRunner: transactionRunner,
    preparer: const _FixedPreparer(),
    settings: repository,
    modelActivationService: ModelActivationService(
      transactionRunner: transactionRunner,
      settings: repository,
      versions: versions,
      learningRuns: _MemoryLearningRuns(),
      consents: _MemoryConsents(),
      notices: _MemoryNotices(),
    ),
  );
}

final class _ImmediateTransactionRunner implements TransactionRunner {
  const _ImmediateTransactionRunner();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

final class _FixedPreparer implements OperationPreparer {
  const _FixedPreparer();

  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) async {
    return OperationPreparationResult(
      trigger: trigger,
      nowLocal: DateTime(2026, 7, 26, 12),
      nowUtc: DateTime.utc(2026, 7, 26, 4),
      current: CurrentDayProjection(
        lifeDay: LifeDay(2026, 7, 26),
        baseEstimatedEnergy: 100,
        ruleVersion: 'energy-rules-v2-mvp-a',
        morningAdjustment: 0,
        shortTermAdjustment: 0,
        previousFinalEstimate: null,
        morningCheckInCompleted: false,
        projection: EstimatedDayProjection(
          initialEstimate: 100,
          currentEstimate: 100,
          band: EstimatedEnergyBand.estimatedNormal,
          activities: const [],
          totalConsumption: 0,
          totalRecovery: 0,
          categorySummaries: const {},
          effectiveDayKind: EffectiveDayKind.none,
        ),
      ),
      settledSummaries: const [],
      appliedPendingBaseEnergy: false,
      appliedPendingRuleVersion: false,
    );
  }
}

final class _MemorySettings implements AppSettingsRepository {
  _MemorySettings(this.value);

  AppSettings value;
  int saveCount = 0;

  @override
  Future<AppSettings> get() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
    saveCount++;
  }
}

AppSettings _settings() {
  return AppSettings(
    activeRuleVersion: 'energy-rules-v2-mvp-a',
    pendingRuleVersion: null,
    pendingRuleEffectiveLifeDay: null,
    onboardingCompleted: false,
    createdAt: DateTime.utc(2026, 7, 26),
    updatedAt: DateTime.utc(2026, 7, 26),
  );
}

PersonalizationVersion _initialVersion() => initialPersonalizationVersion(
  baseEnergy: 100,
  createdAt: DateTime.utc(2026, 7, 26),
);

final class _MemoryVersions implements PersonalizationVersionsRepository {
  _MemoryVersions(PersonalizationVersion initial) : values = [initial];

  final List<PersonalizationVersion> values;

  @override
  Future<void> insert(PersonalizationVersion version) async {
    if (values.any((item) => item.id == version.id)) {
      throw StateError('duplicate version');
    }
    values.add(version);
  }

  @override
  Future<void> update(PersonalizationVersion version) async {
    final index = values.indexWhere((item) => item.id == version.id);
    if (index < 0) throw StateError('missing version');
    values[index] = version;
  }

  @override
  Future<bool> updateIfStatus(
    PersonalizationVersion version,
    PersonalizationVersionStatus expectedStatus,
  ) async {
    final index = values.indexWhere((item) => item.id == version.id);
    if (index < 0 || values[index].status != expectedStatus) return false;
    values[index] = version;
    return true;
  }

  @override
  Future<PersonalizationVersion?> find(String id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<PersonalizationVersion> getActive() async => values.singleWhere(
    (item) => item.status == PersonalizationVersionStatus.active,
  );

  @override
  Future<PersonalizationVersion?> findPending() async =>
      values.where((item) => item.status.isPending).firstOrNull;

  @override
  Future<List<PersonalizationVersion>> list() async => List.of(values);
}

final class _MemoryLearningRuns implements LearningRunsRepository {
  const _MemoryLearningRuns();

  @override
  Future<void> insert(LearningRun run) async {}

  @override
  Future<void> update(LearningRun run) async {}

  @override
  Future<LearningRun?> find(String id) async => null;

  @override
  Future<LearningRun?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) async => null;

  @override
  Future<List<LearningRun>> list() async => const [];
}

final class _MemoryConsents implements LearningConsentsRepository {
  _MemoryConsents();

  final List<LearningConsent> values = [];

  @override
  Future<void> insert(LearningConsent consent) async => values.add(consent);

  @override
  Future<bool> exists({
    required LearningParameterFamily parameterFamily,
    required String disclosureVersion,
  }) async => values.any(
    (item) =>
        item.parameterFamily == parameterFamily &&
        item.disclosureVersion == disclosureVersion,
  );

  @override
  Future<List<LearningConsent>> list() async => List.of(values);
}

final class _MemoryNotices implements LearningNoticesRepository {
  _MemoryNotices();

  final List<LearningNotice> values = [];

  @override
  Future<void> insert(LearningNotice notice) async => values.add(notice);

  @override
  Future<void> update(LearningNotice notice) async {
    final index = values.indexWhere((item) => item.id == notice.id);
    if (index < 0) throw StateError('missing notice');
    values[index] = notice;
  }

  @override
  Future<LearningNotice?> find(String id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<List<LearningNotice>> list() async => List.of(values);
}
