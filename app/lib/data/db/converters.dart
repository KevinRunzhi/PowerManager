part of 'app_database.dart';

T _enumFromCode<T>(Iterable<T> values, String code, String Function(T) codeOf) {
  return values.firstWhere(
    (value) => codeOf(value) == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown enum code'),
  );
}

final class LifeDayConverter extends TypeConverter<LifeDay, String> {
  const LifeDayConverter();

  @override
  LifeDay fromSql(String fromDb) => LifeDay.parse(fromDb);

  @override
  String toSql(LifeDay value) => value.toString();
}

final class ActivityCategoryConverter
    extends TypeConverter<ActivityCategory, String> {
  const ActivityCategoryConverter();

  @override
  ActivityCategory fromSql(String fromDb) =>
      _enumFromCode(ActivityCategory.values, fromDb, (value) => value.code);

  @override
  String toSql(ActivityCategory value) => value.code;
}

final class ActivitySubcategoryConverter
    extends TypeConverter<ActivitySubcategory, String> {
  const ActivitySubcategoryConverter();

  @override
  ActivitySubcategory fromSql(String fromDb) =>
      _enumFromCode(ActivitySubcategory.values, fromDb, (value) => value.code);

  @override
  String toSql(ActivitySubcategory value) => value.code;
}

final class DurationSlotConverter extends TypeConverter<DurationSlot, int> {
  const DurationSlotConverter();

  @override
  DurationSlot fromSql(int fromDb) => DurationSlot.fromMinutes(fromDb);

  @override
  int toSql(DurationSlot value) => value.minutes;
}

final class MorningOverallStateConverter
    extends TypeConverter<MorningOverallState, String> {
  const MorningOverallStateConverter();

  @override
  MorningOverallState fromSql(String fromDb) =>
      _enumFromCode(MorningOverallState.values, fromDb, (value) => value.code);

  @override
  String toSql(MorningOverallState value) => value.code;
}

final class FreeTimeLevelConverter
    extends TypeConverter<FreeTimeLevel, String> {
  const FreeTimeLevelConverter();

  @override
  FreeTimeLevel fromSql(String fromDb) =>
      _enumFromCode(FreeTimeLevel.values, fromDb, (value) => value.code);

  @override
  String toSql(FreeTimeLevel value) => value.code;
}

final class PressureSourceConverter
    extends TypeConverter<PressureSource, String> {
  const PressureSourceConverter();

  @override
  PressureSource fromSql(String fromDb) =>
      _enumFromCode(PressureSource.values, fromDb, (value) => value.code);

  @override
  String toSql(PressureSource value) => value.code;
}

final class SleepRecoveryConverter
    extends TypeConverter<SleepRecovery, String> {
  const SleepRecoveryConverter();

  @override
  SleepRecovery fromSql(String fromDb) =>
      _enumFromCode(SleepRecovery.values, fromDb, (value) => value.code);

  @override
  String toSql(SleepRecovery value) => value.code;
}

final class ActivityRecordStatusConverter
    extends TypeConverter<ActivityRecordStatus, String> {
  const ActivityRecordStatusConverter();

  @override
  ActivityRecordStatus fromSql(String fromDb) =>
      _enumFromCode(ActivityRecordStatus.values, fromDb, (value) => value.code);

  @override
  String toSql(ActivityRecordStatus value) => value.code;
}

