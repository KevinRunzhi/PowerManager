import 'dart:async';
import 'dart:io';

import 'package:power_manager/data/backup/recoverable_atomic_text_file.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late File target;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'powermanager-atomic-text-',
    );
    target = File('${directory.path}${Platform.pathSeparator}state.json');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('replaces an existing file and removes transient files', () async {
    final file = RecoverableAtomicTextFile(target);

    await file.write('first');
    await file.write('second');

    expect(await target.readAsString(), 'second');
    expect(await file.temporary.exists(), isFalse);
    expect(await file.recovery.exists(), isFalse);
  });

  test('failure before rotation preserves the previous valid file', () async {
    await target.writeAsString('valid previous');
    final file = RecoverableAtomicTextFile(
      target,
      beforeReplace: (_, _) async => throw StateError('injected failure'),
    );

    await expectLater(file.write('incomplete next'), throwsStateError);

    expect(await target.readAsString(), 'valid previous');
    expect(await file.temporary.exists(), isFalse);
    expect(await file.recovery.exists(), isFalse);
  });

  test('temporary readback mismatch preserves the previous file', () async {
    await target.writeAsString('valid previous');
    final file = RecoverableAtomicTextFile(
      target,
      beforeReplace: (temporary, _) => temporary.writeAsString('corrupted'),
    );

    await expectLater(
      file.write('intended next'),
      throwsA(isA<FileSystemException>()),
    );

    expect(await target.readAsString(), 'valid previous');
    expect(await file.temporary.exists(), isFalse);
    expect(await file.recovery.exists(), isFalse);
  });

  test('recovers the previous file after an interrupted promotion', () async {
    final file = RecoverableAtomicTextFile(target);
    await file.recovery.writeAsString('recover me');
    await file.temporary.writeAsString('untrusted temporary');

    final recovered = await file.recover();

    expect(await recovered.readAsString(), 'recover me');
    expect(await file.recovery.exists(), isFalse);
    expect(await file.temporary.exists(), isFalse);
  });

  test('keeps the promoted target when stale recovery also exists', () async {
    final file = RecoverableAtomicTextFile(target);
    await target.writeAsString('promoted');
    await file.recovery.writeAsString('old');

    final recovered = await file.recover();

    expect(await recovered.readAsString(), 'promoted');
    expect(await file.recovery.exists(), isFalse);
  });

  test('serializes a read while a replacement is in progress', () async {
    await target.writeAsString('old');
    final replacementStarted = Completer<void>();
    final allowReplacement = Completer<void>();
    final writer = RecoverableAtomicTextFile(
      target,
      beforeReplace: (_, _) async {
        replacementStarted.complete();
        await allowReplacement.future;
      },
    );

    final write = writer.write('new');
    await replacementStarted.future;
    final read = RecoverableAtomicTextFile(
      target,
    ).read((file) => file.readAsString());
    allowReplacement.complete();

    await write;
    expect(await read, 'new');
    expect(await writer.temporary.exists(), isFalse);
    expect(await writer.recovery.exists(), isFalse);
  });

  test('serializes a replacement while a read is in progress', () async {
    await target.writeAsString('old');
    final readStarted = Completer<void>();
    final allowRead = Completer<void>();
    final file = RecoverableAtomicTextFile(target);

    final read = file.read((target) async {
      readStarted.complete();
      await allowRead.future;
      return target.readAsString();
    });
    await readStarted.future;
    final write = file.write('new');

    expect(await target.readAsString(), 'old');
    allowRead.complete();

    expect(await read, 'old');
    await write;
    expect(await target.readAsString(), 'new');
  });
}
