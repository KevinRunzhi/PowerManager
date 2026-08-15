import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class BackupDataCounts {
  const BackupDataCounts({
    required this.ruleVersions,
    required this.morningCheckIns,
    required this.activityRecords,
    required this.energyObservations,
    this.activityFeedback = 0,
    required this.dailySummaries,
    required this.promptReceipts,
  });

  final int ruleVersions;
  final int morningCheckIns;
  final int activityRecords;
  final int energyObservations;
  final int activityFeedback;
  final int dailySummaries;
  final int promptReceipts;

  int get total =>
      ruleVersions +
      morningCheckIns +
      activityRecords +
      energyObservations +
      activityFeedback +
      dailySummaries +
      promptReceipts +
      1;
}

final class BackupInspection {
  const BackupInspection({
    required this.fileName,
    required this.backup,
    required this.counts,
    required this.earliestLifeDay,
    required this.latestLifeDay,
  });

  final String fileName;
  final PowerManagerExportDto backup;
  final BackupDataCounts counts;
  final LifeDay? earliestLifeDay;
  final LifeDay? latestLifeDay;
}

final class JsonBackupCodec {
  const JsonBackupCodec();

  static const maxBytes = 10 * 1024 * 1024;

  BackupInspection inspect({
    required String fileName,
    required Uint8List bytes,
  }) {
    if (!fileName.toLowerCase().endsWith('.json')) {
      throw const BackupFormatException('请选择 PowerManager JSON 备份文件。');
    }
    if (bytes.length > maxBytes) {
      throw const BackupFormatException('备份文件超过 10 MiB，无法导入。');
    }

    final String contents;
    try {
      contents = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const BackupFormatException('文件不是有效的 UTF-8 文本。');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException {
      throw const BackupFormatException('文件不是有效的 JSON。');
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupFormatException('备份顶层必须是 JSON 对象。');
    }

    try {
      final backup = _parseBackup(decoded);
      _validateBackup(backup);
      final lifeDays = <LifeDay>[
        ...backup.morningCheckIns.map((item) => item.lifeDay),
        ...backup.activityRecords.map((item) => item.lifeDay),
        ...backup.energyObservations.map((item) => item.lifeDay),
        ...backup.activityFeedback.map((item) => item.lifeDay),
        ...backup.dailySummaries.map((item) => item.lifeDay),
      ]..sort();
      return BackupInspection(
        fileName: fileName,
        backup: backup,
        counts: BackupDataCounts(
          ruleVersions: backup.ruleVersions.length,
          morningCheckIns: backup.morningCheckIns.length,
          activityRecords: backup.activityRecords.length,
          energyObservations: backup.energyObservations.length,
          activityFeedback: backup.activityFeedback.length,
          dailySummaries: backup.dailySummaries.length,
          promptReceipts: backup.promptReceipts.length,
        ),
        earliestLifeDay: lifeDays.firstOrNull,
        latestLifeDay: lifeDays.lastOrNull,
      );
    } on BackupFormatException {
      rethrow;
    } on Object {
      throw const BackupFormatException('备份内容不完整或数据关系不合法。');
    }
  }
}

PowerManagerExportDto _parseBackup(Map<String, Object?> json) {
  final schemaVersion = _int(json, 'schemaVersion', '顶层');
  if (schemaVersion != 1 && schemaVersion != 2) {
    throw const BackupFormatException('当前应用只支持 schemaVersion 1 或 2 的备份。');
  }
  final settingsJson = _map(json, 'appSettings', '顶层');
  final rules = _list(
    json,
    'ruleConfigVersions',
    '顶层',
  ).map((item) => _parseRule(_asMap(item, '规则版本'))).toList(growable: false);
  final mornings = _list(
    json,
    'morningCheckIns',
    '顶层',
  ).map((item) => _parseMorning(_asMap(item, '晨间确认'))).toList(growable: false);
  final activities = _list(
    json,
    'activityRecords',
    '顶层',
  ).map((item) => _parseActivity(_asMap(item, '活动记录'))).toList(growable: false);
  final observations = _list(json, 'energyObservations', '顶层')
      .map(
        (item) => _parseObservation(
          _asMap(item, '实际状态'),
          schemaVersion: schemaVersion,
        ),
      )
      .toList(growable: false);
  final feedback = schemaVersion == 1
      ? const <ActivityFeedback>[]
      : _list(json, 'activityFeedback', '顶层')
            .map((item) => _parseFeedback(_asMap(item, '活动反馈')))
            .toList(growable: false);
  final summaries = _list(
    json,
    'dailySummaries',
    '顶层',
  ).map((item) => _parseSummary(_asMap(item, '日总结'))).toList(growable: false);
  final receipts = _list(
    json,
    'promptReceipts',
    '顶层',
  ).map((item) => _parseReceipt(_asMap(item, '提醒回执'))).toList(growable: false);

  return PowerManagerExportDto(
    schemaVersion: schemaVersion,
    exportedAt: _date(json, 'exportedAt', '顶层'),
    appVersion: _string(json, 'appVersion', '顶层'),
    appSettings: _parseSettings(settingsJson),
    ruleVersions: rules,
    morningCheckIns: mornings,
    activityRecords: activities,
    energyObservations: observations,
    activityFeedback: feedback,
    dailySummaries: summaries,
    promptReceipts: receipts,
  );
}

AppSettings _parseSettings(Map<String, Object?> json) {
  return AppSettings(
    baseEstimatedEnergy: _int(json, 'baseEstimatedEnergy', '设置'),
    pendingBaseEstimatedEnergy: _nullableInt(
      json,
      'pendingBaseEstimatedEnergy',
      '设置',
    ),
    baseEnergyEffectiveLifeDay: _nullableLifeDay(
      json,
      'baseEnergyEffectiveLifeDay',
      '设置',
    ),
    activeRuleVersion: _string(json, 'activeRuleVersion', '设置'),
    pendingRuleVersion: _nullableString(json, 'pendingRuleVersion', '设置'),
    pendingRuleEffectiveLifeDay: _nullableLifeDay(
      json,
      'pendingRuleEffectiveLifeDay',
      '设置',
    ),
    onboardingCompleted: _bool(json, 'onboardingCompleted', '设置'),
    createdAt: _date(json, 'createdAt', '设置'),
    updatedAt: _date(json, 'updatedAt', '设置'),
  );
}

RuleConfigVersion _parseRule(Map<String, Object?> json) {
  return RuleConfigVersion(
    version: _string(json, 'version', '规则版本'),
    values: _map(json, 'values', '规则版本'),
    createdAt: _date(json, 'createdAt', '规则版本'),
  );
}

MorningCheckIn _parseMorning(Map<String, Object?> json) {
  final overall = _enumByCode(
    MorningOverallState.values,
    _string(json, 'overallState', '晨间确认'),
    (value) => value.code,
    '总体状态',
  );
  return MorningCheckIn(
    id: _string(json, 'id', '晨间确认'),
    lifeDay: _lifeDay(json, 'lifeDay', '晨间确认'),
    overallState: overall,
    freeTimeLevel: _enumByCode(
      FreeTimeLevel.values,
      _string(json, 'freeTimeLevel', '晨间确认'),
      (value) => value.code,
      '空闲程度',
    ),
    pressureSource: _enumByCode(
      PressureSource.values,
      _string(json, 'pressureSource', '晨间确认'),
      (value) => value.code,
      '压力来源',
    ),
    sleepRecovery: _enumByCode(
      SleepRecovery.values,
      _string(json, 'sleepRecovery', '晨间确认'),
      (value) => value.code,
      '睡眠恢复',
    ),
    morningAdjustment: _int(json, 'morningAdjustment', '晨间确认'),
    completedAt: _date(json, 'completedAt', '晨间确认'),
  );
}

StoredEstimatedActivity _parseActivity(Map<String, Object?> json) {
  return StoredEstimatedActivity(
    id: _string(json, 'id', '活动记录'),
    lifeDay: _lifeDay(json, 'lifeDay', '活动记录'),
    completedAt: _date(json, 'completedAt', '活动记录'),
    createdAt: _date(json, 'createdAt', '活动记录'),
    updatedAt: _date(json, 'updatedAt', '活动记录'),
    category: _enumByCode(
      ActivityCategory.values,
      _string(json, 'category', '活动记录'),
      (value) => value.code,
      '活动大类',
    ),
    subcategory: _enumByCode(
      ActivitySubcategory.values,
      _string(json, 'subcategory', '活动记录'),
      (value) => value.code,
      '活动子类',
    ),
    duration: _duration(_int(json, 'durationMinutes', '活动记录')),
    theoreticalDelta: _int(json, 'theoreticalDelta', '活动记录'),
    appliedDelta: _int(json, 'appliedDelta', '活动记录'),
    ruleVersion: _string(json, 'ruleVersion', '活动记录'),
    status: _enumByCode(
      ActivityRecordStatus.values,
      _string(json, 'status', '活动记录'),
      (value) => value.code,
      '活动状态',
    ),
    deletedAt: _nullableDate(json, 'deletedAt', '活动记录'),
  );
}

EnergyObservation _parseObservation(
  Map<String, Object?> json, {
  required int schemaVersion,
}) {
  if (schemaVersion >= 2) {
    _requireKeys(json, const {
      'contractVersion',
      'referenceType',
      'initialEstimateAtObservation',
      'estimatedOrdinalAtObservation',
      'baseEnergyAtObservation',
      'ruleVersionAtObservation',
      'comparisonBandVersion',
      'personalizationVersionAtObservation',
      'effectiveModelFingerprintAtObservation',
      'modelRegimeEpochAtObservation',
      'activeActivityCountAtObservation',
      'coverageState',
      'modelRegimeKey',
    }, '实际状态');
  }
  final absoluteCode = _nullableString(json, 'absoluteState', '实际状态');
  final relativeCode = _nullableString(json, 'relativeState', '实际状态');
  final referenceCode = schemaVersion >= 2
      ? _nullableString(json, 'referenceType', '实际状态')
      : null;
  final coverageCode = schemaVersion >= 2
      ? _nullableString(json, 'coverageState', '实际状态')
      : null;
  return EnergyObservation(
    id: _string(json, 'id', '实际状态'),
    lifeDay: _lifeDay(json, 'lifeDay', '实际状态'),
    type: _enumByCode(
      EnergyObservationType.values,
      _string(json, 'type', '实际状态'),
      (value) => value.code,
      '实际状态类型',
    ),
    absoluteState: absoluteCode == null
        ? null
        : _enumByCode<AbsoluteEnergyState>(
            AbsoluteEnergyState.values,
            absoluteCode,
            (value) => value.code,
            '每日实际状态',
          ),
    relativeState: relativeCode == null
        ? null
        : _enumByCode<RelativeCorrection>(
            RelativeCorrection.values,
            relativeCode,
            (value) => value.code,
            '相对校正',
          ),
    estimateAtObservation: _nullableInt(json, 'estimateAtObservation', '实际状态'),
    observedAt: _date(json, 'observedAt', '实际状态'),
    contractVersion: schemaVersion >= 2
        ? _nullableString(json, 'contractVersion', '实际状态')
        : null,
    referenceType: referenceCode == null
        ? null
        : _enumByCode<ObservationReferenceType>(
            ObservationReferenceType.values,
            referenceCode,
            (value) => value.code,
            '观测参考类型',
          ),
    initialEstimateAtObservation: schemaVersion >= 2
        ? _nullableInt(json, 'initialEstimateAtObservation', '实际状态')
        : null,
    estimatedOrdinalAtObservation: schemaVersion >= 2
        ? _nullableInt(json, 'estimatedOrdinalAtObservation', '实际状态')
        : null,
    baseEnergyAtObservation: schemaVersion >= 2
        ? _nullableInt(json, 'baseEnergyAtObservation', '实际状态')
        : null,
    ruleVersionAtObservation: schemaVersion >= 2
        ? _nullableString(json, 'ruleVersionAtObservation', '实际状态')
        : null,
    comparisonBandVersion: schemaVersion >= 2
        ? _nullableString(json, 'comparisonBandVersion', '实际状态')
        : null,
    personalizationVersionAtObservation: schemaVersion >= 2
        ? _nullableString(json, 'personalizationVersionAtObservation', '实际状态')
        : null,
    effectiveModelFingerprintAtObservation: schemaVersion >= 2
        ? _nullableString(
            json,
            'effectiveModelFingerprintAtObservation',
            '实际状态',
          )
        : null,
    modelRegimeEpochAtObservation: schemaVersion >= 2
        ? _nullableString(json, 'modelRegimeEpochAtObservation', '实际状态')
        : null,
    activeActivityCountAtObservation: schemaVersion >= 2
        ? _nullableInt(json, 'activeActivityCountAtObservation', '实际状态')
        : null,
    coverageState: coverageCode == null
        ? null
        : _enumByCode<ObservationCoverageState>(
            ObservationCoverageState.values,
            coverageCode,
            (value) => value.code,
            '活动覆盖状态',
          ),
    modelRegimeKey: schemaVersion >= 2
        ? _nullableString(json, 'modelRegimeKey', '实际状态')
        : null,
  );
}

ActivityFeedback _parseFeedback(Map<String, Object?> json) {
  _requireKeys(json, const {
    'id',
    'activityRecordId',
    'lifeDay',
    'subcategorySnapshot',
    'durationMinutesSnapshot',
    'theoreticalDeltaSnapshot',
    'appliedDeltaSnapshot',
    'impactSignSnapshot',
    'ruleVersionSnapshot',
    'activityUpdatedAtSnapshot',
    'direction',
    'status',
    'invalidationReason',
    'observedAt',
  }, '活动反馈');
  final invalidationCode = _nullableString(json, 'invalidationReason', '活动反馈');
  return ActivityFeedback(
    id: _string(json, 'id', '活动反馈'),
    activityRecordId: _string(json, 'activityRecordId', '活动反馈'),
    lifeDay: _lifeDay(json, 'lifeDay', '活动反馈'),
    subcategorySnapshot: _enumByCode(
      ActivitySubcategory.values,
      _string(json, 'subcategorySnapshot', '活动反馈'),
      (value) => value.code,
      '活动反馈子类',
    ),
    durationSnapshot: _duration(_int(json, 'durationMinutesSnapshot', '活动反馈')),
    theoreticalDeltaSnapshot: _int(json, 'theoreticalDeltaSnapshot', '活动反馈'),
    appliedDeltaSnapshot: _int(json, 'appliedDeltaSnapshot', '活动反馈'),
    impactSignSnapshot: _enumByCode(
      ActivityImpactSign.values,
      _string(json, 'impactSignSnapshot', '活动反馈'),
      (value) => value.code,
      '活动反馈影响方向',
    ),
    ruleVersionSnapshot: _string(json, 'ruleVersionSnapshot', '活动反馈'),
    activityUpdatedAtSnapshot: _date(json, 'activityUpdatedAtSnapshot', '活动反馈'),
    direction: _enumByCode(
      ActivityFeedbackDirection.values,
      _string(json, 'direction', '活动反馈'),
      (value) => value.code,
      '活动反馈方向',
    ),
    status: _enumByCode(
      ActivityFeedbackStatus.values,
      _string(json, 'status', '活动反馈'),
      (value) => value.code,
      '活动反馈状态',
    ),
    invalidationReason: invalidationCode == null
        ? null
        : _enumByCode<ActivityFeedbackInvalidationReason>(
            ActivityFeedbackInvalidationReason.values,
            invalidationCode,
            (value) => value.code,
            '活动反馈失效原因',
          ),
    observedAt: _date(json, 'observedAt', '活动反馈'),
  );
}

DailySummary _parseSummary(Map<String, Object?> json) {
  final categoriesJson = _map(json, 'categorySummaries', '日总结');
  final categories = <ActivityCategory, CategoryEstimatedSummary>{};
  for (final entry in categoriesJson.entries) {
    final category = _enumByCode(
      ActivityCategory.values,
      entry.key,
      (value) => value.code,
      '总结活动大类',
    );
    final value = _asMap(entry.value, '分类总结');
    if (categories.containsKey(category)) {
      throw const BackupFormatException('日总结包含重复活动大类。');
    }
    categories[category] = CategoryEstimatedSummary(
      category: category,
      durationMinutes: _int(value, 'durationMinutes', '分类总结'),
      netDelta: _int(value, 'netDelta', '分类总结'),
      grossDelta: _int(value, 'grossDelta', '分类总结'),
    );
  }
  return DailySummary(
    lifeDay: _lifeDay(json, 'lifeDay', '日总结'),
    baseEstimatedEnergy: _int(json, 'baseEstimatedEnergy', '日总结'),
    ruleVersion: _string(json, 'ruleVersion', '日总结'),
    morningAdjustment: _int(json, 'morningAdjustment', '日总结'),
    shortTermAdjustment: _int(json, 'shortTermAdjustment', '日总结'),
    initialEstimatedEnergy: _int(json, 'initialEstimatedEnergy', '日总结'),
    finalEstimatedEnergy: _int(json, 'finalEstimatedEnergy', '日总结'),
    totalConsumption: _int(json, 'totalConsumption', '日总结'),
    totalRecovery: _int(json, 'totalRecovery', '日总结'),
    categorySummaries: categories,
    isStandardEffectiveDay: _bool(json, 'isStandardEffectiveDay', '日总结'),
    isWeakEffectiveDay: _bool(json, 'isWeakEffectiveDay', '日总结'),
    settledAt: _date(json, 'settledAt', '日总结'),
  );
}

PromptReceipt _parseReceipt(Map<String, Object?> json) {
  return PromptReceipt(
    id: _string(json, 'id', '提醒回执'),
    type: _enumByCode(
      PromptReceiptType.values,
      _string(json, 'type', '提醒回执'),
      (value) => value.code,
      '提醒类型',
    ),
    scopeKey: _string(json, 'scopeKey', '提醒回执'),
    action: _enumByCode(
      PromptReceiptAction.values,
      _string(json, 'action', '提醒回执'),
      (value) => value.code,
      '提醒动作',
    ),
    occurredAt: _date(json, 'occurredAt', '提醒回执'),
  );
}

void _validateBackup(PowerManagerExportDto backup) {
  final settings = backup.appSettings;
  _range(settings.baseEstimatedEnergy, 60, 140, '基准线');
  if (settings.pendingBaseEstimatedEnergy case final pending?) {
    _range(pending, 60, 140, '待生效基准线');
  }
  _paired(
    settings.pendingBaseEstimatedEnergy,
    settings.baseEnergyEffectiveLifeDay,
    '待生效基准线',
  );
  _paired(
    settings.pendingRuleVersion,
    settings.pendingRuleEffectiveLifeDay,
    '待生效规则',
  );
  if (settings.createdAt.isAfter(settings.updatedAt)) {
    throw const BackupFormatException('设置时间顺序不合法。');
  }

  final rulesByVersion = <String, EnergyRuleConfig>{};
  for (final version in backup.ruleVersions) {
    _nonEmpty(version.version, '规则版本');
    if (rulesByVersion.containsKey(version.version)) {
      throw const BackupFormatException('规则版本重复。');
    }
    rulesByVersion[version.version] = _ruleConfig(version);
  }
  if (!rulesByVersion.containsKey(settings.activeRuleVersion) ||
      (settings.pendingRuleVersion != null &&
          !rulesByVersion.containsKey(settings.pendingRuleVersion))) {
    throw const BackupFormatException('设置引用了不存在的规则版本。');
  }

  final morningIds = <String>{};
  final morningsByDay = <LifeDay, MorningCheckIn>{};
  for (final morning in backup.morningCheckIns) {
    _unique(morningIds, morning.id, '晨间确认 ID');
    if (morningsByDay.putIfAbsent(morning.lifeDay, () => morning) != morning) {
      throw const BackupFormatException('同一生活日存在多条晨间确认。');
    }
    if (morning.overallState == MorningOverallState.skipped ||
        morning.morningAdjustment != morning.overallState.adjustment) {
      throw const BackupFormatException('晨间确认调整值不合法。');
    }
  }

  final activityIds = <String>{};
  final activitiesById = <String, StoredEstimatedActivity>{};
  final activitiesByDay = <LifeDay, List<StoredEstimatedActivity>>{};
  for (final activity in backup.activityRecords) {
    _unique(activityIds, activity.id, '活动 ID');
    activitiesById[activity.id] = activity;
    if (activity.category != activity.subcategory.category ||
        activity.createdAt.isAfter(activity.updatedAt)) {
      throw const BackupFormatException('活动记录关系或时间顺序不合法。');
    }
    final deletedShape =
        activity.status == ActivityRecordStatus.deleted &&
        activity.deletedAt != null;
    final activeShape =
        activity.status == ActivityRecordStatus.active &&
        activity.deletedAt == null;
    if (!deletedShape && !activeShape) {
      throw const BackupFormatException('活动删除状态不合法。');
    }
    final config = rulesByVersion[activity.ruleVersion];
    if (config == null ||
        config.theoreticalDelta(activity.subcategory, activity.duration) !=
            activity.theoreticalDelta) {
      throw const BackupFormatException('活动规则版本或理论变化值不合法。');
    }
    activitiesByDay.putIfAbsent(activity.lifeDay, () => []).add(activity);
  }

  final observationIds = <String>{};
  final dailyAbsoluteDays = <LifeDay>{};
  for (final observation in backup.energyObservations) {
    _unique(observationIds, observation.id, '实际状态 ID');
    _validateObservation(observation, rulesByVersion);
    if (observation.type == EnergyObservationType.dailyAbsolute &&
        !dailyAbsoluteDays.add(observation.lifeDay)) {
      throw const BackupFormatException('同一生活日存在多条每日实际状态。');
    }
  }

  final feedbackIds = <String>{};
  final activeFeedbackActivities = <String>{};
  for (final feedback in backup.activityFeedback) {
    _unique(feedbackIds, feedback.id, '活动反馈 ID');
    _validateFeedback(
      feedback,
      activitiesById: activitiesById,
      rulesByVersion: rulesByVersion,
      activeFeedbackActivities: activeFeedbackActivities,
    );
  }

  final summariesByDay = <LifeDay, DailySummary>{};
  for (final summary in backup.dailySummaries) {
    if (summariesByDay.putIfAbsent(summary.lifeDay, () => summary) != summary) {
      throw const BackupFormatException('同一生活日存在多条日总结。');
    }
    _range(summary.baseEstimatedEnergy, 60, 140, '日总结基准线');
    if (!const {-6, 0, 6}.contains(summary.morningAdjustment) ||
        summary.shortTermAdjustment < -4 ||
        summary.shortTermAdjustment > 0 ||
        summary.totalConsumption < 0 ||
        summary.totalRecovery < 0 ||
        (summary.isStandardEffectiveDay && summary.isWeakEffectiveDay) ||
        !rulesByVersion.containsKey(summary.ruleVersion)) {
      throw const BackupFormatException('日总结基础字段不合法。');
    }
    if (summary.categorySummaries.length != ActivityCategory.values.length ||
        summary.categorySummaries.values.any(
          (value) => value.durationMinutes < 0 || value.grossDelta < 0,
        )) {
      throw const BackupFormatException('日总结分类汇总不完整。');
    }
  }

  _validateReplays(
    settings: settings,
    morningsByDay: morningsByDay,
    activitiesByDay: activitiesByDay,
    summariesByDay: summariesByDay,
  );

  final receiptIds = <String>{};
  final receiptKeys = <String>{};
  for (final receipt in backup.promptReceipts) {
    _unique(receiptIds, receipt.id, '提醒回执 ID');
    _nonEmpty(receipt.scopeKey, '提醒范围');
    final key =
        '${receipt.type.code}\u0000${receipt.scopeKey}\u0000${receipt.action.code}';
    if (!receiptKeys.add(key)) {
      throw const BackupFormatException('提醒回执唯一键重复。');
    }
  }
}

void _validateObservation(
  EnergyObservation observation,
  Map<String, EnergyRuleConfig> rulesByVersion,
) {
  final baseShape = switch (observation.type) {
    EnergyObservationType.dailyAbsolute =>
      observation.absoluteState != null && observation.relativeState == null,
    EnergyObservationType.relativeCorrection =>
      observation.absoluteState == null &&
          observation.relativeState != null &&
          observation.estimateAtObservation != null,
  };
  if (!baseShape) {
    throw const BackupFormatException('实际状态字段组合不合法。');
  }

  if (observation.contractVersion == null) {
    final legacyShape =
        observation.referenceType == null &&
        observation.initialEstimateAtObservation == null &&
        observation.estimatedOrdinalAtObservation == null &&
        observation.baseEnergyAtObservation == null &&
        observation.ruleVersionAtObservation == null &&
        observation.comparisonBandVersion == null &&
        observation.personalizationVersionAtObservation == null &&
        observation.effectiveModelFingerprintAtObservation == null &&
        observation.modelRegimeEpochAtObservation == null &&
        observation.activeActivityCountAtObservation == null &&
        (observation.coverageState == null ||
            observation.coverageState ==
                ObservationCoverageState.legacyUnknown) &&
        observation.modelRegimeKey == null;
    if (!legacyShape) {
      throw const BackupFormatException('Legacy 实际状态包含了伪造的新合同快照。');
    }
    return;
  }

  final initial = observation.initialEstimateAtObservation;
  final ordinal = observation.estimatedOrdinalAtObservation;
  final base = observation.baseEnergyAtObservation;
  final activeCount = observation.activeActivityCountAtObservation;
  final ruleVersion = observation.ruleVersionAtObservation;
  final completeContract =
      observation.contractVersion == mvpBObservationContractV1 &&
      observation.type == EnergyObservationType.dailyAbsolute &&
      observation.estimateAtObservation != null &&
      observation.referenceType != null &&
      initial != null &&
      initial > 0 &&
      ordinal != null &&
      ordinal >= 0 &&
      ordinal <= 4 &&
      base != null &&
      base >= 60 &&
      base <= 140 &&
      ruleVersion != null &&
      rulesByVersion.containsKey(ruleVersion) &&
      observation.comparisonBandVersion != null &&
      observation.personalizationVersionAtObservation != null &&
      observation.effectiveModelFingerprintAtObservation != null &&
      observation.modelRegimeEpochAtObservation != null &&
      activeCount != null &&
      activeCount >= 0 &&
      (observation.coverageState == ObservationCoverageState.confirmed ||
          observation.coverageState == ObservationCoverageState.uncertain) &&
      observation.modelRegimeKey != null;
  if (!completeContract) {
    throw const BackupFormatException('MVP-B 实际状态合同字段不完整。');
  }
  _nonEmpty(ruleVersion, '观测规则版本');
  _nonEmpty(observation.comparisonBandVersion!, '比较档位版本');
  _nonEmpty(observation.personalizationVersionAtObservation!, '观测个性化版本');
  _nonEmpty(observation.effectiveModelFingerprintAtObservation!, '观测模型指纹');
  _nonEmpty(observation.modelRegimeEpochAtObservation!, '观测模型窗口');
  _nonEmpty(observation.modelRegimeKey!, '观测模型分组键');
  if (observation.comparisonBandVersion != mvpBComparisonBandV1) {
    throw const BackupFormatException('观测比较档位版本不受支持。');
  }
  final comparison = const ObservationComparisonService().compare(
    actualState: observation.absoluteState!,
    estimate: observation.estimateAtObservation!,
    initialEstimate: initial,
  );
  if (!comparison.isValid || comparison.estimatedOrdinal != ordinal) {
    throw const BackupFormatException('观测估计档位快照不一致。');
  }
  final expectedModelRegimeKey = const ModelRegimeKeyBuilder().build(
    referenceType: observation.referenceType!,
    baseEnergy: base,
    ruleVersion: ruleVersion,
    comparisonBandVersion: observation.comparisonBandVersion!,
    effectiveModelFingerprint:
        observation.effectiveModelFingerprintAtObservation!,
    modelRegimeEpoch: observation.modelRegimeEpochAtObservation!,
  );
  if (observation.modelRegimeKey != expectedModelRegimeKey) {
    throw const BackupFormatException('观测模型分组键与快照不一致。');
  }
}

void _validateFeedback(
  ActivityFeedback feedback, {
  required Map<String, StoredEstimatedActivity> activitiesById,
  required Map<String, EnergyRuleConfig> rulesByVersion,
  required Set<String> activeFeedbackActivities,
}) {
  _nonEmpty(feedback.activityRecordId, '活动反馈关联活动');
  _nonEmpty(feedback.ruleVersionSnapshot, '活动反馈规则版本');
  final activity = activitiesById[feedback.activityRecordId];
  final rule = rulesByVersion[feedback.ruleVersionSnapshot];
  if (activity == null ||
      rule == null ||
      rule.theoreticalDelta(
            feedback.subcategorySnapshot,
            feedback.durationSnapshot,
          ) !=
          feedback.theoreticalDeltaSnapshot ||
      _impactSign(feedback.theoreticalDeltaSnapshot) !=
          feedback.impactSignSnapshot ||
      feedback.activityUpdatedAtSnapshot.isAfter(feedback.observedAt)) {
    throw const BackupFormatException('活动反馈快照或引用不合法。');
  }

  final activeShape =
      feedback.status == ActivityFeedbackStatus.active &&
      feedback.invalidationReason == null;
  final invalidatedShape =
      feedback.status == ActivityFeedbackStatus.invalidated &&
      feedback.invalidationReason != null;
  if (!activeShape && !invalidatedShape) {
    throw const BackupFormatException('活动反馈失效状态不合法。');
  }

  if (activeShape) {
    if (!activeFeedbackActivities.add(feedback.activityRecordId)) {
      throw const BackupFormatException('同一活动存在多条 active 反馈。');
    }
    final currentSnapshotMatches =
        activity.status == ActivityRecordStatus.active &&
        activity.lifeDay == feedback.lifeDay &&
        activity.subcategory == feedback.subcategorySnapshot &&
        activity.duration == feedback.durationSnapshot &&
        activity.theoreticalDelta == feedback.theoreticalDeltaSnapshot &&
        activity.appliedDelta == feedback.appliedDeltaSnapshot &&
        activity.ruleVersion == feedback.ruleVersionSnapshot &&
        activity.updatedAt == feedback.activityUpdatedAtSnapshot;
    if (!currentSnapshotMatches) {
      throw const BackupFormatException('Active 活动反馈与当前活动快照不一致。');
    }
  }
}

ActivityImpactSign _impactSign(int theoreticalDelta) {
  if (theoreticalDelta < 0) return ActivityImpactSign.consumption;
  if (theoreticalDelta > 0) return ActivityImpactSign.recovery;
  return ActivityImpactSign.zero;
}

void _validateReplays({
  required AppSettings settings,
  required Map<LifeDay, MorningCheckIn> morningsByDay,
  required Map<LifeDay, List<StoredEstimatedActivity>> activitiesByDay,
  required Map<LifeDay, DailySummary> summariesByDay,
}) {
  const calculator = EnergyCalculator();
  const projector = CurrentDayProjector();
  final allDays = <LifeDay>{
    ...activitiesByDay.keys,
    ...summariesByDay.keys,
  }.toList()..sort();
  for (final day in allDays) {
    final summary = summariesByDay[day];
    final morning = morningsByDay[day];
    final previousSummary = summariesByDay[day.previous];
    final shortTerm = calculator.calculateShortTermAdjustment(
      previousSummary?.finalEstimatedEnergy,
    );
    final base = summary?.baseEstimatedEnergy ?? settings.baseEstimatedEnergy;
    final morningAdjustment = morning?.morningAdjustment ?? 0;
    final initial = base + morningAdjustment + shortTerm;
    if (summary != null &&
        (summary.morningAdjustment != morningAdjustment ||
            summary.shortTermAdjustment != shortTerm ||
            summary.initialEstimatedEnergy != initial)) {
      throw const BackupFormatException('日总结初始估计无法通过稳定重放。');
    }
    final projection = projector.project(
      initialEstimate: initial,
      records: (activitiesByDay[day] ?? const []).map(
        (activity) => activity.toReplayRecord(),
      ),
      morningCheckInCompleted: morning != null,
    );
    final projectedById = {
      for (final item in projection.activities)
        item.record.id: item.appliedDelta,
    };
    for (final activity in activitiesByDay[day] ?? const []) {
      if (activity.status == ActivityRecordStatus.active &&
          projectedById[activity.id] != activity.appliedDelta) {
        throw const BackupFormatException('活动应用变化值无法通过稳定重放。');
      }
    }
    if (summary != null &&
        (summary.finalEstimatedEnergy != projection.currentEstimate ||
            summary.totalConsumption != projection.totalConsumption ||
            summary.totalRecovery != projection.totalRecovery ||
            summary.isStandardEffectiveDay !=
                projection.isStandardEffectiveDay ||
            summary.isWeakEffectiveDay != projection.isWeakEffectiveDay ||
            !_sameCategories(
              summary.categorySummaries,
              projection.categorySummaries,
            ))) {
      throw const BackupFormatException('日总结无法通过稳定重放。');
    }
  }
}

bool _sameCategories(
  Map<ActivityCategory, CategoryEstimatedSummary> left,
  Map<ActivityCategory, CategoryEstimatedSummary> right,
) {
  return ActivityCategory.values.every((category) {
    final a = left[category];
    final b = right[category];
    return a != null &&
        b != null &&
        a.durationMinutes == b.durationMinutes &&
        a.netDelta == b.netDelta &&
        a.grossDelta == b.grossDelta;
  });
}

EnergyRuleConfig _ruleConfig(RuleConfigVersion version) {
  final values = version.values;
  if (values['ruleVersion'] != version.version) {
    throw const BackupFormatException('规则正文版本与外层版本不一致。');
  }
  final activityRules = _map(values, 'activityRules', '规则正文');
  final rules = <SubcategoryEnergyRule>[];
  for (final subcategory in ActivitySubcategory.values) {
    final row = _asMap(activityRules[subcategory.code], '活动规则');
    rules.add(
      SubcategoryEnergyRule(
        subcategory: subcategory,
        deltas: {
          for (final duration in DurationSlot.values)
            duration: _int(row, '${duration.minutes}', '活动规则'),
        },
      ),
    );
  }
  final config = EnergyRuleConfig(ruleVersion: version.version, rules: rules);
  if (config.validate().isNotEmpty ||
      activityRules.length != ActivitySubcategory.values.length) {
    throw const BackupFormatException('规则正文不完整。');
  }
  return config;
}

Map<String, Object?> _map(
  Map<String, Object?> json,
  String key,
  String context,
) => _asMap(json[key], '$context.$key');

void _requireKeys(Map<String, Object?> json, Set<String> keys, String context) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      throw BackupFormatException('$context.$key 缺失。');
    }
  }
}

