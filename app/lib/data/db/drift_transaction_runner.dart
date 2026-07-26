import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/data/db/app_database.dart';

final class DriftTransactionRunner implements TransactionRunner {
  const DriftTransactionRunner(this.database);

  final AppDatabase database;

  @override
  Future<T> run<T>(Future<T> Function() action) {
    return database.transaction(action);
  }
}
