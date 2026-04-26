import 'package:drift/drift.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/local/tables/tables.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> enqueue(SyncQueueTableCompanion entry) {
    return into(syncQueueTable).insert(entry);
  }

  Future<List<SyncQueueTableData>> getPendingBatch(int limit) {
    return (select(syncQueueTable)
          ..where((table) => table.syncedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> markSynced(int id) {
    return (update(syncQueueTable)..where((table) => table.id.equals(id))).write(
      SyncQueueTableCompanion(
        syncedAt: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<int> markFailed({
    required int id,
    required String errorMessage,
  }) {
    return customUpdate(
      '''
      UPDATE sync_queue_table
      SET retry_count = retry_count + 1,
          last_attempt_at = ?,
          last_error = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<DateTime>(DateTime.now()),
        Variable<String>(errorMessage),
        Variable<int>(id),
      ],
      updates: {syncQueueTable},
    );
  }
}
