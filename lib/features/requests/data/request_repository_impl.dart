import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sallahha/core/analytics/analytics_service.dart';
import 'package:sallahha/core/backend/remote_api.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/core/sync/drift_op_log.dart';
import 'package:sallahha/core/sync/op_log.dart';
import 'package:sallahha/core/sync/sync_engine.dart';
import 'package:sallahha/features/notifications/notification_service.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/features/requests/domain/request_repository.dart';
import 'package:sallahha/features/requests/domain/rules.dart';

/// Offline-first repository: every mutation applies provisionally to the
/// local cache, enqueues a durable op (same opId = idempotency key), and
/// flushes when online. Reads always render local data; remote refreshes
/// only when connected AND nothing is pending for the entity.
class RequestRepositoryImpl implements RequestRepository {
  final RemoteApi remote;
  final LocalRequestStore local;
  final OpLog oplog;
  final Future<bool> Function() isOnline;
  final NotificationService notifications;
  final AnalyticsService analytics;
  late final SyncEngine engine;

  int _seq = 0;

  RequestRepositoryImpl({
    required this.remote,
    required this.local,
    OpLog? oplog,
    Future<bool> Function()? isOnline,
    NotificationService? notifications,
    AnalyticsService? analytics,
  }) : oplog = oplog ?? DriftOpLog(local.db),
       isOnline = isOnline ?? _defaultOnline,
       notifications = notifications ?? MemoryNotificationService(),
       analytics = analytics ?? MemoryAnalyticsService() {
    engine = SyncEngine(
      log: this.oplog,
      execute: _execute,
      resolveConflict: _rebase,
      isOnline: this.isOnline,
    );
  }

