import 'package:sallahha/core/sync/backoff.dart';
import 'package:sallahha/core/sync/op_log.dart';

/// Replay outcome for one op. The repository decides; the engine schedules.
enum ReplayOutcome {
  /// Applied remotely (or confirmed duplicate) — safe to ack.
  applied,

  /// Transient failure (network/timeout) — back off and retry.
  retry,

  /// Permanent failure (validation, permission, illegal transition,
  /// exhausted retries, unresolvable conflict) — human must look.
  failed,

  /// Server version moved — try one rebase before failing.
  conflict,
}

/// Executes one op against the remote. Returns outcome + optional message.
typedef OpExecutor = Future<(ReplayOutcome, String?)> Function(SyncOp op);

/// One-shot conflict rebase (server wins, intent re-applied when valid).
/// Returns true when the rebase applied and the op may be acked.
typedef ConflictResolver = Future<bool> Function(SyncOp op);

/// Offline-first flush engine over an [OpLog].
/// Per-entity FIFO (createdAt order), exponential backoff, idempotent
/// replay (same opIds — server dedupes), restart-safe (log is durable).
class SyncEngine {
  final OpLog log;
  final OpExecutor execute;
  final ConflictResolver resolveConflict;
  final Future<bool> Function() isOnline;

  bool _running = false;

  SyncEngine({
    required this.log,
    required this.execute,
    required this.resolveConflict,
    required this.isOnline,
  });

  /// Flush all due ops. Returns counts by outcome. Single-flight guarded.
  Future<Map<ReplayOutcome, int>> flush() async {
    if (_running) return {};
    if (!await isOnline()) return {};
    _running = true;
    try {
      final counts = <ReplayOutcome, int>{};
      for (final op in await log.dueOps(DateTime.now())) {
        final outcome = await _runOne(op);
        counts[outcome] = (counts[outcome] ?? 0) + 1;
      }
      return counts;
    } finally {
      _running = false;
    }
  }

  Future<ReplayOutcome> _runOne(SyncOp op) async {
    final now = DateTime.now();
    await log.update(op.copyWith(status: 'sending', lastAttemptAt: now));
    final (outcome, message) = await execute(op);
    switch (outcome) {
      case ReplayOutcome.applied:
        await log.update(op.copyWith(status: 'acked'));
        return outcome;
      case ReplayOutcome.conflict:
        final rebased = await resolveConflict(op);
        if (rebased) {
          await log.update(op.copyWith(status: 'acked'));
          return ReplayOutcome.applied;
        }
        await log.update(
          op.copyWith(status: 'failed', lastError: message ?? 'conflict'),
        );
        return ReplayOutcome.failed;
      case ReplayOutcome.failed:
        await log.update(
          op.copyWith(status: 'failed', lastError: message ?? 'failed'),
        );
        return outcome;
      case ReplayOutcome.retry:
        final next = op.retryCount + 1;
        if (next >= maxAttempts) {
          await log.update(
            op.copyWith(
              status: 'failed',
              retryCount: next,
              lastError: 'retry-exhausted',
            ),
          );
          return ReplayOutcome.failed;
        }
        await log.update(
          op.copyWith(
            status: 'backing_off',
            retryCount: next,
            lastAttemptAt: now,
            lastError: message,
            nextAttemptAt: now.add(backoffForAttempt(next)),
          ),
        );
        return outcome;
    }
  }

  /// Manual retry: failed or backing_off ops for one entity go pending.
  Future<void> retryEntity(String entityId) async {
    for (final op in await log.opsFor(entityId)) {
      if (op.status == 'failed' || op.status == 'backing_off') {
        await log.requeue(op.opId);
      }
    }
    await flush();
  }

  /// Badge state for one entity. Failed dominates (needs human first).
  static Future<String> entityState(OpLog log, String entityId) async {
    final ops = await log.opsFor(entityId);
    if (ops.any((o) => o.status == 'failed')) return 'failed';
    if (ops.any(
      (o) =>
          o.status == 'pending' ||
          o.status == 'sending' ||
          o.status == 'backing_off',
    )) {
      return 'pending';
    }
    return 'synced';
  }
}
