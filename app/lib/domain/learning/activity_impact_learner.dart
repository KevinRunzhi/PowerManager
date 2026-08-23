import 'dart:collection';
import 'dart:math' as math;
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

/// The learner consumes a joined, immutable sample/feedback/activity row.  A
/// caller must provide the settled-day fact explicitly so a still-editable
/// day cannot accidentally become learning evidence.
final class ActivityImpactLearningObservation {
  const ActivityImpactLearningObservation({
    required this.activity,
    required this.sample,
    required this.feedback,
    required this.lifeDaySettled,
  });

  final StoredEstimatedActivity activity;
  final ActivityFeedbackSample sample;
  final ActivityFeedback feedback;
  final bool lifeDaySettled;
}

final class ActivityImpactLearningConfig {
  const ActivityImpactLearningConfig({
    this.policy = const ActivityImpactSamplingPolicyV1(),
    this.mode = LearningMode.review,
    this.productionLearningEnabled = false,
    this.automaticLearningEngineEnabled = false,
    this.automaticApplyEnabled = false,
  });

  final ActivityImpactSamplingPolicyV1 policy;
  final LearningMode mode;
  final bool productionLearningEnabled;
  final bool automaticLearningEngineEnabled;

  /// Automatic mode is a production write path.  Keep candidate generation
  /// fail-closed unless the separate apply gate is explicitly open.
  final bool automaticApplyEnabled;

  bool get isValid => policy.isValid;

  bool get executableCandidate =>
      productionLearningEnabled &&
      automaticLearningEngineEnabled &&
      (mode != LearningMode.automatic || automaticApplyEnabled) &&
      mode != LearningMode.off;
}

final class ActivityImpactLearningCurrentModel {
  ActivityImpactLearningCurrentModel({
    required this.personalizationVersionId,
    required this.factorRegimeStartedLifeDay,
    required Map<ActivityImpactKey, double> factors,
  }) : factors = UnmodifiableMapView({...factors});

  final String personalizationVersionId;
  final LifeDay factorRegimeStartedLifeDay;
  final Map<ActivityImpactKey, double> factors;

  double factorFor(ActivityImpactKey key, double fallback) =>
      factors[key] ?? fallback;
}

final class ActivityImpactFactorCandidate {
  const ActivityImpactFactorCandidate({
    required this.key,
    required this.currentFactor,
    required this.candidateFactor,
    required this.sampleCount,
    required this.coverageDays,
    required this.strongerCount,
    required this.weakerCount,
  });

  final ActivityImpactKey key;
  final double currentFactor;
  final double candidateFactor;
  final int sampleCount;
  final int coverageDays;
  final int strongerCount;
  final int weakerCount;

  Map<String, Object?> toJson() => {
    'factorBps': _factorBps(candidateFactor),
    'baseActivityRuleVersion': activityImpactSupportedRuleVersion,
    'sampleCount': sampleCount,
    'coverageDays': coverageDays,
  };
}

final class ActivityImpactKeyLearningAudit {
  const ActivityImpactKeyLearningAudit({
    required this.key,
    required this.sampleCount,
    required this.coverageDays,
    required this.strongerCount,
    required this.aboutRightCount,
    required this.weakerCount,
    required this.directionMismatchCount,
    required this.durationSpanMinutes,
    required this.result,
    required this.reasonCodes,
  });

  final ActivityImpactKey key;
  final int sampleCount;
  final int coverageDays;
  final int strongerCount;
  final int aboutRightCount;
  final int weakerCount;
  final int directionMismatchCount;
  final int durationSpanMinutes;
  final LearningRunResult result;
  final List<String> reasonCodes;
}

