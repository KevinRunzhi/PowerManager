import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:test/test.dart';

void main() {
  const encoder = CanonicalJsonEncoder();

  test('canonical JSON sorts every object and preserves list order', () {
    final value = <String, Object?>{
      'z': <Object?>[
        3,
        <String, Object?>{'é': '雪', 'a': true},
      ],
      'a': null,
      'quote': 'line\n"quoted"',
    };

    expect(
      encoder.encode(value),
      '{"a":null,"quote":"line\\n\\"quoted\\"",'
      '"z":[3,{"a":true,"é":"雪"}]}',
    );
    expect(
      encoder.encode(<String, Object?>{
        'quote': 'line\n"quoted"',
        'a': null,
        'z': <Object?>[
          3,
          <String, Object?>{'a': true, 'é': '雪'},
        ],
      }),
      encoder.encode(value),
    );
  });

  test('canonical JSON rejects floating point and unsupported values', () {
    expect(() => encoder.encode(1.5), throwsArgumentError);
    expect(() => encoder.encode(DateTime.utc(2026)), throwsArgumentError);
    expect(
      () => encoder.encode(<Object?, Object?>{1: 'not-a-string-key'}),
      throwsArgumentError,
    );
  });

  test('UTC timestamps always have six fractional digits', () {
    expect(
      canonicalUtcIso8601Micros(
        DateTime.parse('2026-08-15T20:01:02.123456+08:00'),
      ),
      '2026-08-15T12:01:02.123456Z',
    );
    expect(
      canonicalUtcIso8601Micros(DateTime.utc(2026, 8, 15, 12, 1, 2)),
      '2026-08-15T12:01:02.000000Z',
    );
  });

  test('deterministic run id has a locked golden vector', () {
    final id = deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: 'model-regime-test',
      algorithmVersion: shadowLearningAlgorithmV1,
      configVersion: shadowLearningConfigV1,
      evidenceHash: List.filled(64, '0').join(),
    );

    expect(
      id,
      'learning-run-sha256-v1:'
      'a9b7787f28ff5c4a5d65806fee059fb450c2dc893a12281cb1658f84907512e0',
    );
  });
}
