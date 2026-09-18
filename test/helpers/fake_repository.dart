import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/features/requests/domain/request_repository.dart';

/// Canned repository for widget tests: rendering, validation,
/// navigation — never business rules (covered in unit/integration).
class FakeRequestRepository implements RequestRepository {
  final List<ServiceInfo> serviceList;
  final List<AppUser> techList;
  final List<ServiceRequest> requests;
  final Map<String, RequestDetails> detailsMap;
  final List<String> calls = [];

  FakeRequestRepository({
    required this.serviceList,
    required this.techList,
    required this.requests,
    required this.detailsMap,
  });

  @override
  Future<Result<List<ServiceRequest>>> listForUser(AppUser user) async =>
      Ok(requests);

  @override
  Future<Result<List<ServiceRequest>>> dispatchQueue(String view) async =>
      Ok(requests);

  @override
  Future<Result<Map<String, int>>> technicianWorkload() async => const Ok({});

  @override
  Future<Result<ServiceRequest>> create(AppUser user, RequestDraft d) async {
    calls.add('create');
    return Ok(requests.first);
  }

  @override
  Future<Result<RequestDetails>> details(String id) async {
    final d = detailsMap[id];
    if (d == null) return const Err(NotFound());
    return Ok(d);
  }

  @override
  Future<Result<ServiceRequest>> assign({
    required AppUser by,
    required String requestId,
    required String technicianId,
    required String idempotencyKey,
  }) async {
    calls.add('assign');
    return Ok(requests.first);
  }

  @override
  Future<Result<ServiceRequest>> setPriority({
    required AppUser by,
    required String requestId,
    required String priority,
    required int baseVersion,
    required String idempotencyKey,
  }) async => Ok(requests.first);

  @override
  Future<Result<ServiceRequest>> transition({
    required AppUser by,
    required String requestId,
    required String to,
    required int baseVersion,
    required String idempotencyKey,
    String? reason,
  }) async => Ok(requests.first);

  @override
  Future<Result<void>> addNote({
    required AppUser by,
    required String requestId,
    required String kind,
    required String body,
    required String idempotencyKey,
  }) async {
    calls.add('note:$body');
    return const Ok(null);
  }

  @override
  Future<Result<void>> addPhoto({
    required AppUser by,
    required String requestId,
    required String kind,
    required String localPath,
    required String idempotencyKey,
  }) async => const Ok(null);

  @override
  Future<Result<void>> addPart({
    required AppUser by,
    required String requestId,
    required String partId,
    required int qty,
    required String idempotencyKey,
  }) async => const Ok(null);

  @override
  Future<Result<void>> setEstimate({
    required AppUser by,
    required String requestId,
    required int amountEgp,
    required String idempotencyKey,
  }) async => const Ok(null);

  @override
  Future<Result<void>> confirm({
    required AppUser by,
    required String requestId,
    required String idempotencyKey,
  }) async {
    calls.add('confirm');
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
    calls.add('rate:$stars');
    return const Ok(null);
  }

  @override
  Future<Result<List<ServiceInfo>>> services() async => Ok(serviceList);

  @override
  Future<Result<List<AppUser>>> technicians() async => Ok(techList);

  @override
  Future<void> flushOutbox() async {}

  @override
  Future<String> syncState(String entityId) async => 'synced';

  @override
  Future<void> retryEntity(String entityId) async {}
}

ServiceRequest fakeRequest({String id = 'req-1', String status = 'new'}) {
  final now = DateTime(2026, 9, 17, 10);
  return ServiceRequest(
    id: id,
    customerId: 'u-customer-1',
    serviceId: 'svc-ac-repair',
    description: 'التكييف ما بيبردش',
    address: '12 شارع مصدق، الدقي',
    governorate: 'الجيزة',
    phone: '01000000001',
    priority: 'normal',
    status: status,
    slaDueAt: now.add(const Duration(hours: 24)),
    idempotencyKey: 'fake-$id',
    version: 1,
    createdAt: now,
    updatedAt: now,
  );
}

RequestDetails fakeDetails(ServiceRequest r) => RequestDetails(
  request: r,
  timeline: [
    StatusEvent(
      requestId: r.id,
      from: '-',
      to: r.status,
      byUserId: r.customerId,
      createdAt: r.createdAt,
    ),
  ],
  notes: const [],
  photos: const [],
  parts: const [],
);
