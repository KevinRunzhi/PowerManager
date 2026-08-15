import 'dart:async';

abstract interface class BusinessWriteCoordinator {
  Future<T> run<T>(Future<T> Function() action);
}

final class SerialBusinessWriteCoordinator implements BusinessWriteCoordinator {
  Future<void> _tail = Future.value();

  @override
  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
