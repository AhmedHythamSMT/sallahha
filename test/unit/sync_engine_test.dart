import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/sync/op_log.dart';
import 'package:sallahha/core/sync/sync_engine.dart';

SyncOp _op(String id, {DateTime? at}) => SyncOp(
  opId: id,
  entityType: 'request',
  entityId: 'req-1',
  opType: 'note',
  payload: const {},
  createdAt: at ?? DateTime(2026, 9, 17, 10),
);

void main() {
  group('SyncEngine over MemoryOpLog', () {
    test('flushes FIFO and acks applied ops', () async {
      final log = MemoryOpLog();
      final order = <String>[];
      final engine = SyncEngine(
        log: log,
        execute: (op) async {
          order.add(op.opId);
          return (ReplayOutcome.applied, null);
        },
        resolveConflict: (_) async => false,
        isOnline: () async => true,
      );
      await log.enqueue(_op('op-1'));
      await log.enqueue(_op('op-2', at: DateTime(2026, 9, 17, 10, 0, 1)));
      final counts = await engine.flush();
      expect(order, ['op-1', 'op-2']);
      expect(counts[ReplayOutcome.applied], 2);
      expect(await SyncEngine.entityState(log, 'req-1'), 'synced');
    });

    test('offline flush executes nothing', () async {
      var ran = false;
      final log = MemoryOpLog();
      final engine = SyncEngine(
        log: log,
        execute: (_) async {
          ran = true;
          return (ReplayOutcome.applied, null);
        },
        resolveConflict: (_) async => false,
        isOnline: () async => false,
      );
      await log.enqueue(_op('op-1'));
      await engine.flush();
      expect(ran, isFalse);
      expect(await SyncEngine.entityState(log, 'req-1'), 'pending');
    });

    test('retry backs off with growing delay, then exhausts', () async {
      final log = MemoryOpLog();
      var calls = 0;
      final engine = SyncEngine(
        log: log,
        execute: (_) async {
          calls++;
          return (ReplayOutcome.retry, 'timeout');
        },
        resolveConflict: (_) async => false,
        isOnline: () async => true,
      );
      await log.enqueue(_op('op-1'));
      await engine.flush();
      var ops = await log.opsFor('req-1');
      expect(ops.single.status, 'backing_off');
      expect(ops.single.retryCount, 1);
      final firstDelay = ops.single.nextAttemptAt!.difference(
        ops.single.lastAttemptAt!,
      );
      expect(firstDelay.inSeconds, greaterThanOrEqualTo(2));
      // Not due yet: second flush is a no-op.
      await engine.flush();
      expect(calls, 1);
      expect(await SyncEngine.entityState(log, 'req-1'), 'pending');
    });

    test('failed ops surface for humans; retryEntity requeues', () async {
      final log = MemoryOpLog();
      var calls = 0;
      final engine = SyncEngine(
        log: log,
        execute: (_) async {
          calls++;
          return calls == 1
              ? (ReplayOutcome.failed, 'validation:stars')
              : (ReplayOutcome.applied, null);
        },
        resolveConflict: (_) async => false,
        isOnline: () async => true,
      );
      await log.enqueue(_op('op-1'));
      await engine.flush();
      expect(await SyncEngine.entityState(log, 'req-1'), 'failed');
      await engine.retryEntity('req-1');
      expect(calls, 2);
      expect(await SyncEngine.entityState(log, 'req-1'), 'synced');
    });

    test('conflict resolves via rebase or fails loudly', () async {
      // rebase success
      final log = MemoryOpLog();
      final okEngine = SyncEngine(
        log: log,
        execute: (_) async => (ReplayOutcome.conflict, 'version-conflict'),
        resolveConflict: (_) async => true,
        isOnline: () async => true,
      );
      await log.enqueue(_op('op-1'));
      await okEngine.flush();
      expect(await SyncEngine.entityState(log, 'req-1'), 'synced');

      // rebase refusal
      final log2 = MemoryOpLog();
      final badEngine = SyncEngine(
        log: log2,
        execute: (_) async => (ReplayOutcome.conflict, 'version-conflict'),
        resolveConflict: (_) async => false,
        isOnline: () async => true,
      );
      await log2.enqueue(_op('op-2'));
      await badEngine.flush();
      expect(await SyncEngine.entityState(log2, 'req-1'), 'failed');
    });

    test('duplicate enqueue is ignored (idempotent)', () async {
      final log = MemoryOpLog();
      var calls = 0;
      final engine = SyncEngine(
        log: log,
        execute: (_) async {
          calls++;
          return (ReplayOutcome.applied, null);
        },
        resolveConflict: (_) async => false,
        isOnline: () async => true,
      );
      expect(await log.enqueue(_op('op-1')), isTrue);
      expect(await log.enqueue(_op('op-1')), isFalse);
      await engine.flush();
      expect(calls, 1);
    });

    test('queue survives engine restart (same durable log)', () async {
      final log = MemoryOpLog();
      await log.enqueue(_op('op-1'));
      var calls = 0;
      // "restart": brand-new engine over the same log.
      final engine2 = SyncEngine(
        log: log,
        execute: (_) async {
          calls++;
          return (ReplayOutcome.applied, null);
        },
        resolveConflict: (_) async => false,
        isOnline: () async => true,
      );
      await engine2.flush();
      expect(calls, 1);
    });
  });
}
