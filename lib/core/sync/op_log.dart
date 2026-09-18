import 'dart:convert';

/// Durable outbox record. Mirrors the SyncOperations drift table.
/// Status follows docs/architecture/sync-state-machine.md.
class SyncOp {
  final String opId; // client UUID = idempotency key
  final String entityType; // 'request'
  final String entityId;
  final String
  opType; // create|assign|priority|status|note|photo|part|estimate|confirm|rate
  final Map<String, dynamic> payload;
  final String status; // pending|sending|backing_off|acked|failed
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;

  const SyncOp({
    required this.opId,
    required this.entityType,
    required this.entityId,
    required this.opType,
    required this.payload,
    this.status = 'pending',
    this.retryCount = 0,
    this.lastAttemptAt,
    this.lastError,
    required this.createdAt,
    this.nextAttemptAt,
  });

  SyncOp copyWith({
    String? status,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? lastError,
    DateTime? nextAttemptAt,
  }) {
    return SyncOp(
      opId: opId,
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt,
      lastError: lastError,
      createdAt: createdAt,
      nextAttemptAt: nextAttemptAt,
    );
  }

  String encodePayload() => jsonEncode(payload);

  static Map<String, dynamic> decodePayload(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);
}

/// Outbox storage contract. Drift adapter for devices, memory for tests.
abstract class OpLog {
  /// Insert unless the opId already exists (dedupe — returns false).
  Future<bool> enqueue(SyncOp op);
  Future<bool> contains(String opId);
  Future<List<SyncOp>> dueOps(DateTime now);
  Future<void> update(SyncOp op);
  Future<List<SyncOp>> opsFor(String entityId);
  Future<void> requeue(String opId);
}

/// Test/CI-friendly in-memory log. Same ordering semantics as drift.
class MemoryOpLog implements OpLog {
  final Map<String, SyncOp> _ops = {};

  @override
  Future<bool> enqueue(SyncOp op) async {
    if (_ops.containsKey(op.opId)) return false;
    _ops[op.opId] = op;
    return true;
  }

  @override
  Future<bool> contains(String opId) async => _ops.containsKey(opId);

  @override
  Future<List<SyncOp>> dueOps(DateTime now) async {
    final due = _ops.values.where((o) {
      if (o.status == 'pending') return true;
      if (o.status == 'backing_off' &&
          (o.nextAttemptAt == null || !o.nextAttemptAt!.isAfter(now))) {
        return true;
      }
      return false;
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return due;
  }

  @override
  Future<void> update(SyncOp op) async {
    _ops[op.opId] = op;
  }

  @override
  Future<List<SyncOp>> opsFor(String entityId) async =>
      _ops.values.where((o) => o.entityId == entityId).toList();

  @override
  Future<void> requeue(String opId) async {
    final op = _ops[opId];
    if (op == null) return;
    _ops[opId] = op.copyWith(
      status: 'pending',
      lastError: null,
      nextAttemptAt: null,
    );
  }
}