final class ActivityImpactLearningEvaluation {
  ActivityImpactLearningEvaluation({
    required this.result,
    required List<String> reasonCodes,
    required List<ActivityImpactFactorCandidate> candidates,
    required List<ActivityImpactKeyLearningAudit> audits,
    required this.currentValuesJson,
    required this.candidateValuesJson,
    required this.evidenceSnapshotJson,
    required this.evidenceHash,
    required this.candidateExecutable,
  }) : reasonCodes = List.unmodifiable(reasonCodes),
       candidates = List.unmodifiable(candidates),
       audits = List.unmodifiable(audits);

  final LearningRunResult result;
  final List<String> reasonCodes;
  final List<ActivityImpactFactorCandidate> candidates;
  final List<ActivityImpactKeyLearningAudit> audits;
  final String currentValuesJson;
  final String? candidateValuesJson;
  final String evidenceSnapshotJson;
  final String evidenceHash;
  final bool candidateExecutable;

  bool get isCandidate => result == LearningRunResult.candidate;
}

/// B3-1 pure learner.  It only generates a deterministic shadow candidate;
/// persistence, lifecycle transitions, activation, and automatic scheduling
/// remain outside this class.  In particular, user-initiated feedback never
/// crosses this API's eligibility boundary.
final class ActivityImpactLearner {
  const ActivityImpactLearner({this.encoder = const CanonicalJsonEncoder()});

  final CanonicalJsonEncoder encoder;

  ActivityImpactLearningEvaluation evaluate({
    required Iterable<ActivityImpactLearningObservation> observations,
    required ActivityImpactLearningCurrentModel current,
    ActivityImpactLearningConfig config = const ActivityImpactLearningConfig(),
  }) {
    final all = observations.toList(growable: false);
    final ordered = [...all]
      ..sort((a, b) => a.feedback.id.compareTo(b.feedback.id));
    final currentValues = _valuesJson(current.factors);
    if (!config.isValid) {
      return _blocked(
        all: all,
        currentValues: currentValues,
        reason: 'invalidActivityImpactConfiguration',
      );
    }
    if (config.mode == LearningMode.off) {
      return _blocked(
        all: all,
        currentValues: currentValues,
        reason: 'activityImpactLearningModeOff',
      );
    }
    if (config.mode == LearningMode.automatic &&
        !config.automaticApplyEnabled) {
      return _blocked(
        all: all,
        currentValues: currentValues,
        reason: 'automaticApplyDisabled',
      );
    }

    final grouped = <ActivityImpactKey, List<_AcceptedObservation>>{};
    final exclusionReasons = <String, String>{};
    for (final item in all) {
      final reason = _ineligibilityReason(item, current, config.policy);
      if (reason != null) {
        exclusionReasons[item.feedback.id] = reason;
        continue;
      }
      final key = ActivityImpactKey(
        subcategory: item.feedback.subcategorySnapshot,
        impactSign: item.feedback.impactSignSnapshot,
      );
      grouped
          .putIfAbsent(key, () => [])
          .add(_AcceptedObservation(item, item.feedback.direction));
    }

    final keys = grouped.keys.toList()..sort();
    final candidates = <ActivityImpactFactorCandidate>[];
    final audits = <ActivityImpactKeyLearningAudit>[];
    final reasons = <String>{...exclusionReasons.values};
    var hasUnstable = false;
    var hasInsufficient = false;
    var hasNoChange = false;

    for (final key in keys) {
      final values = grouped[key]!;
      final audit = _evaluateKey(key, values, current, config.policy);
      audits.add(audit.audit);
      reasons.addAll(audit.audit.reasonCodes);
      switch (audit.audit.result) {
        case LearningRunResult.candidate:
          candidates.add(audit.candidate!);
        case LearningRunResult.unstable:
          hasUnstable = true;
        case LearningRunResult.insufficientEvidence:
          hasInsufficient = true;
        case LearningRunResult.noChange:
          hasNoChange = true;
        default:
          break;
      }
    }

    final result = candidates.isNotEmpty
        ? LearningRunResult.candidate
        : hasUnstable
        ? LearningRunResult.unstable
        : hasInsufficient || grouped.isEmpty
        ? LearningRunResult.insufficientEvidence
        : hasNoChange
        ? LearningRunResult.noChange
        : LearningRunResult.insufficientEvidence;
    if (result == LearningRunResult.candidate && !config.executableCandidate) {
      reasons.add('preproductionCandidateNotExecutable');
    }
    final candidateJson = result == LearningRunResult.candidate
        ? encoder.encode({
            'factors': {
              for (final candidate in candidates)
                candidate.key.value: candidate.toJson(),
            },
          })
        : null;
    final evidenceJson = encoder.encode({
      'algorithmVersion': activityImpactSamplingAlgorithmV1,
      'policyVersion': config.policy.policyVersion,
      'currentPersonalizationVersionId': current.personalizationVersionId,
      'currentFactorRegimeStartedLifeDay': current.factorRegimeStartedLifeDay
          .toString(),
      'observations': [
        for (final item in ordered)
          _observationJson(
            item,
            exclusionReason: exclusionReasons[item.feedback.id],
          ),
      ],
    });
    return ActivityImpactLearningEvaluation(
      result: result,
      reasonCodes: reasons.toList()..sort(),
      candidates: candidates,
      audits: audits,
      currentValuesJson: currentValues,
      candidateValuesJson: candidateJson,
      evidenceSnapshotJson: evidenceJson,
      evidenceHash: sha256.convert(utf8.encode(evidenceJson)).toString(),
      candidateExecutable:
          result == LearningRunResult.candidate && config.executableCandidate,
    );
  }

