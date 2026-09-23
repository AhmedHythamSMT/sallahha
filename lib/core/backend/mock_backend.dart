import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/storage/mappers.dart';
import 'package:sallahha/core/storage/seed_data.dart';
import 'package:sallahha/features/jobs/domain/job_status.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// In-memory server stand-in. Simulates latency, server-side guards,
/// idempotency dedupe, and optimistic-concurrency conflicts.
/// Supabase/FastAPI replaces this behind RequestRepository (Phase 5).
class MockBackend {
  static const demoPassword = 'demo1234';
  static const _latency = Duration(milliseconds: 120);

  final Map<String, AppUser> users = {};
  final Map<String, ServiceInfo> services = {};
  final Map<String, PartRow> parts = {};
  final Map<String, ServiceRequest> requests = {};
  final Map<String, List<StatusEvent>> timelines = {};
  final Map<String, List<JobNote>> notes = {};
  final Map<String, List<JobPhoto>> photos = {};
  final Map<String, List<PartUsage>> partsUsed = {};
  final Map<String, AssignmentInfo> assignments = {};
  final Map<String, RatingInfo> ratings = {};
  final Set<String> confirmed = {};

  /// Server-side notification store: user id → inbox (server ids).
  final Map<String, List<InboxItem>> notifications = {};
  int _notifSeq = 1;

  /// Idempotency store for creates: key -> request id.
  final Map<String, String> _createKeys = {};

  int _seq = 100;

  MockBackend() {
    for (final u in demoUsers()) {
      users[u.id.value] = userFromCompanion(u);
    }
    for (final s in demoServices()) {
      services[s.id.value] = serviceFromCompanion(s);
    }
    for (final p in demoParts()) {
      parts[p.id.value] = PartRow(
        p.id.value,
        p.nameAr.value,
        p.nameEn.value,
        p.priceEgp.value,
      );
    }
    final now = DateTime.now();
    for (final r in demoRequests(now)) {
      final e = requestFromCompanion(r, now);
      requests[e.id] = e;
      timelines[e.id] = [
        StatusEvent(
          requestId: e.id,
          from: '-',
          to: e.status,
          byUserId: e.customerId,
          createdAt: e.createdAt,
        ),
      ];
      notes[e.id] = [];
      photos[e.id] = [];
      partsUsed[e.id] = [];
    }
    // Seed one assignment so dispatch/job screens have content.
    assignments['req-progress-1'] = const AssignmentInfo(
      id: 'seed-asg-1',
      requestId: 'req-progress-1',
      technicianId: 'u-tech-1',
      technicianName: 'Hassan Ali',
      assignedBy: 'u-supervisor-1',
    );
  }

  Future<T> _slow<T>(T Function() fn) async {
    await Future.delayed(_latency);
    return fn();
  }

  List<PartInfo> partsCatalog() => parts.values
      .map(
        (p) => PartInfo(
          id: p.id,
          nameAr: p.nameAr,
          nameEn: p.nameEn,
          priceEgp: p.price,
        ),
      )
      .toList();

  Result<AppUser> signIn(String email, String password) {
    final match = users.values.where((u) => u.email == email).toList();
    if (match.isEmpty || password != demoPassword) {
      return const Err(Unauthorized());
    }
    if (match.first.role == 'technician') {
      // technicians sign in too; active check mirrors server policy
    }
    return Ok(match.first);
  }

