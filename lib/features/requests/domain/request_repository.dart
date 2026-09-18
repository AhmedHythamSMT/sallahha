import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Repository contract. Implementations hide local/remote details.
/// Every mutation is idempotent on [idempotencyKey]/op id.
abstract class RequestRepository {
  Future<Result<List<ServiceRequest>>> listForUser(AppUser user);
  Future<Result<List<ServiceRequest>>> dispatchQueue(String view);
  Future<Result<Map<String, int>>> technicianWorkload();
  Future<Result<ServiceRequest>> create(AppUser user, RequestDraft draft);
  Future<Result<RequestDetails>> details(String id);
  Future<Result<ServiceRequest>> assign({
    required AppUser by,
    required String requestId,
    required String technicianId,
    required String idempotencyKey,
  });
  Future<Result<ServiceRequest>> setPriority({
    required AppUser by,
    required String requestId,
    required String priority,
    required int baseVersion,
    required String idempotencyKey,
  });
  Future<Result<ServiceRequest>> transition({
    required AppUser by,
    required String requestId,
    required String to,
    required int baseVersion,
    required String idempotencyKey,
    String? reason,
  });
  Future<Result<void>> addNote({
    required AppUser by,
    required String requestId,
    required String kind,
    required String body,
    required String idempotencyKey,
  });
  Future<Result<void>> addPhoto({
    required AppUser by,
    required String requestId,
    required String kind,
    required String localPath,
    required String idempotencyKey,
  });
  Future<Result<void>> addPart({
    required AppUser by,
    required String requestId,
    required String partId,
    required int qty,
    required String idempotencyKey,
  });
  Future<Result<void>> setEstimate({
    required AppUser by,
    required String requestId,
    required int amountEgp,
    required String idempotencyKey,
  });
  Future<Result<void>> confirm({
    required AppUser by,
    required String requestId,
    required String idempotencyKey,
  });
  Future<Result<void>> rate({
    required AppUser by,
    required String requestId,
    required int stars,
    required String idempotencyKey,
    String? comment,
  });
  Future<Result<List<ServiceInfo>>> services();
  Future<Result<List<AppUser>>> technicians();

  // --- sync UX (Phase 4) ---
  Future<void> flushOutbox();
  Future<String> syncState(String entityId); // synced|pending|failed
  Future<void> retryEntity(String entityId);
}
