import 'package:drift/drift.dart';
import 'package:sallahha/core/storage/app_database.dart' as drift;
import 'package:sallahha/core/sync/op_log.dart';

/// Drift-backed outbox. Survives app restarts (Phase 4 requirement).
class DriftOpLog implements OpLog {
  final drift.AppDatabase db;
  DriftOpLog(this.db);

  @override
  Future<bool> enqueue(SyncOp op) async {
    if (await contains(op.opId)) return false;
    await db
        .into(db.syncOperations)
        .insert(
          drift.SyncOperationsCompanion(
            opId: Value(op.opId),
            entityType: Value(op.entityType),
            entityId: Value(op.entityId),
            opType: Value(op.opType),
            payloadJson: Value(op.encodePayload()),
            status: Value(op.status),
            retryCount: Value(op.retryCount),
            createdAt: Value(op.createdAt),
          ),
        );
    return true;
  }

  @override
  Future<bool> contains(String opId) async {
    final row = await (db.select(
      db.syncOperations,
    )..where((t) => t.opId.equals(opId))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<SyncOp>> dueOps(DateTime now) async {
    final rows =
        await (db.select(db.syncOperations)
              ..where(
                (t) =>
                    t.status.equals('pending') | t.status.equals('backing_off'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    // nextAttemptAt isn't a column in v1; backing_off readiness is
    // derived from lastAttemptAt + backoff(retryCount). v2 can add it.
    return rows.map(_fromRow).where((o) {
      if (o.status == 'pending') return true;
      if (o.status == 'backing_off') {
        final at = o.lastAttemptAt;
        if (at == null) return true;
        return !at.add(_backoffOf(o.retryCount)).isAfter(now);
      }
      return false;
    }).toList();
  }

  Duration _backoffOf(int retryCount) {
    var seconds = 1 << retryCount.clamp(0, 9);
    if (seconds > 300) seconds = 300;
    return Duration(seconds: seconds);
  }

  @override
  Future<void> update(SyncOp op) async {
    await (db.update(
      db.syncOperations,
    )..where((t) => t.opId.equals(op.opId))).write(
      drift.SyncOperationsCompanion(
        status: Value(op.status),
        retryCount: Value(op.retryCount),
        lastAttemptAt: Value(op.lastAttemptAt),
        lastError: Value(op.lastError),
        payloadJson: Value(op.encodePayload()),
      ),
    );
  }

  @override
  Future<List<SyncOp>> opsFor(String entityId) async {
    final rows = await (db.select(
      db.syncOperations,
    )..where((t) => t.entityId.equals(entityId))).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> requeue(String opId) async {
    await (db.update(
      db.syncOperations,
    )..where((t) => t.opId.equals(opId))).write(
      const drift.SyncOperationsCompanion(
        status: Value('pending'),
        lastError: Value(null),
        lastAttemptAt: Value(null),
      ),
    );
  }

  SyncOp _fromRow(drift.SyncOperation row) => SyncOp(
    opId: row.opId,
    entityType: row.entityType,
    entityId: row.entityId,
    opType: row.opType,
    payload: SyncOp.decodePayload(row.payloadJson),
    status: row.status,
    retryCount: row.retryCount,
    lastAttemptAt: row.lastAttemptAt,
    lastError: row.lastError,
    createdAt: row.createdAt,
  );
}
