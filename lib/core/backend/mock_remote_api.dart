import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/backend/remote_api.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// [RemoteApi] adapter over the in-memory [MockBackend]: async surface for
/// the engine, zero network. Used for demo/interview and keyless dev.
class MockRemoteApi implements RemoteApi {
  final MockBackend _b;
  MockRemoteApi([MockBackend? backend]) : _b = backend ?? MockBackend();

  MockBackend get backend => _b;

  @override
  Map<String, AssignmentInfo> get assignments => _b.assignments;
  @override
  Map<String, List<JobNote>> get notes => _b.notes;
  @override
  Map<String, List<JobPhoto>> get photos => _b.photos;
  @override
  Map<String, List<PartUsage>> get partsUsed => _b.partsUsed;
  @override
  Map<String, RatingInfo> get ratings => _b.ratings;
  @override
  Map<String, ServiceRequest> get requests => _b.requests;
  @override
  Map<String, ServiceInfo> get services => _b.services;
  @override
  Map<String, List<StatusEvent>> get timelines => _b.timelines;
  @override
  Map<String, AppUser> get users => _b.users;

  @override
  Future<void> refresh() async {}

  @override
  Future<Result<List<PartInfo>>> partsCatalog() async => Ok(_b.partsCatalog());

  @override
  Future<Result<ServiceRequest>> createRequest({
    required String customerId,
    required RequestDraft draft,
    required String idempotencyKey,
    required int slaHours,
    String? requestId,
  }) =>
      _b.createRequest(
        customerId: customerId,
        draft: draft,
        idempotencyKey: idempotencyKey,
        slaHours: slaHours,
        requestId: requestId,
      );

  @override
  Future<Result<ServiceRequest>> assign({
    required String byId,
    required String requestId,
    required String technicianId,
  }) async =>
      _b.assign(byId: byId, requestId: requestId, technicianId: technicianId);

  @override
  Future<Result<ServiceRequest>> setPriority({
    required String requestId,
    required String priority,
    required int baseVersion,
  }) async => _b.setPriority(
    requestId: requestId,
    priority: priority,
    baseVersion: baseVersion,
  );

  @override
  Future<Result<ServiceRequest>> transition({
    required String byId,
    required String requestId,
    required String to,
    required int baseVersion,
    String? reason,
  }) async =>
      _b.transition(
        byId: byId,
        requestId: requestId,
        to: to,
        baseVersion: baseVersion,
        reason: reason,
      );

  @override
  Future<Result<void>> addNote(JobNote note) async {
    _b.addNote(note);
    return const Ok(null);
  }

  @override
  Future<Result<void>> addPhoto(JobPhoto photo) async {
    _b.addPhoto(photo);
    return const Ok(null);
  }

  @override
  Future<Result<void>> addPart({
    required String requestId,
    required String partId,
    required int qty,
  }) async =>
      _b.addPart(requestId: requestId, partId: partId, qty: qty);

  @override
  Future<Result<void>> setEstimate({
    required String requestId,
    required int amountEgp,
  }) async =>
      _b.setEstimate(requestId: requestId, amountEgp: amountEgp);

  @override
  Future<Result<void>> confirm({required String requestId}) async => _b
      .confirm(requestId: requestId);

  @override
  Future<Result<void>> rate({
    required String requestId,
    required int stars,
    String? comment,
  }) async => _b.rate(requestId: requestId, stars: stars, comment: comment);

  @override
  Future<Result<void>> pushNotifications({
    required List<String> userIds,
    required List<String> roles,
    required String kind,
    required String title,
    required String body,
  }) async => _b.pushNotifications(
    userIds: userIds,
    roles: roles,
    kind: kind,
    title: title,
    body: body,
  );

  @override
  Future<List<InboxItem>> pullInbox(String userId) => _b.inboxFor(userId);

  @override
  Future<Result<void>> markNotificationRead({
    required int id,
    required String userId,
  }) async => _b.markNotificationRead(id: id, userId: userId);
}