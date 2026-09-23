import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Server-side surface the offline-first engine talks to. Implementations:
///   * [MockBackend] behind a sync adapter (demo / keyless dev)
///   * Supabase (PostgREST) when `.env` provides credentials
///
/// Mutations are awaited by the outbox engine; reads are served from the
/// in-memory maps which [refresh] keeps in sync with the server. Maps are
/// intentionally plain so the engine keeps its offline-first mirroring
/// contract (cache local, remote only when online).
abstract interface class RemoteApi {
  Map<String, ServiceRequest> get requests;
  Map<String, AppUser> get users;
  Map<String, ServiceInfo> get services;
  Map<String, AssignmentInfo> get assignments;
  Map<String, List<StatusEvent>> get timelines;
  Map<String, List<JobNote>> get notes;
  Map<String, List<JobPhoto>> get photos;
  Map<String, List<PartUsage>> get partsUsed;
  Map<String, RatingInfo> get ratings;

  /// Pulls the collections above from the server. Must never throw:
  /// a failed fetch keeps the previous state (reads stay local-first).
  Future<void> refresh();

  Future<Result<List<PartInfo>>> partsCatalog();

  Future<Result<ServiceRequest>> createRequest({
    required String customerId,
    required RequestDraft draft,
    required String idempotencyKey,
    required int slaHours,
    String? requestId,
  });

  Future<Result<ServiceRequest>> assign({
    required String byId,
    required String requestId,
    required String technicianId,
  });

  Future<Result<ServiceRequest>> setPriority({
    required String requestId,
    required String priority,
    required int baseVersion,
  });

  Future<Result<ServiceRequest>> transition({
    required String byId,
    required String requestId,
    required String to,
    required int baseVersion,
    String? reason,
  });

  Future<Result<void>> addNote(JobNote note);
  Future<Result<void>> addPhoto(JobPhoto photo);

  Future<Result<void>> addPart({
    required String requestId,
    required String partId,
    required int qty,
  });

  Future<Result<void>> setEstimate({
    required String requestId,
    required int amountEgp,
  });

  Future<Result<void>> confirm({required String requestId});

  Future<Result<void>> rate({
    required String requestId,
    required int stars,
    String? comment,
  });

  // ---------- role-to-role notifications ----------

  /// Fans a notification out to explicit users and/or every profile with
  /// one of [roles]. Roles resolve server-side (profiles table), so the
  /// caller needs no users mirror. Results in one inbox row per recipient.
  Future<Result<void>> pushNotifications({
    required List<String> userIds,
    required List<String> roles,
    required String kind,
    required String title,
    required String body,
  });

  /// Best-effort server inbox for [userId] (never throws — empty on
  /// failure, mirroring the reads-are-local-first contract).
  Future<List<InboxItem>> pullInbox(String userId);

  /// Marks ONE recipient's row read (RLS: only the owning user).
  Future<Result<void>> markNotificationRead({
    required int id,
    required String userId,
  });
}