Map<String, Object?> _asMap(Object? value, String context) {
  if (value is! Map<String, Object?>) {
    throw BackupFormatException('$context 必须是对象。');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw BackupFormatException('$context.$key 必须是数组。');
  }
  return value;
}

String _string(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value is! String) {
    throw BackupFormatException('$context.$key 必须是文本。');
  }
  return value;
}

String? _nullableString(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw BackupFormatException('$context.$key 必须是文本或 null。');
  }
  return value;
}

int _int(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value is! int) {
    throw BackupFormatException('$context.$key 必须是整数。');
  }
  return value;
}

int? _nullableInt(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw BackupFormatException('$context.$key 必须是整数或 null。');
  }
  return value;
}

bool _bool(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value is! bool) {
    throw BackupFormatException('$context.$key 必须是布尔值。');
  }
  return value;
}

DateTime _date(Map<String, Object?> json, String key, String context) {
  final value = _string(json, key, context);
  if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw BackupFormatException('$context.$key 必须包含时区。');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw BackupFormatException('$context.$key 不是合法时间。');
  }
  return parsed.toUtc();
}

DateTime? _nullableDate(Map<String, Object?> json, String key, String context) {
  if (json[key] == null) return null;
  return _date(json, key, context);
}

LifeDay _lifeDay(Map<String, Object?> json, String key, String context) {
  try {
    return LifeDay.parse(_string(json, key, context));
  } on Object {
    throw BackupFormatException('$context.$key 不是合法生活日。');
  }
}

