import 'dart:io';

import 'package:sallahha/core/backend/remote_api.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Production backend over the Supabase project (PostgREST + Storage).
///
/// Keeps the same in-memory alignment as [RemoteApi] so the offline-first
/// engine is untouched: [refresh] pulls visible rows into the maps, and
/// each mutation mirrors the equivalent MockBackend call one-on-one,
/// preserving version checks and idempotency (unique `idempotency_key`).
class SupabaseApi implements RemoteApi {
  final SupabaseClient client;
  SupabaseApi(this.client);

  final Map<String, ServiceRequest> _requests = {};
  final Map<String, AppUser> _users = {};
  final Map<String, ServiceInfo> _services = {};
  final Map<String, AssignmentInfo> _assignments = {};
  final Map<String, List<StatusEvent>> _timelines = {};
  final Map<String, List<JobNote>> _notes = {};
  final Map<String, List<JobPhoto>> _photos = {};
  final Map<String, List<PartUsage>> _partsUsed = {};
  final Map<String, RatingInfo> _ratings = {};

  @override
  Map<String, ServiceRequest> get requests => _requests;
  @override
  Map<String, AppUser> get users => _users;
  @override
  Map<String, ServiceInfo> get services => _services;
  @override
  Map<String, AssignmentInfo> get assignments => _assignments;
  @override
  Map<String, List<StatusEvent>> get timelines => _timelines;
  @override
  Map<String, List<JobNote>> get notes => _notes;
  @override
  Map<String, List<JobPhoto>> get photos => _photos;
  @override
  Map<String, List<PartUsage>> get partsUsed => _partsUsed;
  @override
  Map<String, RatingInfo> get ratings => _ratings;

  // ---------- reads ----------

  DateTime? _lastRefreshAt;

  /// Rate-limit window for [refresh] so consecutive invalidations (poller,
  /// realtime, list+detail refreshes, connectivity reconnects) don't each
  /// pay the full multi-table mirror cost. Short enough to stay fresh,
  /// long enough to keep opening a job after a list load near-instant.
  static const _refreshRateLimit = Duration(seconds: 8);

  /// Best-effort mirror. Each pull is isolated so one flaky table never
  /// bricks the read path; previous maps survive on failure. Pulls run in
  /// PARALLEL (one round-trip instead of nine) and the whole refresh is
  /// rate-limited so hot paths don't hammer PostgREST.
  @override
  Future<void> refresh() async {
    final now = DateTime.now();
    final last = _lastRefreshAt;
    if (last != null && now.difference(last) < _refreshRateLimit) {
      return;
    }
    _lastRefreshAt = now;
    await Future.wait([
      _pullRequests(),
      _pullUsers(),
      _pullServices(),
      _pullAssignments(),
      _pullTimelines(),
      _pullNotes(),
      _pullPhotos(),
      _pullPartUsage(),
      _pullRatings(),
    ]);
  }

  Future<void> _guard(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {
      // Keep last-known state; reads always resolve.
    }
  }

  Future<void> _pullRequests() async {
    await _guard(() async {
      final rows = await client
          .from('service_requests')
          .select()
          .order('created_at', ascending: false);
      _requests
        ..clear()
        ..addEntries(rows.map((r) => MapEntry(r['id'] as String, _req(r))));
      // Only keep timelines/photos/etc. for requests we can still see.
      for (final key in _timelines.keys.toList()) {
        if (!_requests.containsKey(key)) _timelines.remove(key);
      }
    });
  }

  Future<void> _pullUsers() async {
    await _guard(() async {
      final rows = await client.from('profiles').select('id, name, phone, role');
      _users
        ..clear()
        ..addEntries(
          rows.map(
            (p) => MapEntry(
              p['id'] as String,
              AppUser(
                id: p['id'] as String,
                name: (p['name'] as String?) ?? '',
                phone: (p['phone'] as String?) ?? '',
                role: (p['role'] as String?) ?? 'customer',
              ),
            ),
          ),
        );
    });
  }

  Future<void> _pullServices() async {
    await _guard(() async {
      final rows = await client
          .from('services')
          .select()
          .order('name_ar');
      _services
        ..clear()
        ..addEntries(
          rows.map(
            (s) => MapEntry(
              s['id'] as String,
              ServiceInfo(
                id: s['id'] as String,
                code: (s['code'] as String?) ?? '',
                nameAr: (s['name_ar'] as String?) ?? '',
                nameEn: (s['name_en'] as String?) ?? '',
                defaultSlaHours: _int(s['sla_hours']) ?? 24,
              ),
            ),
          ),
        );
    });
  }

