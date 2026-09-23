import 'package:drift/drift.dart';
import 'package:sallahha/core/storage/app_database.dart' as drift;
import 'package:sallahha/core/storage/mappers.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Local cache over Drift. Source of truth for reads; repository
/// refreshes it from the backend and records every mutation as a
/// SyncOperation (Phase 4 engine flushes pending ones).
class LocalRequestStore {
  final drift.AppDatabase db;
  LocalRequestStore(this.db);

  Future<void> upsertRequests(List<ServiceRequest> items) async {
    await db.batch((b) {
      for (final e in items) {
        b.insert(
          db.serviceRequests,
          requestToCompanion(e),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> upsertUsers(List<AppUser> users) async {
    await db.batch((b) {
      for (final u in users) {
        b.insert(
          db.users,
          drift.UsersCompanion(
            id: Value(u.id),
            name: Value(u.name),
            phone: Value(u.phone),
            email: Value(u.email),
            role: Value(u.role),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ServiceRequest>> requestsForCustomer(String customerId) {
    return (db.select(db.serviceRequests)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get()
        .then((rows) => rows.map(requestFromRow).toList());
  }

  Future<List<ServiceRequest>> requestsForTechnician(String techId) async {
    final asgs =
        await (db.select(db.jobAssignments)..where(
              (t) => t.technicianId.equals(techId) & t.active.equals(true),
            ))
            .get();
    final ids = asgs.map((a) => a.requestId).toSet();
    if (ids.isEmpty) return [];
    final rows = await (db.select(
      db.serviceRequests,
    )..where((t) => t.id.isIn(ids))).get();
    return rows.map(requestFromRow).toList();
  }

  Future<List<ServiceRequest>> allRequests() {
    return db
        .select(db.serviceRequests)
        .get()
        .then((rows) => rows.map(requestFromRow).toList());
  }

  Future<ServiceRequest?> requestById(String id) async {
    final row = await (db.select(
      db.serviceRequests,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : requestFromRow(row);
  }

  Future<void> recordTimeline(StatusEvent e) {
    return db
        .into(db.statusHistory)
        .insert(
          drift.StatusHistoryCompanion(
            requestId: Value(e.requestId),
            from: Value(e.from),
            to: Value(e.to),
            byUserId: Value(e.byUserId),
            reason: Value(e.reason),
            createdAt: Value(e.createdAt),
          ),
        );
  }

  Future<List<StatusEvent>> timeline(String requestId) async {
    final rows =
        await (db.select(db.statusHistory)
              ..where((t) => t.requestId.equals(requestId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(eventFromRow).toList();
  }

  Future<void> addNote(JobNote n) {
    return db
        .into(db.jobNotes)
        .insert(
          drift.JobNotesCompanion(
            requestId: Value(n.requestId),
            authorId: Value(n.authorId),
            kind: Value(n.kind),
            body: Value(n.body),
            createdAt: Value(n.createdAt),
          ),
        );
  }

  Future<List<JobNote>> notes(String requestId) async {
    final rows = await (db.select(
      db.jobNotes,
    )..where((t) => t.requestId.equals(requestId))).get();
    return rows.map(noteFromRow).toList();
  }

  Future<void> addPhoto(JobPhoto p) {
    return db
        .into(db.jobPhotos)
        .insert(
          drift.JobPhotosCompanion(
            requestId: Value(p.requestId),
            kind: Value(p.kind),
            localPath: Value(p.localPath),
          ),
        );
  }

  Future<List<JobPhoto>> photos(String requestId) async {
    final rows = await (db.select(
      db.jobPhotos,
    )..where((t) => t.requestId.equals(requestId))).get();
    return rows.map(photoFromRow).toList();
  }

  Future<void> upsertAssignment(AssignmentInfo a) {
    return db
        .into(db.jobAssignments)
        .insert(
          drift.JobAssignmentsCompanion(
            id: Value(a.id),
            requestId: Value(a.requestId),
            technicianId: Value(a.technicianId),
            assignedBy: Value(a.assignedBy),
            active: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<AssignmentInfo?> assignment(String requestId) async {
    final row =
        await (db.select(db.jobAssignments)..where(
              (t) => t.requestId.equals(requestId) & t.active.equals(true),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    final tech = await (db.select(
      db.users,
    )..where((t) => t.id.equals(row.technicianId))).getSingleOrNull();
    return AssignmentInfo(
      id: row.id,
      requestId: row.requestId,
      technicianId: row.technicianId,
      technicianName: tech?.name ?? row.technicianId,
      assignedBy: row.assignedBy,
    );
  }

  Future<void> recordSyncOp({
    required String opId,
    required String entityType,
    required String entityId,
    required String opType,
    required String status,
  }) {
    return db
        .into(db.syncOperations)
        .insert(
          drift.SyncOperationsCompanion(
            opId: Value(opId),
            entityType: Value(entityType),
            entityId: Value(entityId),
            opType: Value(opType),
            payloadJson: const Value('{}'),
            status: Value(status),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  // --- Catalog caches (offline parts/services entry) ---

  Future<void> upsertServices(List<ServiceInfo> items) async {
    await db.batch((b) {
      for (final s in items) {
        b.insert(
          db.services,
          serviceToCompanion(s),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ServiceInfo>> cachedServices() {
    return db
        .select(db.services)
        .get()
        .then((rows) => rows.map(serviceFromRow).toList());
  }

  Future<void> upsertParts(List<PartInfo> items) async {
    await db.batch((b) {
      for (final p in items) {
        b.insert(
          db.parts,
          partToCompanion(p),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<PartInfo>> cachedParts() {
    return db
        .select(db.parts)
        .get()
        .then((rows) => rows.map(partFromRow).toList());
  }

  Future<PartInfo?> partById(String id) async {
    final row = await (db.select(
      db.parts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : partFromRow(row);
  }

  // --- Job proof bundle (local-first details) ---

  Future<void> addPartUsage(String requestId, PartUsage u) {
    return db.into(db.jobPartUsage).insert(partUsageToCompanion(requestId, u));
  }

  Future<List<PartUsage>> partUsages(String requestId) async {
    final rows = await (db.select(
      db.jobPartUsage,
    )..where((t) => t.requestId.equals(requestId))).get();
    final out = <PartUsage>[];
    for (final r in rows) {
      final catalog = await partById(r.partId);
      out.add(
        PartUsage(
          partId: r.partId,
          partName: catalog?.nameEn ?? r.partId,
          priceEgp: catalog?.priceEgp ?? 0,
          qty: r.qty,
        ),
      );
    }
    return out;
  }

  Future<void> upsertRating(RatingInfo r) {
    return db
        .into(db.ratings)
        .insert(ratingToCompanion(r), mode: InsertMode.insertOrReplace);
  }

  Future<RatingInfo?> rating(String requestId) async {
    final row = await (db.select(
      db.ratings,
    )..where((t) => t.requestId.equals(requestId))).getSingleOrNull();
    return row == null ? null : ratingFromRow(row);
  }

  Future<List<AppUser>> allUsers() {
    return db
        .select(db.users)
        .get()
        .then((rows) => rows.map(userFromRow).toList());
  }

  Future<AppUser?> userById(String id) async {
    final row = await (db.select(
      db.users,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : userFromRow(row);
  }

  /// Local detail bundle. Remote refresh (when online) happens in the
  /// repository; screens always render this — offline included.
  Future<RequestDetails?> localDetails(
    String id, {
    required Future<bool> Function() confirmedFromOutbox,
  }) async {
    final req = await requestById(id);
    if (req == null) return null;
    return RequestDetails(
      request: req,
      timeline: await timeline(id),
      notes: await notes(id),
      photos: await photos(id),
      parts: await partUsages(id),
      assignment: await assignment(id),
      rating: await rating(id),
      confirmed: await confirmedFromOutbox(),
    );
  }

  // --- Notifications inbox (drift-backed) ---

  Future<void> addNotification({
    required String userId,
    required String kind,
    required String title,
    required String body,
  }) {
    return db
        .into(db.notifications)
        .insert(
          drift.NotificationsCompanion(
            userId: Value(userId),
            kind: Value(kind),
            title: Value(title),
            body: Value(body),
          ),
        );
  }

  Future<List<InboxItem>> notificationsFor(String userId) async {
    final rows =
        await (db.select(db.notifications)
              ..where((t) => t.userId.equals(userId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return rows
        .map(
          (r) => InboxItem(
            id: r.id,
            kind: r.kind,
            title: r.title,
            body: r.body,
            read: r.readAt != null,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  Future<void> markNotificationRead(int id) {
    return (db.update(db.notifications)..where((t) => t.id.equals(id))).write(
      drift.NotificationsCompanion(readAt: Value(DateTime.now())),
    );
  }

  /// Server-truth mirror: replaces this user's row cache with [items].
  /// Local ids become the SERVER ids, so mark-read syncs by the same id
  /// and realtime-triggered pulls converge without duplicates.
  Future<void> mergeInbox(String userId, List<InboxItem> items) async {
    await db.transaction(() async {
      await (db.delete(db.notifications)..where((t) => t.userId.equals(userId)))
          .go();
      for (final item in items) {
        await db.into(db.notifications).insert(
          drift.NotificationsCompanion(
            id: Value(item.id),
            userId: Value(userId),
            kind: Value(item.kind),
            title: Value(item.title),
            body: Value(item.body),
            readAt: item.read ? Value(DateTime.now()) : const Value(null),
            createdAt: Value(item.createdAt),
          ),
        );
      }
    });
  }

  // --- Payments (mock gateway records) ---

  Future<void> recordPayment({
    required String id,
    required String requestId,
    required int amountEgp,
    required String state,
    String? gatewayRef,
  }) {
    return db
        .into(db.payments)
        .insert(
          drift.PaymentsCompanion(
            id: Value(id),
            requestId: Value(requestId),
            amountEgp: Value(amountEgp),
            state: Value(state),
            gatewayRef: Value(gatewayRef),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<PaymentRecord>> paymentsFor(String requestId) async {
    final rows =
        await (db.select(db.payments)
              ..where((t) => t.requestId.equals(requestId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return rows
        .map(
          (r) => PaymentRecord(
            id: r.id,
            amountEgp: r.amountEgp,
            state: r.state,
            gatewayRef: r.gatewayRef,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }
}
