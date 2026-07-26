import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> get();
  Future<void> save(AppSettings settings);
}

abstract interface class RuleConfigVersionsRepository {
  Future<void> insert(RuleConfigVersion version);
  Future<RuleConfigVersion?> find(String version);
  Future<List<RuleConfigVersion>> list();
}

abstract interface class MorningCheckInsRepository {
  Future<void> insert(MorningCheckIn checkIn);
  Future<MorningCheckIn?> findByLifeDay(LifeDay lifeDay);
  Future<List<MorningCheckIn>> list();
  Future<void> update(MorningCheckIn checkIn);
  Future<void> delete(String id);
}

abstract interface class ActivityRecordsRepository {
  Future<void> insert(StoredEstimatedActivity activity);
  Future<StoredEstimatedActivity?> find(String id);
  Future<List<StoredEstimatedActivity>> listActiveForLifeDay(LifeDay lifeDay);
  Future<List<StoredEstimatedActivity>> listAllForLifeDay(LifeDay lifeDay);
  Future<List<StoredEstimatedActivity>> listAllForExport();
  Future<void> update(StoredEstimatedActivity activity);
  Future<void> logicallyDelete(String id, DateTime deletedAt);
}

abstract interface class EnergyObservationsRepository {
  Future<void> insert(EnergyObservation observation);
  Future<EnergyObservation?> find(String id);
  Future<List<EnergyObservation>> listForLifeDay(LifeDay lifeDay);
  Future<List<EnergyObservation>> list();
}

abstract interface class DailySummariesRepository {
  Future<DailySummary> insertOrGet(DailySummary summary);
  Future<DailySummary?> findByLifeDay(LifeDay lifeDay);
  Future<List<DailySummary>> list();
}

abstract interface class PromptReceiptsRepository {
  Future<void> insert(PromptReceipt receipt);
  Future<bool> exists({
    required PromptReceiptType type,
    required String scopeKey,
    required PromptReceiptAction action,
  });
  Future<List<PromptReceipt>> list();
}