  ActivityImpactLearningEvaluation _blocked({
    required List<ActivityImpactLearningObservation> all,
    required String currentValues,
    required String reason,
  }) {
    final evidenceJson = encoder.encode({
      'algorithmVersion': activityImpactSamplingAlgorithmV1,
      'observations': [for (final item in all) _observationJson(item)],
    });
    return ActivityImpactLearningEvaluation(
      result: LearningRunResult.configurationBlocked,
      reasonCodes: [reason],
      candidates: const [],
      audits: const [],
      currentValuesJson: currentValues,
      candidateValuesJson: null,
      evidenceSnapshotJson: evidenceJson,
      evidenceHash: sha256.convert(utf8.encode(evidenceJson)).toString(),
      candidateExecutable: false,
    );
  }

  _KeyEvaluation _evaluateKey(
    ActivityImpactKey key,
    List<_AcceptedObservation> values,
    ActivityImpactLearningCurrentModel current,
    ActivityImpactSamplingPolicyV1 policy,
  ) {
    final mismatch = values
        .where(
          (value) =>
              value.direction == ActivityFeedbackDirection.directionMismatch,
        )
        .length;
    final stronger = values
        .where(
          (value) =>
              value.direction == ActivityFeedbackDirection.strongerImpact,
        )
        .length;
    final aboutRight = values
        .where(
          (value) => value.direction == ActivityFeedbackDirection.aboutRight,
        )
        .length;
    final weaker = values
        .where(
          (value) => value.direction == ActivityFeedbackDirection.weakerImpact,
        )
        .length;
    final days = values.map((value) => value.item.feedback.lifeDay).toSet();
    final durations = values
        .map((value) => value.item.feedback.durationSnapshot.minutes)
        .toList();
    final span = durations.isEmpty
        ? 0
        : durations.reduce(math.max) - durations.reduce(math.min);
    final reasonCodes = <String>[];
    var result = LearningRunResult.candidate;
    ActivityImpactFactorCandidate? candidate;
    if (mismatch >= policy.minimumDirectionMismatchCount &&
        mismatch / values.length >= policy.directionMismatchVetoRatio) {
      result = LearningRunResult.unstable;
      reasonCodes.add('directionMismatchVeto');
    } else if (span > policy.maximumDurationSpanMinutes) {
      result = LearningRunResult.unstable;
      reasonCodes.add('durationHeterogeneity');
    } else if (values.length - mismatch < policy.minimumSamplesPerKey ||
        days.length < policy.minimumCoverageDays) {
      result = LearningRunResult.insufficientEvidence;
      reasonCodes.add('minimumSampleOrDayNotMet');
    } else {
      final currentFactor = current.factorFor(
        key,
        values.first.item.feedback.factorSnapshot,
      );
      final deltaDirection = stronger.compareTo(weaker);
      if (deltaDirection == 0) {
        result = LearningRunResult.noChange;
        reasonCodes.add('balancedDirectionEvidence');
      } else {
        final next = _stepFactor(
          currentFactor,
          deltaDirection > 0 ? policy.factorStep : -policy.factorStep,
        );
        if (!policy.isFactorInRange(currentFactor) ||
            !policy.isFactorInRange(next) ||
            next == currentFactor) {
          result = LearningRunResult.noChange;
          reasonCodes.add('factorBoundaryOrStep');
        } else {
          candidate = ActivityImpactFactorCandidate(
            key: key,
            currentFactor: currentFactor,
            candidateFactor: next,
            sampleCount: values.length - mismatch,
            coverageDays: days.length,
            strongerCount: stronger,
            weakerCount: weaker,
          );
          reasonCodes.add('factorCandidate');
        }
      }
    }
    return _KeyEvaluation(
      audit: ActivityImpactKeyLearningAudit(
        key: key,
        sampleCount: values.length - mismatch,
        coverageDays: days.length,
        strongerCount: stronger,
        aboutRightCount: aboutRight,
        weakerCount: weaker,
        directionMismatchCount: mismatch,
        durationSpanMinutes: span,
        result: result,
        reasonCodes: List.unmodifiable(reasonCodes),
      ),
      candidate: candidate,
    );
  }

