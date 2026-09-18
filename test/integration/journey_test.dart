import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/features/requests/domain/rules.dart';

/// Full MVP spine against the mock backend (no SQLite → runs on any host).
/// Repository + drift caching is covered in repository_impl_test (CI Linux).
void main() {
  late MockBackend backend;

  setUp(() {
    backend = MockBackend();
  });

  test('end-to-end: create → assign → work → confirm → rate', () async {
    // 1. customer creates
    final created = await backend.createRequest(
      customerId: 'u-customer-1',
      draft: const RequestDraft(
        serviceId: 'svc-ac-repair',
        description: 'التكييف ما بيبردش وطالع هواء دافئ',
        address: '12 شارع مصدق، الدقي',
        governorate: 'الجيزة',
        phone: '01000000001',
      ),
      idempotencyKey: 'e2e-key-1',
      slaHours: 24,
    );
    expect(created, isA<Ok<ServiceRequest>>());
    final req = (created as Ok<ServiceRequest>).value;
    expect(req.status, 'new');

    // 2. idempotent retry returns same request, no duplicate
    final retry = await backend.createRequest(
      customerId: 'u-customer-1',
      draft: const RequestDraft(
        serviceId: 'svc-ac-repair',
        description: 'different text same key',
        address: 'x',
        governorate: 'y',
        phone: '01000000001',
      ),
      idempotencyKey: 'e2e-key-1',
      slaHours: 24,
    );
    expect((retry as Ok<ServiceRequest>).value.id, req.id);

    // 3. supervisor assigns (happy path)
    final assigned = backend.assign(
      byId: 'u-supervisor-1',
      requestId: req.id,
      technicianId: 'u-tech-1',
    );
    expect((assigned as Ok<ServiceRequest>).value.status, 'assigned');

    // 4. illegal skip rejected with typed error
    final illegal = backend.transition(
      byId: 'u-tech-1',
      requestId: req.id,
      to: 'completed',
      baseVersion: 2,
    );
    expect(illegal, isA<Err<ServiceRequest>>());
    final err = (illegal as Err<ServiceRequest>).error;
    expect(err, isA<IllegalTransition>());

    // 5. legal chain to completion
    var version = 2;
    for (final next in [
      'accepted',
      'on_the_way',
      'arrived',
      'in_progress',
      'waiting_for_parts',
      'in_progress',
      'completed',
    ]) {
      final r = backend.transition(
        byId: 'u-tech-1',
        requestId: req.id,
        to: next,
        baseVersion: version,
      );
      expect(r, isA<Ok<ServiceRequest>>(), reason: 'step $next');
      version = (r as Ok<ServiceRequest>).value.version;
    }

    // 6. stale version rejected (conflict policy: server wins)
    final stale = backend.transition(
      byId: 'u-tech-1',
      requestId: req.id,
      to: 'cancelled',
      baseVersion: 2,
    );
    expect((stale as Err<ServiceRequest>).error, isA<SyncFailed>());

    // 7. proof bundle
    backend.addNote(
      JobNote(
        requestId: req.id,
        authorId: 'u-tech-1',
        kind: 'diagnosis',
        body: 'ضعف فريون + تنظيف فلاتر',
        createdAt: DateTime.now(),
      ),
    );
    expect(
      backend.addPart(requestId: req.id, partId: 'part-freon', qty: 1),
      isA<Ok<void>>(),
    );
    expect(
      backend.setEstimate(requestId: req.id, amountEgp: 450),
      isA<Ok<void>>(),
    );

    // 8. confirm requires completed (this one is) → rate once
    expect(backend.confirm(requestId: req.id), isA<Ok<void>>());
    expect(
      backend.rate(requestId: req.id, stars: 5, comment: 'ممتاز'),
      isA<Ok<void>>(),
    );
    final doubleRate = backend.rate(requestId: req.id, stars: 4);
    expect((doubleRate as Err<void>).error, isA<ValidationFailed>());
  });

  test('auth + permission paths', () {
    // wrong password
    expect(backend.signIn('customer@demo.test', 'nope'), isA<Err<AppUser>>());
    // unknown user
    expect(backend.signIn('ghost@demo.test', 'demo1234'), isA<Err<AppUser>>());
    // ok
    final ok = backend.signIn('tech@demo.test', 'demo1234');
    expect((ok as Ok<AppUser>).value.role, 'technician');
  });

  test('confirm before completion is rejected', () {
    expect(backend.confirm(requestId: 'req-new-1'), isA<Err<void>>());
  });

  test('overdue queue derivation', () {
    final now = DateTime.now();
    // completed seeds with past dues are never overdue
    final donePast = backend.requests.values.where(
      (r) => r.status == 'completed' && r.slaDueAt.isBefore(now),
    );
    expect(donePast, isNotEmpty);
    expect(
      donePast.every((r) => !isOverdue(r.slaDueAt, r.status, now)),
      isTrue,
    );
    // an open request past its SLA is overdue
    final open = backend.requests['req-new-1']!;
    backend.requests['req-late'] = ServiceRequest(
      id: 'req-late',
      customerId: open.customerId,
      serviceId: open.serviceId,
      description: open.description,
      address: open.address,
      governorate: open.governorate,
      phone: open.phone,
      priority: 'high',
      status: 'assigned',
      slaDueAt: now.subtract(const Duration(hours: 1)),
      idempotencyKey: 'late-1',
      version: 1,
      createdAt: now.subtract(const Duration(hours: 9)),
      updatedAt: now,
    );
    final overdue = backend.requests.values
        .where((r) => isOverdue(r.slaDueAt, r.status, now))
        .toList();
    expect(overdue.map((r) => r.id), contains('req-late'));
  });
}