  static Future<bool> _defaultOnline() async {
    final c = await Connectivity().checkConnectivity();
    return !c.contains(ConnectivityResult.none);
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  Future<bool> _online() => isOnline();

  static const _photoExts = ['.jpg', '.jpeg', '.png'];
  static const _maxPhotoBytes = 5 * 1024 * 1024;

  /// Upload validation (mirrored server-side with real backends):
  /// type + size. Missing files are tolerated so mock/demo paths and
  /// unit tests keep working; the camera flow always passes real files.
  String? validatePhoto(String localPath) {
    final lower = localPath.toLowerCase();
    if (!_photoExts.any(lower.endsWith)) return 'localPath';
    final file = File(localPath);
    if (file.existsSync() && file.lengthSync() > _maxPhotoBytes) {
      return 'localPath';
    }
    return null;
  }

  Future<bool> _hasPending(String entityId) async {
    final state = await SyncEngine.entityState(oplog, entityId);
    return state != 'synced';
  }

  Future<bool> _confirmedFromOutbox(String id) async {
    final ops = await oplog.opsFor(id);
    if ((await local.rating(id)) != null) return true;
    return ops.any((o) => o.opType == 'confirm' && o.status != 'failed');
  }

  // ---------- reads ----------

  @override
  Future<Result<List<ServiceRequest>>> listForUser(AppUser user) async {
    if (await _online()) {
      await remote.refresh();
      final all = remote.requests.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await local.upsertRequests(all);
      await local.upsertUsers(remote.users.values.toList());
      for (final entry in remote.assignments.entries) {
        await local.upsertAssignment(entry.value);
      }
    }
    return switch (user.role) {
      'customer' => Ok(await local.requestsForCustomer(user.id)),
      'technician' => Ok(await local.requestsForTechnician(user.id)),
      _ => Ok(await local.allRequests()),
    };
  }

  @override
  Future<Result<List<ServiceRequest>>> dispatchQueue(String view) async {
    if (await _online()) {
      await remote.refresh();
      final now = DateTime.now();
      final all = remote.requests.values.toList();
      final filtered = switch (view) {
        'new' => all.where((r) => r.status == 'new').toList(),
        'active' =>
          all
              .where(
                (r) => !{'new', 'completed', 'cancelled'}.contains(r.status),
              )
              .toList(),
        'overdue' =>
          all.where((r) => isOverdue(r.slaDueAt, r.status, now)).toList(),
        _ =>
          all
              .where((r) => r.status == 'completed' || r.status == 'cancelled')
              .toList(),
      }..sort((a, b) => a.slaDueAt.compareTo(b.slaDueAt));
      await local.upsertRequests(filtered);
    } else {
      final cached = await local.allRequests();
      final now = DateTime.now();
      final filtered = switch (view) {
        'new' => cached.where((r) => r.status == 'new').toList(),
        'active' =>
          cached
              .where(
                (r) => !{'new', 'completed', 'cancelled'}.contains(r.status),
              )
              .toList(),
        'overdue' =>
          cached.where((r) => isOverdue(r.slaDueAt, r.status, now)).toList(),
        _ =>
          cached
              .where((r) => r.status == 'completed' || r.status == 'cancelled')
              .toList(),
      }..sort((a, b) => a.slaDueAt.compareTo(b.slaDueAt));
      return Ok(filtered);
    }
    // Serve the local view of what was just mirrored.
    return listForUser(
      const AppUser(id: '', name: '', phone: '', role: 'supervisor'),
    );
  }

  @override
  Future<Result<Map<String, int>>> technicianWorkload() async {
    if (await _online()) {
      await remote.refresh();
      final counts = <String, int>{};
      for (final a in remote.assignments.values) {
        final req = remote.requests[a.requestId];
        if (req == null || {'completed', 'cancelled'}.contains(req.status)) {
          continue;
        }
        counts[a.technicianId] = (counts[a.technicianId] ?? 0) + 1;
      }
      return Ok(counts);
    }
    final all = await local.allRequests();
    final counts = <String, int>{};
    for (final r in all) {
      if ({'completed', 'cancelled', 'new'}.contains(r.status)) continue;
      final a = await local.assignment(r.id);
      if (a == null) continue;
      counts[a.technicianId] = (counts[a.technicianId] ?? 0) + 1;
    }
    return Ok(counts);
  }

  @override
  Future<Result<RequestDetails>> details(String id) async {
    if (await _online() && !await _hasPending(id)) {
      await _mirrorBundle(id);
    }
    final bundle = await local.localDetails(
      id,
      confirmedFromOutbox: () => _confirmedFromOutbox(id),
    );
    if (bundle == null) return const Err(NotFound());
    return Ok(bundle);
  }

  /// Replace local collections from remote (only when nothing pending).
  Future<void> _mirrorBundle(String id) async {
    await remote.refresh();
    final req = remote.requests[id];
    if (req == null) return;
    await local.upsertRequests([req]);
    final asg = remote.assignments[id];
    if (asg != null) await local.upsertAssignment(asg);
    // Collections: delete-then-insert would need delete APIs; Phase 4
    // mirrors headers + assignment and appends missing timeline events
    // by matching (from,to,by) triples to avoid duplicates.
    final known = await local.timeline(id);
    for (final e in remote.timelines[id] ?? const <StatusEvent>[]) {
      final dup = known.any(
        (k) => k.from == e.from && k.to == e.to && k.byUserId == e.byUserId,
      );
      if (!dup) await local.recordTimeline(e);
    }
    final knownNotes = await local.notes(id);
    for (final n in remote.notes[id] ?? const <JobNote>[]) {
      if (!knownNotes.any((k) => k.body == n.body && k.kind == n.kind)) {
        await local.addNote(n);
      }
    }
    final rating = remote.ratings[id];
    if (rating != null) await local.upsertRating(rating);
  }

  @override
  Future<Result<List<ServiceInfo>>> services() async {
    if (await _online()) {
      await remote.refresh();
      final list = remote.services.values.toList();
      await local.upsertServices(list);
      return Ok(list);
    }
    return Ok(await local.cachedServices());
  }

  @override
  Future<Result<List<AppUser>>> technicians() async {
    if (await _online()) {
      await remote.refresh();
      await local.upsertUsers(remote.users.values.toList());
    }
    final cached = await local.allRequests();
    if (cached.isEmpty && !await _online()) return const Ok([]);
    // Users table is the cache; filter technicians.
    final users = await local.allUsers();
    return Ok(users.where((u) => u.role == 'technician').toList());
  }

  // ---------- writes (enqueue-first) ----------

  Future<bool> _enqueue(SyncOp op) => oplog.enqueue(op);

  SyncOp _op({
    required String entityId,
    required String opType,
    required Map<String, dynamic> payload,
    String? opId,
    String entityType = 'request',
  }) {
    return SyncOp(
      opId: opId ?? _newId('op'),
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  /// Fan a notification out to [target]. Offline-first: recipients are
  /// resolved locally from the users mirror (only the acting device sees
  /// them instantly), AND a durable 'notify' op fans out server-side so
  /// every recipient's other devices converge via realtime/pull.
  Future<void> _notify(
    NotifyTarget target, {
    required String kind,
    required String title,
    required String body,
  }) async {
    if (target.isEmpty) return;
    final ids = <String>{...target.userIds};
    for (final u in remote.users.values) {
      if (target.roles.contains(u.role)) ids.add(u.id);
    }
    for (final id in ids) {
      await notifications.notify(
        userId: id,
        kind: kind,
        title: title,
        body: body,
      );
    }
    final opId = _newId('op');
    await _enqueue(
      _op(
        opId: opId,
        entityType: 'notification',
        entityId: 'notif-$opId',
        opType: 'notify',
        payload: {
          'userIds': target.userIds,
          'roles': target.roles,
          'kind': kind,
          'title': title,
          'body': body,
        },
      ),
    );
  }

  @override
  Future<Result<ServiceRequest>> create(AppUser user, RequestDraft d) async {
    final field = validateDraft(
      description: d.description,
      address: d.address,
      governorate: d.governorate,
      phone: d.phone,
    );
    if (field != null) return Err(ValidationFailed(field));
    final online = await _online();
    var service = online
        ? remote.services[d.serviceId]
        : await _cachedService(d.serviceId);
    if (online && service == null) {
      // Catalogue may not be mirrored yet on first use; prime it.
      await remote.refresh();
      service = remote.services[d.serviceId];
    }
    if (service == null) return const Err(ValidationFailed('serviceId'));

    final now = DateTime.now();
    final id = _newId('req');
    final opId = _newId('op');
    final req = ServiceRequest(
      id: id,
      customerId: user.id,
      serviceId: d.serviceId,
      description: d.description.trim(),
      address: d.address.trim(),
      governorate: d.governorate,
      phone: d.phone.trim(),
      priority: 'normal',
      status: 'new',
      slaDueAt: now.add(Duration(hours: service.defaultSlaHours)),
      idempotencyKey: opId,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    await local.upsertRequests([req]);
    await local.recordTimeline(
      StatusEvent(
        requestId: id,
        from: '-',
        to: 'new',
        byUserId: user.id,
        createdAt: now,
      ),
    );
    final fresh = await _enqueue(
      _op(
        opId: opId,
        entityId: id,
        opType: 'create',
        payload: {
          'requestId': id,
          'customerId': user.id,
          'serviceId': d.serviceId,
          'description': req.description,
          'address': req.address,
          'governorate': req.governorate,
          'phone': req.phone,
          'preferredSlot': d.preferredSlot,
          'slaHours': service.defaultSlaHours,
        },
      ),
    );
    analytics.log('request_created', {'id': id});
    if (!fresh) {
      final existing = await local.requestById(id);
      if (existing != null) return Ok(existing);
    }
    await _notify(
      NotifyTarget.roles(['admin', 'supervisor']),
      kind: 'new_request',
      title: 'طلب جديد',
      body: '#$id — بانتظار التوجيه',
    );
    await engine.flush();
    return Ok((await local.requestById(id)) ?? req);
  }

  Future<ServiceInfo?> _cachedService(String id) async {
    final list = await local.cachedServices();
    return list.where((s) => s.id == id).firstOrNull;
  }

  Future<List<PartInfo>> _onlineParts() async {
    final res = await remote.partsCatalog();
    return switch (res) {
      Ok(value: final v) => v,
      Err() => const [],
    };
  }

  @override
  Future<Result<ServiceRequest>> assign({
    required AppUser by,
    required String requestId,
    required String technicianId,
    required String idempotencyKey,
  }) async {
    if (by.role != 'supervisor' && by.role != 'admin') {
      return const Err(PermissionDenied());
    }
    final current =
        await local.requestById(requestId) ?? remote.requests[requestId];
    if (current == null) return const Err(NotFound());
    final tech =
        remote.users[technicianId] ?? await local.userById(technicianId);
    if (tech == null || tech.role != 'technician') {
      return const Err(ValidationFailed('technicianId'));
    }
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'assign',
        payload: {
          'byId': by.id,
          'technicianId': technicianId,
          'baseVersion': current.version,
        },
      ),
    );
    if (!fresh) {
      final existing = await local.requestById(requestId);
      return Ok(existing ?? current);
    }
    await _applyHeader(current, status: 'assigned', byId: by.id, reason: null);
    await local.upsertAssignment(
      AssignmentInfo(
        id: 'asg-$requestId',
        requestId: requestId,
        technicianId: technicianId,
        technicianName: tech.name,
        assignedBy: by.id,
      ),
    );
    await _notify(
      NotifyTarget.user(technicianId),
      kind: 'assignment',
      title: 'طلب جديد مُسند',
      body: '#$requestId — بانتظار القبول',
    );
    analytics.log('assigned', {'id': requestId, 'tech': technicianId});
    await engine.flush();
    return Ok((await local.requestById(requestId)) ?? current);
  }

  /// Provisional header bump (+1 version, timeline event).
  Future<ServiceRequest> _applyHeader(
    ServiceRequest current, {
    String? status,
    String? priority,
    int? estimateEgp,
    required String byId,
    String? reason,
  }) async {
    final now = DateTime.now();
    final updated = ServiceRequest(
      id: current.id,
      customerId: current.customerId,
      serviceId: current.serviceId,
      description: current.description,
      address: current.address,
      governorate: current.governorate,
      phone: current.phone,
      photoLocalPath: current.photoLocalPath,
      priority: priority ?? current.priority,
      status: status ?? current.status,
      slaDueAt: current.slaDueAt,
      estimateEgp: estimateEgp ?? current.estimateEgp,
      idempotencyKey: current.idempotencyKey,
      version: current.version + 1,
      createdAt: current.createdAt,
      updatedAt: now,
    );
    await local.upsertRequests([updated]);
    if (status != null && status != current.status) {
      await local.recordTimeline(
        StatusEvent(
          requestId: current.id,
          from: current.status,
          to: status,
          byUserId: byId,
          reason: reason,
          createdAt: now,
        ),
      );
    }
    return updated;
  }

  @override
  Future<Result<ServiceRequest>> setPriority({
    required AppUser by,
    required String requestId,
    required String priority,
    required int baseVersion,
    required String idempotencyKey,
  }) async {
    if (by.role != 'supervisor' && by.role != 'admin') {
      return const Err(PermissionDenied());
    }
    final current =
        await local.requestById(requestId) ?? remote.requests[requestId];
    if (current == null) return const Err(NotFound());
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'priority',
        payload: {'priority': priority, 'baseVersion': current.version},
      ),
    );
    if (!fresh) {
      final existing = await local.requestById(requestId);
      return Ok(existing ?? current);
    }
    await _applyHeader(current, priority: priority, byId: by.id);
    await engine.flush();
    return Ok((await local.requestById(requestId)) ?? current);
  }