LifeDay? _nullableLifeDay(
  Map<String, Object?> json,
  String key,
  String context,
) {
  if (json[key] == null) return null;
  return _lifeDay(json, key, context);
}

DurationSlot _duration(int minutes) {
  try {
    return DurationSlot.fromMinutes(minutes);
  } on Object {
    throw const BackupFormatException('活动时长档位不受支持。');
  }
}

T _enumByCode<T>(
  Iterable<T> values,
  String code,
  String Function(T value) codeOf,
  String description,
) {
  for (final value in values) {
    if (codeOf(value) == code) return value;
  }
  throw BackupFormatException('$description包含未知值。');
}

void _range(int value, int min, int max, String description) {
  if (value < min || value > max) {
    throw BackupFormatException('$description超出允许范围。');
  }
}

void _paired(Object? left, Object? right, String description) {
  if ((left == null) != (right == null)) {
    throw BackupFormatException('$description字段必须同时存在或同时为空。');
  }
}

void _nonEmpty(String value, String description) {
  if (value.trim().isEmpty) {
    throw BackupFormatException('$description不能为空。');
  }
}

void _unique(Set<String> values, String value, String description) {
  _nonEmpty(value, description);
  if (!values.add(value)) {
    throw BackupFormatException('$description重复。');
  }
}