  String? _ineligibilityReason(
    ActivityImpactLearningObservation item,
    ActivityImpactLearningCurrentModel current,
    ActivityImpactSamplingPolicyV1 policy,
  ) {
    final activity = item.activity;
    final sample = item.sample;
    final feedback = item.feedback;
    if (!item.lifeDaySettled) return 'lifeDayNotSettled';
    if (feedback.collectionSource !=
        ActivityFeedbackCollectionSource.sampledPrompt) {
      return 'userInitiatedFeedbackExcluded';
    }
    if (feedback.samplingPolicyVersion != policy.policyVersion ||
        sample.samplingPolicyVersion != policy.policyVersion) {
      return 'unsupportedSamplingPolicy';
    }
    if (sample.status != ActivityFeedbackSampleStatus.responded ||
        sample.feedbackId != feedback.id ||
        feedback.sampleId != sample.id ||
        sample.promptedAt == null ||
        sample.respondedAt == null ||
        feedback.sampledAt == null ||
        sample.isInvalidated ||
        feedback.status != ActivityFeedbackStatus.active) {
      return 'sampleOrFeedbackNotSettled';
    }
    if (activity.id != feedback.activityRecordId ||
        activity.lifeDay != feedback.lifeDay ||
        activity.subcategory != feedback.subcategorySnapshot ||
        activity.duration != feedback.durationSnapshot ||
        activity.ruleVersion != feedback.ruleVersionSnapshot ||
        !activity.updatedAt.toUtc().isAtSameMomentAs(
          feedback.activityUpdatedAtSnapshot.toUtc(),
        ) ||
        activity.defaultTheoreticalDelta !=
            feedback.defaultTheoreticalDeltaSnapshot ||
        activity.factor != feedback.factorSnapshot ||
        activity.personalizedTheoreticalDelta !=
            feedback.personalizedTheoreticalDeltaSnapshot ||
        activity.theoreticalDelta != feedback.theoreticalDeltaSnapshot ||
        activity.appliedDelta != feedback.appliedDeltaSnapshot) {
      return 'incompleteOrChangedSnapshot';
    }
    if (feedback.ruleVersionSnapshot != policy.supportedRuleVersion) {
      return 'unsupportedRuleVersion';
    }
    if (feedback.defaultTheoreticalDeltaSnapshot == 0 ||
        feedback.impactSignSnapshot == ActivityImpactSign.zero ||
        activityImpactContractSign(feedback.theoreticalDeltaSnapshot) !=
            feedback.impactSignSnapshot ||
        !policy.isFactorInRange(feedback.factorSnapshot) ||
        feedback.personalizedTheoreticalDeltaSnapshot !=
            (feedback.defaultTheoreticalDeltaSnapshot * feedback.factorSnapshot)
                .round() ||
        feedback.appliedDeltaSnapshot !=
            feedback.personalizedTheoreticalDeltaSnapshot) {
      return 'zeroOrTruncatedEvidence';
    }
    if (feedback.impactSignSnapshot == ActivityImpactSign.recovery &&
        feedback.appliedDeltaSnapshot < feedback.theoreticalDeltaSnapshot) {
      return 'zeroOrTruncatedEvidence';
    }
    if (feedback.personalizationVersionId != current.personalizationVersionId ||
        activity.personalizationVersionId != current.personalizationVersionId ||
        feedback.factorRegimeStartedLifeDay !=
            current.factorRegimeStartedLifeDay ||
        activity.factorRegimeStartedLifeDay !=
            current.factorRegimeStartedLifeDay ||
        feedback.factorRegimeStartedLifeDay!.compareTo(feedback.lifeDay) > 0) {
      return 'staleFactorRegime';
    }
    final key = ActivityImpactKey(
      subcategory: feedback.subcategorySnapshot,
      impactSign: feedback.impactSignSnapshot,
    );
    final currentFactor = current.factorFor(key, feedback.factorSnapshot);
    if (!currentFactor.isFinite ||
        (currentFactor - feedback.factorSnapshot).abs() > 0.0000001) {
      return 'factorSnapshotNotCurrent';
    }
    return null;
  }

