import 'dart:async';

import 'package:power_manager/core/ids/record_id_generator.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class EnergyReminderService {
  EnergyReminderService({
    required this.clock,
    required this.receipts,
    RecordIdGenerator? recordIdGenerator,
  }) : recordIdGenerator = recordIdGenerator ?? RecordIdGenerator();

  final Clock clock;
  final PromptReceiptsRepository receipts;
  final RecordIdGenerator recordIdGenerator;
  Future<void> _tail = Future.value();

  Future<String?> createOnce({
    required LifeDay lifeDay,
    required EstimatedEnergyBand band,
  }) {
    final completer = Completer<String?>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await _createOnce(lifeDay: lifeDay, band: band));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<String?> _createOnce({
    required LifeDay lifeDay,
    required EstimatedEnergyBand band,
  }) async {
    final message = switch (band) {
      EstimatedEnergyBand.estimatedMediumLow => '估计精力已低于今日初始的一半。',
      EstimatedEnergyBand.estimatedLow => '估计精力已进入今日较低区间。',
      EstimatedEnergyBand.estimatedOverdraft => '当前负荷估计已超过今日储备。',
      EstimatedEnergyBand.estimatedNormal => null,
    };
    if (message == null) return null;
    final scopeKey = '$lifeDay:${band.code}';
    final exists = await receipts.exists(
      type: PromptReceiptType.energyBand,
      scopeKey: scopeKey,
      action: PromptReceiptAction.shown,
    );
    if (exists) return null;
    await receipts.insert(
      PromptReceipt(
        id: recordIdGenerator.next(prefix: 'energy-band', now: clock.now()),
        type: PromptReceiptType.energyBand,
        scopeKey: scopeKey,
        action: PromptReceiptAction.shown,
        occurredAt: clock.now().toUtc(),
      ),
    );
    return message;
  }
}