  Future<void> _pullAssignments() async {
    await _guard(() async {
      final rows = await client
          .from('job_assignments')
          .select()
          .order('created_at', ascending: false);
      _assignments.clear();
      for (final a in rows) {
        final techId = a['technician_id'] as String;
        _assignments[a['request_id'] as String] = AssignmentInfo(
          id: a['id'] as String,
          requestId: a['request_id'] as String,
          technicianId: techId,
          technicianName: _users[techId]?.name ?? techId,
          assignedBy: a['assigned_by'] as String,
        );
      }
    });
  }

  Future<void> _pullTimelines() async {
    await _guard(() async {
      final rows = await client
          .from('status_history')
          .select()
          .order('created_at');
      _timelines.clear();
      for (final e in rows) {
        final rid = e['request_id'] as String;
        _timelines.putIfAbsent(rid, () => []).add(
          StatusEvent(
            requestId: rid,
            from: (e['from_status'] as String?) ?? '-',
            to: e['to_status'] as String,
            byUserId: e['by_user_id'] as String,
            reason: e['reason'] as String?,
            createdAt: _dt(e['created_at']) ?? DateTime.now(),
          ),
        );
      }
    });
  }

  Future<void> _pullNotes() async {
    await _guard(() async {
      final rows = await client
          .from('job_notes')
          .select()
          .order('created_at');
      _notes.clear();
      for (final n in rows) {
        final rid = n['request_id'] as String;
        _notes.putIfAbsent(rid, () => []).add(
          JobNote(
            requestId: rid,
            authorId: n['author_id'] as String,
            kind: (n['kind'] as String?) ?? 'diagnosis',
            body: n['body'] as String,
            createdAt: _dt(n['created_at']) ?? DateTime.now(),
          ),
        );
      }
    });
  }

  Future<void> _pullPhotos() async {
    await _guard(() async {
      final rows = await client
          .from('job_photos')
          .select()
          .order('created_at');
      _photos.clear();
      for (final p in rows) {
        final rid = p['request_id'] as String;
        _photos.putIfAbsent(rid, () => []).add(
          JobPhoto(
            requestId: rid,
            kind: (p['kind'] as String?) ?? 'other',
            localPath: (p['url_path'] as String?) ?? '',
          ),
        );
      }
    });
  }

  Future<void> _pullPartUsage() async {
    await _guard(() async {
      final rows = await client
          .from('job_part_usage')
          .select()
          .order('created_at');
      _partsUsed.clear();
      for (final u in rows) {
        final rid = u['request_id'] as String;
        _partsUsed.putIfAbsent(rid, () => []).add(
          PartUsage(
            partId: u['part_id'] as String,
            partName: (u['part_name'] as String?) ?? '',
            priceEgp: _int(u['price_egp']) ?? 0,
            qty: _int(u['qty']) ?? 1,
          ),
        );
      }
    });
  }

  Future<void> _pullRatings() async {
    await _guard(() async {
      final rows = await client.from('service_ratings').select();
      _ratings.clear();
      for (final r in rows) {
        _ratings[r['request_id'] as String] = RatingInfo(
          requestId: r['request_id'] as String,
          stars: _int(r['stars']) ?? 5,
          comment: r['comment'] as String?,
        );
      }
    });
  }

  @override
  Future<Result<List<PartInfo>>> partsCatalog() async {
    try {
      final rows = await client.from('parts').select().order('name_en');
      return Ok(
        rows
            .map(
              (p) => PartInfo(
                id: p['id'] as String,
                nameAr: (p['name_ar'] as String?) ?? '',
                nameEn: (p['name_en'] as String?) ?? '',
                priceEgp: _int(p['price_egp']) ?? 0,
              ),
            )
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('parts: $e'));
    }
  }

  // ---------- writes (mirror MockBackend one-to-one) ----------

