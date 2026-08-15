enum ActivityCategory {
  study(code: 'study', label: '学习'),
  practice(code: 'practice', label: '实践 / 事务'),
  recovery(code: 'recovery', label: '休息恢复'),
  leisure(code: 'leisure', label: '娱乐消遣');

  const ActivityCategory({required this.code, required this.label});

  final String code;
  final String label;
}

enum ActivitySubcategory {
  classAttendance(
    code: 'classAttendance',
    label: '上课',
    category: ActivityCategory.study,
  ),
  selfStudyOrThesis(
    code: 'selfStudyOrThesis',
    label: '自学 / 论文',
    category: ActivityCategory.study,
  ),
  homework(code: 'homework', label: '写作业', category: ActivityCategory.study),
  reviewOrExamPrep(
    code: 'reviewOrExamPrep',
    label: '复习 / 备考',
    category: ActivityCategory.study,
  ),
  organizeOrSummarize(
    code: 'organizeOrSummarize',
    label: '整理 / 总结',
    category: ActivityCategory.study,
  ),
  otherStudy(
    code: 'otherStudy',
    label: '其他学习',
    category: ActivityCategory.study,
  ),
  implementationOrDevelopment(
    code: 'implementationOrDevelopment',
    label: '实现 / 开发',
    category: ActivityCategory.practice,
  ),
  experiment(
    code: 'experiment',
    label: '做实验',
    category: ActivityCategory.practice,
  ),
  projectProgress(
    code: 'projectProgress',
    label: '项目推进',
    category: ActivityCategory.practice,
  ),
  debuggingOrRevision(
    code: 'debuggingOrRevision',
    label: '调试 / 修改',
    category: ActivityCategory.practice,
  ),
  organizationOrAdministration(
    code: 'organizationOrAdministration',
    label: '组织 / 事务',
    category: ActivityCategory.practice,
  ),
  otherPractice(
    code: 'otherPractice',
    label: '其他事务',
    category: ActivityCategory.practice,
  ),
  nap(code: 'nap', label: '午睡 / 小睡', category: ActivityCategory.recovery),
  lightActivity(
    code: 'lightActivity',
    label: '轻活动',
    category: ActivityCategory.recovery,
  ),
  mentalReset(
    code: 'mentalReset',
    label: '放空 / 调整',
    category: ActivityCategory.recovery,
  ),
  exerciseRecovery(
    code: 'exerciseRecovery',
    label: '运动恢复',
    category: ActivityCategory.recovery,
  ),
  lifeMaintenance(
    code: 'lifeMaintenance',
    label: '生活休整',
    category: ActivityCategory.recovery,
  ),
  otherRecovery(
    code: 'otherRecovery',
    label: '其他恢复',
    category: ActivityCategory.recovery,
  ),
  gaming(code: 'gaming', label: '打游戏', category: ActivityCategory.leisure),
  shortVideo(
    code: 'shortVideo',
    label: '刷视频 / 短内容',
    category: ActivityCategory.leisure,
  ),
  seriesOrMovie(
    code: 'seriesOrMovie',
    label: '看剧 / 观影',
    category: ActivityCategory.leisure,
  ),
  chatOrSocial(
    code: 'chatOrSocial',
    label: '聊天 / 社交',
    category: ActivityCategory.leisure,
  ),
  hobbyEntertainment(
    code: 'hobbyEntertainment',
    label: '兴趣娱乐',
    category: ActivityCategory.leisure,
  ),
  otherLeisure(
    code: 'otherLeisure',
    label: '其他娱乐',
    category: ActivityCategory.leisure,
  );

  const ActivitySubcategory({
    required this.code,
    required this.label,
    required this.category,
  });

  final String code;
  final String label;
  final ActivityCategory category;
}

enum DurationSlot {
  minutes15(15),
  minutes30(30),
  minutes45(45),
  minutes60(60),
  minutes90(90),
  minutes120(120);