  @override
  Future<Result<ServiceRequest>> transition({
    required AppUser by,
    required String requestId,
    required String to,
    required int baseVersion,
    required String idempotencyKey,
    String? reason,
  }) async {
    final current =
        await local.requestById(requestId) ?? remote.requests[requestId];
    if (current == null) return const Err(NotFound());
    // Guard evaluated on local state: works fully offline.
    final err = checkTransition(current.status, to);
    if (err != null) return Err(err);
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'status',
        payload: {
          'byId': by.id,
          'to': to,
          'baseVersion': current.version,
          'reason': reason,
        },
      ),
    );
    if (!fresh) {
      final existing = await local.requestById(requestId);
      return Ok(existing ?? current);
    }
    await _applyHeader(current, status: to, byId: by.id, reason: reason);
    await _notify(
      NotifyTarget(
        userIds: [current.customerId],
        roles: const ['admin', 'supervisor'],
      ),
      kind: 'status',
      title: 'تحديث الطلب',
      body: '#$requestId: $to',
    );
    analytics.log('status_changed', {'id': requestId, 'to': to});
    await engine.flush();
    return Ok((await local.requestById(requestId)) ?? current);
  }

  @override
  Future<Result<void>> addNote({
    required AppUser by,
    required String requestId,
    required String kind,
    required String body,
    required String idempotencyKey,
  }) async {
    if (body.trim().isEmpty) return const Err(ValidationFailed('body'));
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'note',
        payload: {'authorId': by.id, 'kind': kind, 'body': body.trim()},
      ),
    );
    if (!fresh) return const Ok(null);
    await local.addNote(
      JobNote(
        requestId: requestId,
        authorId: by.id,
        kind: kind,
        body: body.trim(),
        createdAt: DateTime.now(),
      ),
    );
    await engine.flush();
    return const Ok(null);
  }

  @override
  Future<Result<void>> addPhoto({
    required AppUser by,
    required String requestId,
    required String kind,
    required String localPath,
    required String idempotencyKey,
  }) async {
    if (localPath.trim().isEmpty) {
      return const Err(ValidationFailed('localPath'));
    }
    if (validatePhoto(localPath) != null) {
      return const Err(ValidationFailed('localPath'));
    }
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'photo',
        payload: {'kind': kind, 'localPath': localPath},
      ),
    );
    if (!fresh) return const Ok(null);
    await local.addPhoto(
      JobPhoto(requestId: requestId, kind: kind, localPath: localPath),
    );
    await engine.flush();
    return const Ok(null);
  }

  @override
  Future<Result<void>> addPart({
    required AppUser by,
    required String requestId,
    required String partId,
    required int qty,
    required String idempotencyKey,
  }) async {
    if (qty < 1) return const Err(ValidationFailed('qty'));
    final online = await _online();
    final catalog = online
        ? await _onlineParts()
        : await local.cachedParts();
    final match = catalog.where((p) => p.id == partId).firstOrNull;
    if (match == null) return const Err(ValidationFailed('partId'));
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'part',
        payload: {'partId': partId, 'qty': qty},
      ),
    );
    if (!fresh) return const Ok(null);
    await local.addPartUsage(
      requestId,
      PartUsage(
        partId: partId,
        partName: match.nameEn,
        priceEgp: match.priceEgp,
        qty: qty,
      ),
    );
    await engine.flush();
    return const Ok(null);
  }

  @override
  Future<Result<void>> setEstimate({
    required AppUser by,
    required String requestId,
    required int amountEgp,
    required String idempotencyKey,
  }) async {
    if (amountEgp < 0) return const Err(ValidationFailed('estimateEgp'));
    final current =
        await local.requestById(requestId) ?? remote.requests[requestId];
    if (current == null) return const Err(NotFound());
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'estimate',
        payload: {'amountEgp': amountEgp},
      ),
    );
    if (!fresh) return const Ok(null);
    await _applyHeader(current, estimateEgp: amountEgp, byId: by.id);
    await engine.flush();
    return const Ok(null);
  }

  @override
  Future<Result<void>> confirm({
    required AppUser by,
    required String requestId,
    required String idempotencyKey,
  }) async {
    final current =
        await local.requestById(requestId) ?? remote.requests[requestId];
    if (current == null) return const Err(NotFound());
    if (current.status != 'completed') {
      return const Err(ValidationFailed('status'));
    }
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'confirm',
        payload: {},
      ),
    );
    if (!fresh) return const Ok(null);
    final dispatcher =
        (await local.assignment(requestId))?.assignedBy ??
        remote.assignments[requestId]?.assignedBy;
    await _notify(
      NotifyTarget(
        userIds: dispatcher == null ? const [] : [dispatcher],
        roles: const ['admin'],
      ),
      kind: 'confirm',
      title: 'تم تأكيد الاستلام',
      body: '#$requestId',
    );
    analytics.log('confirmed', {'id': requestId});
    await engine.flush();
    return const Ok(null);
  }

  @override
  Future<Result<void>> rate({
    required AppUser by,
    required String requestId,
    required int stars,
    required String idempotencyKey,
    String? comment,
  }) async {
    if (stars < 1 || stars > 5) return const Err(ValidationFailed('stars'));
    final fresh = await _enqueue(
      _op(
        opId: idempotencyKey,
        entityId: requestId,
        opType: 'rate',
        payload: {'stars': stars, 'comment': comment},
      ),
    );
    if (!fresh) return const Ok(null);
    await local.upsertRating(
      RatingInfo(requestId: requestId, stars: stars, comment: comment),
    );
    final techId =
        (await local.assignment(requestId))?.technicianId ??
        remote.assignments[requestId]?.technicianId;
    if (techId != null) {
      await _notify(
        NotifyTarget.user(techId),
        kind: 'rating',
        title: 'تقييم جديد',
        body: '#$requestId: $stars★',
      );
    }
    analytics.log('rated', {'id': requestId, 'stars': '$stars'});
    await engine.flush();
    return const Ok(null);
  }

  // ---------- replay (engine callbacks) ----------

  Future<(ReplayOutcome, String?)> _execute(SyncOp op) async {
    try {
      final p = op.payload;
      switch (op.opType) {
        case 'create':
          final res = await remote.createRequest(
            customerId: p['customerId'] as String,
            draft: RequestDraft(
              serviceId: p['serviceId'] as String,
              description: p['description'] as String,
              address: p['address'] as String,
              governorate: p['governorate'] as String,
              phone: p['phone'] as String,
              preferredSlot: p['preferredSlot'] as String?,
            ),
            idempotencyKey: op.opId,
            slaHours: (p['slaHours'] as num).toInt(),
            requestId: p['requestId'] as String,
          );
          return _classify(res);
        case 'assign':
          return _classify(
            await remote.assign(
              byId: p['byId'] as String,
              requestId: op.entityId,
              technicianId: p['technicianId'] as String,
            ),
          );
        case 'priority':
          return _classify(
            await remote.setPriority(
              requestId: op.entityId,
              priority: p['priority'] as String,
              baseVersion: (p['baseVersion'] as num).toInt(),
            ),
          );
        case 'status':
          return _classify(
            await remote.transition(
              byId: p['byId'] as String,
              requestId: op.entityId,
              to: p['to'] as String,
              baseVersion: (p['baseVersion'] as num).toInt(),
              reason: p['reason'] as String?,
            ),
          );
        case 'note':
          return _classify(
            await remote.addNote(
              JobNote(
                requestId: op.entityId,
                authorId: p['authorId'] as String,
                kind: p['kind'] as String,
                body: p['body'] as String,
                createdAt: DateTime.now(),
              ),
            ),
          );
        case 'photo':
          return _classify(
            await remote.addPhoto(
              JobPhoto(
                requestId: op.entityId,
                kind: p['kind'] as String,
                localPath: p['localPath'] as String,
              ),
            ),
          );
        case 'part':
          return _classify(
            await remote.addPart(
              requestId: op.entityId,
              partId: p['partId'] as String,
              qty: (p['qty'] as num).toInt(),
            ),
          );
        case 'estimate':
          return _classify(
            await remote.setEstimate(
              requestId: op.entityId,
              amountEgp: (p['amountEgp'] as num).toInt(),
            ),
          );
        case 'confirm':
          return _classify(await remote.confirm(requestId: op.entityId));
        case 'rate':
          return _classify(
            await remote.rate(
              requestId: op.entityId,
              stars: (p['stars'] as num).toInt(),
              comment: p['comment'] as String?,
            ),
          );
        case 'notify':
          return _classify(
            await remote.pushNotifications(
              userIds: (p['userIds'] as List<dynamic>? ?? const [])
                  .cast<String>(),
              roles: (p['roles'] as List<dynamic>? ?? const []).cast<String>(),
              kind: p['kind'] as String,
              title: p['title'] as String,
              body: p['body'] as String,
            ),
          );
        case 'read':
          return _classify(
            await remote.markNotificationRead(
              id: (p['id'] as num).toInt(),
              userId: p['userId'] as String,
            ),
          );
        default:
          return (ReplayOutcome.failed, 'unknown-op:${op.opType}');
      }
    } catch (e) {
      return (ReplayOutcome.retry, e.toString());
    }
  }

  (ReplayOutcome, String?) _classify(Result res) {
    return switch (res) {
      Ok() => (ReplayOutcome.applied, null),
      Err(error: SyncFailed(reason: final r)) =>
        r == 'version-conflict'
            ? (ReplayOutcome.conflict, r)
            : (ReplayOutcome.retry, r),
      Err(error: ValidationFailed(field: final f)) => (
        ReplayOutcome.failed,
        'validation:$f',
      ),
      Err(error: PermissionDenied()) => (
        ReplayOutcome.failed,
        'permission-denied',
      ),
      Err(error: IllegalTransition(:final from)) => (
        ReplayOutcome.failed,
        'illegal:$from',
      ),
      Err(error: NotFound()) => (ReplayOutcome.failed, 'not-found'),
      Err(error: Unauthorized()) => (ReplayOutcome.failed, 'unauthorized'),
    };
  }

  /// Server wins; the intent is re-applied once on the fresh version when
  /// still legal, then local cache is refreshed. Else the op fails loudly.
  Future<bool> _rebase(SyncOp op) async {
    final current = remote.requests[op.entityId];
    if (current == null) return false;
    final p = op.payload;
    Result res;
    if (op.opType == 'status') {
      final to = p['to'] as String;
      if (!canTransitionRemote(current.status, to)) return false;
      res = await remote.transition(
        byId: p['byId'] as String,
        requestId: op.entityId,
        to: to,
        baseVersion: current.version,
        reason: p['reason'] as String?,
      );
    } else if (op.opType == 'priority') {
      res = await remote.setPriority(
        requestId: op.entityId,
        priority: p['priority'] as String,
        baseVersion: current.version,
      );
    } else {
      return false;
    }
    if (res is! Ok) return false;
    // Refresh local to server truth after rebase.
    await local.upsertRequests([remote.requests[op.entityId]!]);
    final event = remote.timelines[op.entityId]?.lastOrNull;
    if (event != null) {
      final known = await local.timeline(op.entityId);
      final dup = known.any((k) => k.from == event.from && k.to == event.to);
      if (!dup) await local.recordTimeline(event);
    }
    return true;
  }

  bool canTransitionRemote(String from, String to) =>
      checkTransition(from, to) == null;

  // ---------- sync UX ----------

  @override
  Future<String> syncState(String entityId) =>
      SyncEngine.entityState(oplog, entityId);

  @override
  Future<void> retryEntity(String entityId) => engine.retryEntity(entityId);

  @override
  Future<void> flushOutbox() async {
    await engine.flush();
  }

  // ---------- role-to-role notifications ----------

  @override
  Future<void> refreshInbox(String userId) async {
    if (!await _online()) return;
    final items = await remote.pullInbox(userId);
    await notifications.mergeInbox(userId, items);
  }

  @override
  Future<void> markNotificationRead(String userId, int id) async {
    await notifications.markRead(id);
    final opId = _newId('op');
    await _enqueue(
      _op(
        opId: opId,
        entityType: 'notification',
        entityId: 'notif-read-$opId',
        opType: 'read',
        payload: {'id': id, 'userId': userId},
      ),
    );
    await engine.flush();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
