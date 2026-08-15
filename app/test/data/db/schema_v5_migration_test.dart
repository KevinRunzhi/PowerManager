import 'package:drift_dev/api/migrations_native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:test/test.dart';

import '../../generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
    'v4 with no feedback gains safe v5 snapshots and empty sample tables',
    () async {
      final schema = await verifier.schemaAt(4);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        4,
      );
      await _seedV4(old, withFeedback: false);
      await old.close();

      final database = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _SchemaClock(),
      );
      addTearDown(database.close);
      await verifier.migrateAndValidate(database, 5);

      final activity = await database
          .customSelect(
            'SELECT default_theoretical_delta, activity_factor, '
            'personalized_theoretical_delta, personalization_version_id '
            'FROM activity_records',
          )
          .getSingle();
      expect(activity.read<int>('default_theoretical_delta'), -8);
      expect(activity.read<double>('activity_factor'), 1.0);
      expect(activity.read<int>('personalized_theoretical_delta'), -8);
      expect(
        activity.readNullable<String>('personalization_version_id'),
        isNull,
      );
      expect(
        await database
            .customSelect(
              'SELECT COUNT(*) AS c FROM personalization_activity_factors',
            )
            .getSingle()
            .then((row) => row.read<int>('c')),
        0,
      );
      expect(
        await database
            .customSelect('SELECT COUNT(*) AS c FROM activity_feedback_samples')
            .getSingle()
            .then((row) => row.read<int>('c')),
        0,
      );
    },
  );

  test('v4 feedback is copied as user initiated and never sampled', () async {
    final schema = await verifier.schemaAt(4);
    addTearDown(schema.rawDatabase.close);
    final old = GeneratedHelper().databaseForVersion(schema.newConnection(), 4);
    await _seedV4(old, withFeedback: true);
    await old.close();

    final database = AppDatabase.forExecutor(
      schema.newConnection(),
      clock: const _SchemaClock(),
    );
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 5);
    final feedback = await database
        .customSelect(
          'SELECT default_theoretical_delta_snapshot, factor_snapshot, '
          'personalized_theoretical_delta_snapshot, collection_source, sample_id '
          'FROM activity_feedback',
        )
        .getSingle();
    expect(feedback.read<int>('default_theoretical_delta_snapshot'), -8);
    expect(feedback.read<double>('factor_snapshot'), 1.0);
    expect(feedback.read<int>('personalized_theoretical_delta_snapshot'), -8);
    expect(feedback.read<String>('collection_source'), 'userInitiated');
    expect(feedback.readNullable<String>('sample_id'), isNull);
  });

  test(
    'v5 migration failure rolls back to v4 without partial columns',
    () async {
      final schema = await verifier.schemaAt(4);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        4,
      );
      await _seedV4(old, withFeedback: true);
      await old.close();

      final database = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _SchemaClock(),
        migrationFailureHook: (checkpoint) async {
          if (checkpoint == 'v5-after-feedback-renamed') {
            throw StateError('expected v5 failure');
          }
        },
      );
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsStateError,
      );
      await database.close();
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single['user_version'],
        4,
      );
      expect(
        schema.rawDatabase
            .select('PRAGMA table_info(activity_records)')
            .every((row) => row['name'] != 'default_theoretical_delta'),
        isTrue,
      );
    },
  );
}

Future<void> _seedV4(dynamic database, {required bool withFeedback}) async {
  await database.customStatement('''
    INSERT INTO rule_config_versions(version, values_json, created_at)
    VALUES ('energy-rules-v2-mvp-a', '{"ruleVersion":"energy-rules-v2-mvp-a"}', 1786248000)
  ''');
  await database.customStatement('''
    INSERT INTO app_settings(id, active_rule_version, onboarding_completed, created_at, updated_at)
    VALUES (1, 'energy-rules-v2-mvp-a', 1, 1786248000, 1786248000)
  ''');
  await database.customStatement('''
    INSERT INTO activity_records(
      id, life_day, completed_at, created_at, updated_at, category, subcategory,
      duration_minutes, theoretical_delta, applied_delta, rule_version, status, deleted_at
    ) VALUES (
      'activity-v5', '2026-08-08', 1786150800, 1786150800, 1786154400,
      'study', 'homework', 30, -8, -8, 'energy-rules-v2-mvp-a', 'active', NULL
    )
  ''');
  if (withFeedback) {
    await database.customStatement('''
      INSERT INTO activity_feedback(
        id, activity_record_id, life_day, subcategory_snapshot,
        duration_minutes_snapshot, theoretical_delta_snapshot, applied_delta_snapshot,
        impact_sign_snapshot, rule_version_snapshot, activity_updated_at_snapshot,
        direction, status, invalidation_reason, observed_at
      ) VALUES (
        'feedback-v5', 'activity-v5', '2026-08-08', 'homework', 30, -8, -8,
        'consumption', 'energy-rules-v2-mvp-a', 1786154400,
        'aboutRight', 'active', NULL, 1786158000
      )
    ''');
  }
}

final class _SchemaClock implements Clock {
  const _SchemaClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 15, 12);
}
