import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/features/settings/presentation/settings_page.dart';

import '../support/backup_fixture.dart';

void main() {
  testWidgets('preview shows replacement counts and requires confirmation', (
    tester,
  ) async {
    final backup = backupFixture(baseEnergy: 120);
    final inspection = const JsonBackupCodec().inspect(
      fileName: 'powermanager.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup.toJson()))),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: BackupPreviewSheet(
              inspection: inspection,
              currentCounts: const BackupDataCounts(
                ruleVersions: 1,
                morningCheckIns: 7,
                activityRecords: 27,
                energyObservations: 1,
                activityFeedback: 2,
                dailySummaries: 8,
                promptReceipts: 5,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backup-preview-sheet')), findsOneWidget);
    expect(find.text('27 → 0'), findsOneWidget);
    expect(find.text('2 → 0'), findsOneWidget);
    expect(find.text('v1'), findsOneWidget);
    expect(find.textContaining('完整替换当前数据'), findsOneWidget);
    final continueButton = find.byKey(const Key('continue-restore-button'));
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('backup-restore-confirmation')),
      findsOneWidget,
    );
    expect(find.text('保存副本并恢复'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
