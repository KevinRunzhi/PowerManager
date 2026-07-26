import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settings_service.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

void main() {
  test('60 and 140 are accepted for the next life day', () async {
    final repository = _MemorySettings(_settings());
    final service = _service(repository);

    final lower = await service.scheduleBaseEstimate(60);
    expect(lower.baseEstimatedEnergy, 100);
    expect(lower.pendingBaseEstimatedEnergy, 60);
    expect(lower.baseEnergyEffectiveLifeDay, LifeDay(2026, 7, 27));

    final upper = await service.scheduleBaseEstimate(140);
    expect(upper.baseEstimatedEnergy, 100);
    expect(upper.pendingBaseEstimatedEnergy, 140);
    expect(upper.baseEnergyEffectiveLifeDay, LifeDay(2026, 7, 27));
  });

  test('59 and 141 are rejected before persistence', () {
    final repository = _MemorySettings(_settings());
    final service = _service(repository);

    expect(() => service.scheduleBaseEstimate(59), throwsRangeError);
    expect(() => service.scheduleBaseEstimate(141), throwsRangeError);
    expect(repository.saveCount, 0);
  });

  test('onboarding completion is idempotent', () async {
    final repository = _MemorySettings(_settings());
    final service = _service(repository);

    expect((await service.completeOnboarding()).onboardingCompleted, isTrue);
    expect((await service.completeOnboarding()).onboardingCompleted, isTrue);
    expect(repository.saveCount, 1);
  });
}

SettingsService _service(_MemorySettings repository) {
  return SettingsService(
    transactionRunner: const _ImmediateTransactionRunner(),
    preparer: const _FixedPreparer(),
    settings: repository,
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
    baseEstimatedEnergy: 100,
    pendingBaseEstimatedEnergy: null,
    baseEnergyEffectiveLifeDay: null,
    activeRuleVersion: 'energy-rules-v2-mvp-a',
    pendingRuleVersion: null,
    pendingRuleEffectiveLifeDay: null,
    onboardingCompleted: false,
    createdAt: DateTime.utc(2026, 7, 26),
    updatedAt: DateTime.utc(2026, 7, 26),
  );
}