  double _stepFactor(double current, double delta) {
    final value = current + delta;
    return (value * 100).roundToDouble() / 100;
  }

  String _valuesJson(Map<ActivityImpactKey, double> factors) => encoder.encode({
    'factors': {
      for (final entry
          in (factors.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        entry.key.value: {'factorBps': _factorBps(entry.value)},
    },
  });

  Map<String, Object?> _observationJson(
    ActivityImpactLearningObservation item, {
    String? exclusionReason,
  }) {
    final feedback = item.feedback;
    final result = <String, Object?>{
      'activityId': item.activity.id,
      'feedbackId': feedback.id,
      'sampleId': item.sample.id,
      'lifeDay': feedback.lifeDay.toString(),
      'subcategory': feedback.subcategorySnapshot.code,
      'durationMinutes': feedback.durationSnapshot.minutes,
      'defaultTheoreticalDelta': feedback.defaultTheoreticalDeltaSnapshot,
      'factorBps': _factorBps(feedback.factorSnapshot),
      'personalizedTheoreticalDelta':
          feedback.personalizedTheoreticalDeltaSnapshot,
      'appliedDelta': feedback.appliedDeltaSnapshot,
      'impactSign': feedback.impactSignSnapshot.code,
      'direction': feedback.direction.code,
      'collectionSource': feedback.collectionSource.code,
      'samplingPolicyVersion': feedback.samplingPolicyVersion,
      'sampleStatus': item.sample.status.code,
      'settled': item.lifeDaySettled,
    };
    if (exclusionReason != null) result['exclusionReason'] = exclusionReason;
    return result;
  }
}

final class _AcceptedObservation {
  const _AcceptedObservation(this.item, this.direction);

  final ActivityImpactLearningObservation item;
  final ActivityFeedbackDirection direction;
}

final class _KeyEvaluation {
  const _KeyEvaluation({required this.audit, required this.candidate});

  final ActivityImpactKeyLearningAudit audit;
  final ActivityImpactFactorCandidate? candidate;
}

int _factorBps(double factor) => (factor * 100).round();