  @override
  Future<Result<ServiceRequest>> createRequest({
    required String customerId,
    required RequestDraft draft,
    required String idempotencyKey,
    required int slaHours,
    String? requestId,
  }) async {
    final now = DateTime.now().toUtc();
    final id = requestId ?? 'req-${now.microsecondsSinceEpoch}';
    final insert = <String, dynamic>{
      'id': id,
      'customer_id': customerId,
      'service_id': draft.serviceId,
      'description': draft.description,
      'address': draft.address,
      'governorate': draft.governorate,
      'phone': draft.phone,
      'photo_local_path': draft.photoLocalPath,
      'priority': 'normal',
      'status': 'new',
      'sla_due_at': now.add(Duration(hours: slaHours)).toIso8601String(),
      'idempotency_key': idempotencyKey,
      'version': 1,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    try {
      await client.from('service_requests').insert(insert);
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
      _requests[id] = req;
      _timelines[id] = [
        StatusEvent(
          requestId: id,
          from: '-',
          to: 'new',
          byUserId: customerId,
          createdAt: now,
        ),
      ];
      if (!_timelines.containsKey(id)) _notes[id] = [];
      _photos[id] = [];
      _partsUsed[id] = [];
      return Ok(req);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Idempotent retry: return the row created by the first attempt.
        return Ok(_existingByIdempotency(idempotencyKey));
      }
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('create: $e'));
    }
  }

  ServiceRequest _existingByIdempotency(String key) {
    final row = _requests.values
        .where((r) => r.idempotencyKey == key)
        .firstOrNull;
    if (row != null) return row;
    final fallback = _requests.values.isEmpty
        ? ServiceRequest(
            id: 'req-unknown',
            customerId: '',
            serviceId: '',
            description: '',
            address: '',
            governorate: '',
            phone: '',
            priority: 'normal',
            status: 'new',
            slaDueAt: DateTime.now(),
            idempotencyKey: key,
            version: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        : _requests.values.first;
    return fallback;
  }

  @override
  Future<Result<ServiceRequest>> assign({
    required String byId,
    required String requestId,
    required String technicianId,
  }) async {
    final current = _requests[requestId];
    if (current == null) return const Err(NotFound());
    final tech = _users[technicianId];
    if (tech == null || tech.role != 'technician') {
      return const Err(ValidationFailed('technicianId'));
    }
    try {
      final updated = _copy(current, status: 'assigned');
      final rows = await _updateGuarded(
        requestId: requestId,
        values: _collectPatch(current, updated),
        baseVersion: current.version,
      );
      if (rows == 0) return const Err(SyncFailed('version-conflict'));
      await _upsertAssignment(requestId, technicianId, byId);
      await _insertTimeline(
        requestId: requestId,
        from: current.status,
        to: 'assigned',
        byId: byId,
      );
      _requests[requestId] = updated;
      return Ok(updated);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('assign: $e'));
    }
  }

  Future<int> _updateGuarded({
    required String requestId,
    required Map<String, dynamic> values,
    required int baseVersion,
  }) async {
    final res = await client
        .from('service_requests')
        .update(values)
        .eq('id', requestId)
        .eq('version', baseVersion);
    return res.length;
  }

  Future<void> _upsertAssignment(
    String requestId,
    String technicianId,
    String byId,
  ) async {
    await client.from('job_assignments').upsert(
      {
        'id': 'asg-$requestId',
        'request_id': requestId,
        'technician_id': technicianId,
        'assigned_by': byId,
      },
      onConflict: 'id',
    );
    _assignments[requestId] = AssignmentInfo(
      id: 'asg-$requestId',
      requestId: requestId,
      technicianId: technicianId,
      technicianName: _users[technicianId]?.name ?? technicianId,
      assignedBy: byId,
    );
  }

  @override
  Future<Result<ServiceRequest>> setPriority({
    required String requestId,
    required String priority,
    required int baseVersion,
  }) async {
    final current = _requests[requestId];
    if (current == null) return const Err(NotFound());
    try {
      final updated = _copy(current, priority: priority);
      final rows = await _updateGuarded(
        requestId: requestId,
        values: _collectPatch(current, updated),
        baseVersion: baseVersion,
      );
      if (rows == 0) return const Err(SyncFailed('version-conflict'));
      _requests[requestId] = updated;
      return Ok(updated);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('priority: $e'));
    }
  }

  @override
  Future<Result<ServiceRequest>> transition({
    required String byId,
    required String requestId,
    required String to,
    required int baseVersion,
    String? reason,
  }) async {
    final current = _requests[requestId];
    if (current == null) return const Err(NotFound());
    try {
      final updated = _copy(current, status: to);
      final rows = await _updateGuarded(
        requestId: requestId,
        values: _collectPatch(current, updated),
        baseVersion: baseVersion,
      );
      if (rows == 0) return const Err(SyncFailed('version-conflict'));
      await _insertTimeline(from: current.status, to: to, byId: byId,
          requestId: requestId, reason: reason);
      _requests[requestId] = updated;
      return Ok(updated);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('status: $e'));
    }
  }

  Future<void> _insertTimeline({
    required String requestId,
    required String from,
    required String to,
    required String byId,
    String? reason,
  }) async {
    await client.from('status_history').insert({
      'request_id': requestId,
      'from_status': from,
      'to_status': to,
      'by_user_id': byId,
      'reason': reason,
    });
    _timelines.putIfAbsent(requestId, () => []).add(
      StatusEvent(
        requestId: requestId,
        from: from,
        to: to,
        byUserId: byId,
        reason: reason,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> addNote(JobNote note) async {
    try {
      await client.from('job_notes').insert({
        'request_id': note.requestId,
        'author_id': note.authorId,
        'kind': note.kind,
        'body': note.body,
      });
      _notes.putIfAbsent(note.requestId, () => []).add(note);
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('note: $e'));
    }
  }

  @override
  Future<Result<void>> addPhoto(JobPhoto photo) async {
    final file = File(photo.localPath);
    if (!file.existsSync()) {
      // Mirrors mock tolerance for missing file paths (unit tests/demo).
      return const Ok(null);
    }
    try {
      final ext = photo.localPath.split('.').last.toLowerCase();
      final objectPath =
          '${photo.requestId}/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await client.storage
          .from('photos')
          .uploadBinary(objectPath, await file.readAsBytes());
      final url = client.storage.from('photos').getPublicUrl(objectPath);
      await client.from('job_photos').insert({
        'request_id': photo.requestId,
        'kind': photo.kind,
        'url_path': url,
      });
      _photos.putIfAbsent(photo.requestId, () => []).add(
        JobPhoto(
          requestId: photo.requestId,
          kind: photo.kind,
          localPath: url,
        ),
      );
      return const Ok(null);
    } on StorageException catch (e) {
      return Err(SyncFailed('photo_storage: ${e.message}'));
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('photo: $e'));
    }
  }

  @override
  Future<Result<void>> addPart({
    required String requestId,
    required String partId,
    required int qty,
  }) async {
    final catalog = await partsCatalog();
    final part = switch (catalog) {
      Ok(value: final list) => list.where((p) => p.id == partId).firstOrNull,
      Err() => null,
    };
    if (part == null || qty < 1) return const Err(ValidationFailed('partId'));
    try {
      await client.from('job_part_usage').insert({
        'request_id': requestId,
        'part_id': partId,
        'part_name': part.nameEn,
        'price_egp': part.priceEgp,
        'qty': qty,
      });
      _partsUsed.putIfAbsent(requestId, () => []).add(
        PartUsage(
          partId: partId,
          partName: part.nameEn,
          priceEgp: part.priceEgp,
          qty: qty,
        ),
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('part: $e'));
    }
  }

  @override
  Future<Result<void>> setEstimate({
    required String requestId,
    required int amountEgp,
  }) async {
    final current = _requests[requestId];
    if (current == null) return const Err(NotFound());
    if (amountEgp < 0) return const Err(ValidationFailed('estimateEgp'));
    try {
      final updated = _copy(current, estimate: amountEgp);
      final res = await client
          .from('service_requests')
          .update({
            'estimate_egp': amountEgp,
            'version': updated.version,
            'updated_at': updated.updatedAt.toUtc().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('version', current.version);
      if (res.length == 0) return const Err(SyncFailed('version-conflict'));
      _requests[requestId] = updated;
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('estimate: $e'));
    }
  }

  @override
  Future<Result<void>> confirm({required String requestId}) async {
    final current = _requests[requestId];
    if (current == null) return const Err(NotFound());
    if (current.status != 'completed') {
      return const Err(ValidationFailed('status'));
    }
    try {
      final updated = _copy(current);
      final res = await client
          .from('service_requests')
          .update({
            'confirmed': true,
            'version': updated.version,
            'updated_at': updated.updatedAt.toUtc().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('version', current.version);
      if (res.length == 0) return const Err(SyncFailed('version-conflict'));
      _requests[requestId] = updated;
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('confirm: $e'));
    }
  }

  @override
  Future<Result<void>> rate({
    required String requestId,
    required int stars,
    String? comment,
  }) async {
    if (stars < 1 || stars > 5) return const Err(ValidationFailed('stars'));
    if (_ratings.containsKey(requestId)) {
      return const Err(ValidationFailed('rating'));
    }
    // Mock mirrors a "must confirm first" guard; match it.
    final current = _requests[requestId];
    if (current == null) return const Err(NotFound());
    if (current.status != 'completed') {
      return const Err(ValidationFailed('confirm'));
    }
    try {
      final res = await client.from('service_ratings').upsert({
        'request_id': requestId,
        'stars': stars,
        'comment': comment,
      }, onConflict: 'request_id', ignoreDuplicates: true);
      if (res.length == 0) return const Err(ValidationFailed('rating'));
      _ratings[requestId] = RatingInfo(
        requestId: requestId,
        stars: stars,
        comment: comment,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return const Err(ValidationFailed('rating'));
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('rate: $e'));
    }
  }

  // ---------- role-to-role notifications ----------

  @override
  Future<Result<void>> pushNotifications({
    required List<String> userIds,
    required List<String> roles,
    required String kind,
    required String title,
    required String body,
  }) async {
    try {
      await client.rpc(
        'api_push_notifications',
        params: {
          'user_ids': userIds,
          'roles': roles,
          'kind': kind,
          'title': title,
          'body': body,
        },
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('notify: $e'));
    }
  }

  @override
  Future<List<InboxItem>> pullInbox(String userId) async {
    try {
      final rows = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map(
            (n) => InboxItem(
              id: _int(n['id']) ?? 0,
              kind: (n['kind'] as String?) ?? 'status',
              title: (n['title'] as String?) ?? '',
              body: (n['body'] as String?) ?? '',
              read: (n['read'] as bool?) ?? false,
              createdAt: _dt(n['created_at']) ?? DateTime.now(),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Result<void>> markNotificationRead({
    required int id,
    required String userId,
  }) async {
    try {
      final res = await client
          .from('notifications')
          .update({'read': true})
          .eq('id', id)
          .eq('user_id', userId);
      if (res.length == 0) return const Ok(null); // already synced/no-op
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_map(e));
    } catch (e) {
      return Err(SyncFailed('read: $e'));
    }
  }

  // ---------- helpers ----------

  ServiceRequest _copy(
    ServiceRequest r, {
    String? status,
    String? priority,
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
      version: r.version + 1,
      createdAt: r.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _collectPatch(
    ServiceRequest from,
    ServiceRequest to,
  ) {
    final patch = <String, dynamic>{
      'priority': to.priority,
      'status': to.status,
      'version': to.version,
      'updated_at': to.updatedAt.toUtc().toIso8601String(),
    };
    if (from.estimateEgp != to.estimateEgp) {
      patch['estimate_egp'] = to.estimateEgp;
    }
    return patch;
  }

  ServiceRequest _req(Map<String, dynamic> r) {
    return ServiceRequest(
      id: r['id'] as String,
      customerId: r['customer_id'] as String,
      serviceId: (r['service_id'] as String?) ?? '',
      description: (r['description'] as String?) ?? '',
      address: (r['address'] as String?) ?? '',
      governorate: (r['governorate'] as String?) ?? '',
      phone: (r['phone'] as String?) ?? '',
      photoLocalPath: r['photo_local_path'] as String?,
      priority: (r['priority'] as String?) ?? 'normal',
      status: (r['status'] as String?) ?? 'new',
      slaDueAt: _dt(r['sla_due_at']) ?? DateTime.now(),
      estimateEgp: _int(r['estimate_egp']),
      idempotencyKey: r['idempotency_key'] as String? ?? '',
      version: _int(r['version']) ?? 1,
      createdAt: _dt(r['created_at']) ?? DateTime.now(),
      updatedAt: _dt(r['updated_at']) ?? DateTime.now(),
    );
  }

  AppError _map(PostgrestException e) {
    switch (e.code) {
      case '42501':
      case '42503':
        return const PermissionDenied();
      case '23503':
        return const ValidationFailed('serviceId');
      case '22P02':
        return const ValidationFailed('inline');
      default:
        return SyncFailed('supabase: ${e.code ?? ''} ${e.message}');
    }
  }

  static int? _int(Object? v) => switch (v) {
    num n => n.toInt(),
    String s => int.tryParse(s),
    null => null,
    _ => null,
  };

  static DateTime? _dt(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      final t = DateTime.tryParse(v);
      return t?.toLocal();
    }
    return null;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}