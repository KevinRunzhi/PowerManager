import 'dart:async';
import 'dart:io';

typedef BeforeAtomicTextFileReplace =
    Future<void> Function(File temporary, File target);

/// Replaces a text file without depending on the platform overwriting an
/// existing rename destination.
///
/// The previous valid file is retained under [recoverySuffix] until the new
/// file has been promoted. A later read repairs the target when the process
/// stopped between those two renames.
final class RecoverableAtomicTextFile {
  RecoverableAtomicTextFile(this.target, {this.beforeReplace});

  static const temporarySuffix = '.tmp';
  static const recoverySuffix = '.previous';
  static final Map<String, Future<void>> _operationTails = {};

  final File target;
  final BeforeAtomicTextFileReplace? beforeReplace;

  File get temporary => File('${target.path}$temporarySuffix');
  File get recovery => File('${target.path}$recoverySuffix');

  Future<void> write(String contents) {
    return _serialized(() => _write(contents));
  }

  /// Replaces the target and evaluates [reader] before another operation for
  /// the same path may begin.
  Future<T> writeAndRead<T>(
    String contents,
    Future<T> Function(File target) reader,
  ) {
    return _serialized(() async {
      await _write(contents);
      return reader(target);
    });
  }

  Future<void> _write(String contents) async {
    await target.parent.create(recursive: true);
    await _recover();

    try {
      await temporary.writeAsString(contents, flush: true);
      await beforeReplace?.call(temporary, target);
      if (await temporary.readAsString() != contents) {
        throw FileSystemException(
          'Temporary text verification failed',
          temporary.path,
        );
      }

      if (await target.exists()) {
        await target.rename(recovery.path);
      }

      try {
        await temporary.rename(target.path);
      } catch (error, stackTrace) {
        await _restorePreviousIfNeeded();
        Error.throwWithStackTrace(error, stackTrace);
      }

      if (await recovery.exists()) {
        await recovery.delete();
      }
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  /// Returns the canonical target after repairing an interrupted replacement.
  Future<File> recover() => _serialized(_recover);

  /// Repairs and reads the target while excluding replacements for the same
  /// absolute path.
  Future<T> read<T>(Future<T> Function(File target) reader) {
    return _serialized(() async {
      final recovered = await _recover();
      return reader(recovered);
    });
  }

  Future<File> _recover() async {
    final targetExists = await target.exists();
    final recoveryExists = await recovery.exists();

    if (targetExists) {
      if (recoveryExists) {
        await recovery.delete();
      }
    } else if (recoveryExists) {
      await recovery.rename(target.path);
    }

    if (await temporary.exists()) {
      await temporary.delete();
    }
    return target;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) async {
    final path = target.absolute.path;
    final predecessor = _operationTails[path] ?? Future<void>.value();
    final completer = Completer<void>();
    final tail = completer.future;
    _operationTails[path] = tail;
    await predecessor;
    try {
      return await operation();
    } finally {
      completer.complete();
      if (identical(_operationTails[path], tail)) {
        _operationTails.remove(path);
      }
    }
  }

  Future<void> _restorePreviousIfNeeded() async {
    if (!await target.exists() && await recovery.exists()) {
      await recovery.rename(target.path);
    }
  }
}
