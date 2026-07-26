import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/energy_reminder_service.dart';
import 'package:power_manager/application/home_view_model.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

void main() {
  test('home view model exposes projection and sorts categories by gross', () {
    final viewModel = HomeViewModel.fromProjection(
      _projection(
        initial: 120,
        current: -3,
        summaries: {
          ActivityCategory.study: const CategoryEstimatedSummary(
            category: ActivityCategory.study,
            durationMinutes: 30,
            netDelta: 0,
            grossDelta: 20,
          ),
          ActivityCategory.recovery: const CategoryEstimatedSummary(
            category: ActivityCategory.recovery,
            durationMinutes: 60,
            netDelta: 8,
            grossDelta: 8,
          ),
          ActivityCategory.leisure: const CategoryEstimatedSummary(
            category: ActivityCategory.leisure,
            durationMinutes: 15,
            netDelta: -5,
            grossDelta: 5,
          ),
        },
      ),
    );

    expect(viewModel.initialEstimate, 120);
    expect(viewModel.currentEstimate, -3);
    expect(viewModel.bandLabel, '估计透支');
    expect(viewModel.categories.map((item) => item.category), [
      ActivityCategory.study,
      ActivityCategory.recovery,
      ActivityCategory.leisure,
    ]);
    expect(viewModel.categories.first.netDelta, 0);
    expect(viewModel.categories.first.grossDelta, 20);
  });

  test(
    'same life-day and band reminder is emitted only once under concurrency',
    () async {
      final receipts = _MemoryReceipts();
      final service = EnergyReminderService(
        clock: _FixedClock(),
        receipts: receipts,
      );
      final results = await Future.wait([
        service.createOnce(
          lifeDay: LifeDay(2026, 7, 26),
          band: EstimatedEnergyBand.estimatedLow,
        ),
        service.createOnce(
          lifeDay: LifeDay(2026, 7, 26),
          band: EstimatedEnergyBand.estimatedLow,
        ),
      ]);

      expect(results.whereType<String>(), hasLength(1));
      expect(receipts.values, hasLength(1));
      expect(receipts.values.single.scopeKey, '2026-07-26:estimatedLow');
    },
  );

  test(
    'normal creates no receipt and each lower band has its own receipt',
    () async {
      final receipts = _MemoryReceipts();
      final service = EnergyReminderService(
        clock: _FixedClock(),
        receipts: receipts,
      );
      expect(
        await service.createOnce(
          lifeDay: LifeDay(2026, 7, 26),
          band: EstimatedEnergyBand.estimatedNormal,
        ),
        isNull,
      );
      for (final band in [
        EstimatedEnergyBand.estimatedMediumLow,
        EstimatedEnergyBand.estimatedLow,
        EstimatedEnergyBand.estimatedOverdraft,
      ]) {
        expect(
          await service.createOnce(lifeDay: LifeDay(2026, 7, 26), band: band),
          contains('估计'),
        );
      }
      expect(receipts.values, hasLength(3));
    },
  );
}

CurrentDayProjection _projection({
  required int initial,
  required int current,
  required Map<ActivityCategory, CategoryEstimatedSummary> summaries,
}) {
  final band = current < 0
      ? EstimatedEnergyBand.estimatedOverdraft
      : EstimatedEnergyBand.estimatedNormal;
  return CurrentDayProjection(
    lifeDay: LifeDay(2026, 7, 26),
    baseEstimatedEnergy: initial,
    ruleVersion: 'test',
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    previousFinalEstimate: null,
    morningCheckInCompleted: false,
    projection: EstimatedDayProjection(
      initialEstimate: initial,
      currentEstimate: current,
      band: band,
      activities: const [],
      totalConsumption: 0,
      totalRecovery: 0,
      categorySummaries: summaries,
      effectiveDayKind: EffectiveDayKind.none,
    ),
  );
}

final class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 7, 26, 12);
}

final class _MemoryReceipts implements PromptReceiptsRepository {
  final values = <PromptReceipt>[];

  @override
  Future<bool> exists({
    required PromptReceiptType type,
    required String scopeKey,
    required PromptReceiptAction action,
  }) async {
    return values.any(
      (item) =>
          item.type == type &&
          item.scopeKey == scopeKey &&
          item.action == action,
    );
  }

  @override
  Future<void> insert(PromptReceipt receipt) async {
    values.add(receipt);
  }

  @override
  Future<List<PromptReceipt>> list() async => List.unmodifiable(values);
}