  Future<Result<ServiceRequest>> createRequest({
    required String customerId,
    required RequestDraft draft,
    required String idempotencyKey,
    required int slaHours,
    String? requestId,
  }) => _slow(() {
    final existing = _createKeys[idempotencyKey];
    if (existing != null) return Ok(requests[existing]!);
    final now = DateTime.now();
    // Client-generated IDs: the same id works offline-first and on
    // retry, so creates never duplicate and never need remapping.
    final id = requestId ?? 'req-${now.millisecondsSinceEpoch}-${_seq++}';
    final req = ServiceRequest(
      id: id,
      customerId: customerId,
      serviceId: draft.serviceId,
      description: draft.description,
      address: draft.address,
      governorate: draft.governorate,
      phone: draft.phone,
      photoLocalPath: draft.photoLocalPath,
      priority: 'normal',
      status: 'new',
      slaDueAt: now.add(Duration(hours: slaHours)),
      idempotencyKey: idempotencyKey,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    requests[id] = req;
    timelines[id] = [
      StatusEvent(
        requestId: id,
        from: '-',
        to: 'new',
        byUserId: customerId,
        createdAt: now,
      ),
    ];
    notes[id] = [];
    photos[id] = [];
    partsUsed[id] = [];
    _createKeys[idempotencyKey] = id;
    return Ok(req);
  });

  /// Mutation idempotency is enforced by the repository (op-key store);
  /// the backend applies each call exactly once it receives.

  Result<ServiceRequest> assign({
    required String byId,
    required String requestId,
    required String technicianId,
  }) {
    final req = requests[requestId];
    final tech = users[technicianId];
    if (req == null) return const Err(NotFound());
    if (tech == null || tech.role != 'technician') {
      return const Err(ValidationFailed('technicianId'));
    }
    final now = DateTime.now();
    final updated = _copy(req, status: 'assigned', version: req.version + 1);
    requests[requestId] = updated;
    assignments[requestId] = AssignmentInfo(
      id: 'asg-$requestId',
      requestId: requestId,
      technicianId: technicianId,
      technicianName: tech.name,
      assignedBy: byId,
    );
    timelines[requestId]!.add(
      StatusEvent(
        requestId: requestId,
        from: req.status,
        to: 'assigned',
        byUserId: byId,
        createdAt: now,
      ),
    );
    return Ok(updated);
  }

  Result<ServiceRequest> setPriority({
    required String requestId,
    required String priority,
    required int baseVersion,
  }) {
    final req = requests[requestId];
    if (req == null) return const Err(NotFound());
    if (req.version != baseVersion) {
      return const Err(SyncFailed('version-conflict'));
    }
    final updated = _copy(req, priority: priority, version: req.version + 1);
    requests[requestId] = updated;
    return Ok(updated);
  }

  Result<ServiceRequest> transition({
    required String byId,
    required String requestId,
    required String to,
    required int baseVersion,
    String? reason,
  }) {
    final req = requests[requestId];
    if (req == null) return const Err(NotFound());
    if (req.version != baseVersion) {
      return const Err(SyncFailed('version-conflict'));
    }
    if (!canTransition(req.status, to)) {
      return Err(IllegalTransition(req.status, nextStates(req.status)));
    }
    final now = DateTime.now();
    final updated = _copy(req, status: to, version: req.version + 1);
    requests[requestId] = updated;
    timelines[requestId]!.add(
      StatusEvent(
        requestId: requestId,
        from: req.status,
        to: to,
        byUserId: byId,
        reason: reason,
        createdAt: now,
      ),
    );
    return Ok(updated);
  }

  void addNote(JobNote note) => notes[note.requestId]!.add(note);
  void addPhoto(JobPhoto photo) => photos[photo.requestId]!.add(photo);

  Result<void> addPart({
    required String requestId,
    required String partId,
    required int qty,
  }) {
    final part = parts[partId];
    if (part == null || qty < 1) {
      return const Err(ValidationFailed('partId'));
    }
    partsUsed[requestId]!.add(
      PartUsage(
        partId: partId,
        partName: part.nameEn,
        priceEgp: part.price,
        qty: qty,
      ),
    );
    return const Ok(null);
  }

  Result<void> setEstimate({
    required String requestId,
    required int amountEgp,
  }) {
    final req = requests[requestId];
    if (req == null) return const Err(NotFound());
    if (amountEgp < 0) return const Err(ValidationFailed('estimateEgp'));
    requests[requestId] = _copy(req, estimate: amountEgp);
    return const Ok(null);
  }

  Result<void> confirm({required String requestId}) {
    final req = requests[requestId];
    if (req == null) return const Err(NotFound());
    if (req.status != 'completed') {
      return const Err(ValidationFailed('status'));
    }
    confirmed.add(requestId);
    return const Ok(null);
  }

  Result<void> rate({
    required String requestId,
    required int stars,
    String? comment,
  }) {
    if (!confirmed.contains(requestId)) {
      return const Err(ValidationFailed('confirm'));
    }
    if (ratings.containsKey(requestId)) {
      return const Err(ValidationFailed('rating'));
    }
    if (stars < 1 || stars > 5) {
      return const Err(ValidationFailed('stars'));
    }
    ratings[requestId] = RatingInfo(
      requestId: requestId,
      stars: stars,
      comment: comment,
    );
    return const Ok(null);
  }

  // ---------- role-to-role notifications ----------

  /// Fan-out to explicit ids + every user whose role is in [roles].
  /// Mirrors api_push_notifications (SECURITY DEFINER) semantics.
  Future<Result<void>> pushNotifications({
    required List<String> userIds,
    required List<String> roles,
    required String kind,
    required String title,
    required String body,
  }) async {
    final targets = <String>{...userIds};
    for (final u in users.values) {
      if (roles.contains(u.role)) targets.add(u.id);
    }
    if (targets.isEmpty) return const Ok(null);
    final now = DateTime.now();
    for (final id in targets) {
      notifications.putIfAbsent(id, () => []).add(
        InboxItem(
          id: _notifSeq++,
          kind: kind,
          title: title,
          body: body,
          read: false,
          createdAt: now,
        ),
      );
    }
    return const Ok(null);
  }

  /// Server inbox for [userId] (never throws — empty on anomaly).
  Future<List<InboxItem>> inboxFor(String userId) async =>
      List.of(notifications[userId] ?? const []);

  /// Marks one recipient's row read; unknown ids are a no-op.
  Future<Result<void>> markNotificationRead({
    required int id,
    required String userId,
  }) async {
    final list = notifications[userId];
    if (list == null) return const Ok(null);
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return const Ok(null);
    final e = list[i];
    list[i] = InboxItem(
      id: e.id,
      kind: e.kind,
      title: e.title,
      body: e.body,
      read: true,
      createdAt: e.createdAt,
    );
    return const Ok(null);
  }

  static ServiceRequest _copy(
    ServiceRequest r, {
    String? status,
    String? priority,
    int? version,
    int? estimate,
  }) {
    return ServiceRequest(
      id: r.id,
      customerId: r.customerId,
      serviceId: r.serviceId,
      description: r.description,
      address: r.address,
      governorate: r.governorate,
      phone: r.phone,
      photoLocalPath: r.photoLocalPath,
      priority: priority ?? r.priority,
      status: status ?? r.status,
      slaDueAt: r.slaDueAt,
      estimateEgp: estimate ?? r.estimateEgp,
      idempotencyKey: r.idempotencyKey,
      version: version ?? r.version,
      createdAt: r.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PartRow {
  final String id;
  final String nameAr;
  final String nameEn;
  final int price;
  PartRow(this.id, this.nameAr, this.nameEn, this.price);
}