  const DurationSlot(this.minutes);

  final int minutes;

  static DurationSlot fromMinutes(int minutes) {
    return values.firstWhere(
      (slot) => slot.minutes == minutes,
      orElse: () => throw ArgumentError.value(
        minutes,
        'minutes',
        'Unsupported duration slot',
      ),
    );
  }
}

enum MorningOverallState {
  bad(code: 'bad', adjustment: -6),
  normal(code: 'normal', adjustment: 0),
  good(code: 'good', adjustment: 6),
  skipped(code: 'skipped', adjustment: 0);

  const MorningOverallState({required this.code, required this.adjustment});

  final String code;
  final int adjustment;
}

enum SleepRecovery {
  bad('bad'),
  normal('normal'),
  good('good');

  const SleepRecovery(this.code);
  final String code;
}

enum FreeTimeLevel {
  low('low'),
  medium('medium'),
  high('high');

  const FreeTimeLevel(this.code);
  final String code;
}

enum PressureSource {
  study('study'),
  practice('practice'),
  both('both'),
  low('low');

  const PressureSource(this.code);
  final String code;
}

enum AbsoluteEnergyState {
  exhausted('exhausted'),
  low('low'),
  okay('okay'),
  good('good'),
  full('full');

  const AbsoluteEnergyState(this.code);
  final String code;
}

enum EnergyObservationType {
  dailyAbsolute('dailyAbsolute'),
  relativeCorrection('relativeCorrection');

  const EnergyObservationType(this.code);
  final String code;
}

const mvpBObservationContractV1 = 'mvp-b-observation-v1';

enum ObservationReferenceType {
  currentMoment('currentMoment'),
  previousLifeDayEnd('previousLifeDayEnd');

  const ObservationReferenceType(this.code);
  final String code;
}

enum ObservationCoverageState {
  confirmed('confirmed'),
  uncertain('uncertain'),
  legacyUnknown('legacyUnknown');

  const ObservationCoverageState(this.code);
  final String code;
}

enum ActivityImpactSign {
  consumption('consumption'),
  recovery('recovery'),
  zero('zero');

  const ActivityImpactSign(this.code);
  final String code;
}

enum ActivityFeedbackDirection {
  strongerImpact('strongerImpact'),
  aboutRight('aboutRight'),
  weakerImpact('weakerImpact'),
  directionMismatch('directionMismatch');

  const ActivityFeedbackDirection(this.code);
  final String code;
}

enum ActivityFeedbackStatus {
  active('active'),
  invalidated('invalidated');

  const ActivityFeedbackStatus(this.code);
  final String code;
}

enum ActivityFeedbackInvalidationReason {
  activityDeleted('activityDeleted'),
  activityEdited('activityEdited'),
  integrityFailure('integrityFailure');

  const ActivityFeedbackInvalidationReason(this.code);
  final String code;
}

enum RelativeCorrection {
  lowerThanEstimate('lower'),
  aboutRight('aboutRight'),
  higherThanEstimate('higher');

  const RelativeCorrection(this.code);
  final String code;
}

enum PromptReceiptType {
  onboarding('onboarding'),
  morning('morning'),
  dailyObservation('dailyObservation'),
  yesterday('yesterday'),
  energyBand('energyBand');

  const PromptReceiptType(this.code);
  final String code;
}

enum PromptReceiptAction {
  shown('shown'),
  skipped('skipped'),
  dismissed('dismissed');

  const PromptReceiptAction(this.code);
  final String code;
}

enum EstimatedEnergyBand {
  estimatedOverdraft('estimatedOverdraft'),
  estimatedLow('estimatedLow'),
  estimatedMediumLow('estimatedMediumLow'),
  estimatedNormal('estimatedNormal');

  const EstimatedEnergyBand(this.code);
  final String code;
}

enum ActivityRecordStatus {
  active('active'),
  deleted('deleted');

  const ActivityRecordStatus(this.code);
  final String code;
}