final class EnergyObservationTypeConverter
    extends TypeConverter<EnergyObservationType, String> {
  const EnergyObservationTypeConverter();

  @override
  EnergyObservationType fromSql(String fromDb) => _enumFromCode(
    EnergyObservationType.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(EnergyObservationType value) => value.code;
}

final class ObservationReferenceTypeConverter
    extends TypeConverter<ObservationReferenceType, String> {
  const ObservationReferenceTypeConverter();

  @override
  ObservationReferenceType fromSql(String fromDb) => _enumFromCode(
    ObservationReferenceType.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(ObservationReferenceType value) => value.code;
}

final class ObservationCoverageStateConverter
    extends TypeConverter<ObservationCoverageState, String> {
  const ObservationCoverageStateConverter();

  @override
  ObservationCoverageState fromSql(String fromDb) => _enumFromCode(
    ObservationCoverageState.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(ObservationCoverageState value) => value.code;
}

final class ActivityImpactSignConverter
    extends TypeConverter<ActivityImpactSign, String> {
  const ActivityImpactSignConverter();

  @override
  ActivityImpactSign fromSql(String fromDb) =>
      _enumFromCode(ActivityImpactSign.values, fromDb, (value) => value.code);

  @override
  String toSql(ActivityImpactSign value) => value.code;
}

final class ActivityFeedbackDirectionConverter
    extends TypeConverter<ActivityFeedbackDirection, String> {
  const ActivityFeedbackDirectionConverter();

  @override
  ActivityFeedbackDirection fromSql(String fromDb) => _enumFromCode(
    ActivityFeedbackDirection.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(ActivityFeedbackDirection value) => value.code;
}

final class ActivityFeedbackStatusConverter
    extends TypeConverter<ActivityFeedbackStatus, String> {
  const ActivityFeedbackStatusConverter();

  @override
  ActivityFeedbackStatus fromSql(String fromDb) => _enumFromCode(
    ActivityFeedbackStatus.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(ActivityFeedbackStatus value) => value.code;
}

final class ActivityFeedbackInvalidationReasonConverter
    extends TypeConverter<ActivityFeedbackInvalidationReason, String> {
  const ActivityFeedbackInvalidationReasonConverter();

  @override
  ActivityFeedbackInvalidationReason fromSql(String fromDb) => _enumFromCode(
    ActivityFeedbackInvalidationReason.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(ActivityFeedbackInvalidationReason value) => value.code;
}

final class LearningParameterFamilyConverter
    extends TypeConverter<LearningParameterFamily, String> {
  const LearningParameterFamilyConverter();

  @override
  LearningParameterFamily fromSql(String fromDb) => _enumFromCode(
    LearningParameterFamily.values,
    fromDb,
    (value) => value.code,
  );

  @override
  String toSql(LearningParameterFamily value) => value.code;
}

final class LearningRunStatusConverter
    extends TypeConverter<LearningRunStatus, String> {
  const LearningRunStatusConverter();

  @override
  LearningRunStatus fromSql(String fromDb) =>
      _enumFromCode(LearningRunStatus.values, fromDb, (value) => value.code);

  @override
  String toSql(LearningRunStatus value) => value.code;
}

final class LearningRunResultConverter
    extends TypeConverter<LearningRunResult, String> {
  const LearningRunResultConverter();

  @override
  LearningRunResult fromSql(String fromDb) =>
      _enumFromCode(LearningRunResult.values, fromDb, (value) => value.code);

  @override
  String toSql(LearningRunResult value) => value.code;
}

final class AbsoluteEnergyStateConverter
    extends TypeConverter<AbsoluteEnergyState, String> {
  const AbsoluteEnergyStateConverter();

  @override
  AbsoluteEnergyState fromSql(String fromDb) =>
      _enumFromCode(AbsoluteEnergyState.values, fromDb, (value) => value.code);

  @override
  String toSql(AbsoluteEnergyState value) => value.code;
}

final class RelativeCorrectionConverter
    extends TypeConverter<RelativeCorrection, String> {
  const RelativeCorrectionConverter();

  @override
  RelativeCorrection fromSql(String fromDb) =>
      _enumFromCode(RelativeCorrection.values, fromDb, (value) => value.code);

  @override
  String toSql(RelativeCorrection value) => value.code;
}

final class PromptReceiptTypeConverter
    extends TypeConverter<PromptReceiptType, String> {
  const PromptReceiptTypeConverter();

  @override
  PromptReceiptType fromSql(String fromDb) =>
      _enumFromCode(PromptReceiptType.values, fromDb, (value) => value.code);

  @override
  String toSql(PromptReceiptType value) => value.code;
}

final class PromptReceiptActionConverter
    extends TypeConverter<PromptReceiptAction, String> {
  const PromptReceiptActionConverter();

  @override
  PromptReceiptAction fromSql(String fromDb) =>
      _enumFromCode(PromptReceiptAction.values, fromDb, (value) => value.code);

  @override
  String toSql(PromptReceiptAction value) => value.code;
}
