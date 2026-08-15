import 'dart:async';

import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:test/test.dart';

void main() {
  test('runs business writes strictly in invocation order', () async {
    final coordinator = SerialBusinessWriteCoordinator();
    final firstGate = Completer<void>();
    final events = <String>[];

    final first = coordinator.run(() async {
      events.add('first-start');
      await firstGate.future;
      events.add('first-end');
      return 1;
    });
    final second = coordinator.run(() async {
      events.add('second-start');
      return 2;
    });
    await Future<void>.delayed(Duration.zero);

    expect(events, ['first-start']);
    firstGate.complete();
    expect(await first, 1);
    expect(await second, 2);
    expect(events, ['first-start', 'first-end', 'second-start']);
  });

  test('one failed write never poisons later writes', () async {
    final coordinator = SerialBusinessWriteCoordinator();
    final failed = coordinator.run<void>(() async {
      throw StateError('first failed');
    });
    final recovered = coordinator.run(() async => 'recovered');

    await expectLater(failed, throwsStateError);
    expect(await recovered, 'recovered');
  });
}
