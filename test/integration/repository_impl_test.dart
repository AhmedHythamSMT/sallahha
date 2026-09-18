import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/analytics/analytics_service.dart';
import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/storage/app_database.dart' hide ServiceRequest;
import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/core/sync/op_log.dart';
import 'package:sallahha/features/notifications/notification_service.dart';
import 'package:sallahha/features/requests/data/request_repository_impl.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Repository + drift caching. Needs sqlite native lib → CI Linux.
/// Backend-only flow (host-safe) lives in journey_test.dart.
void main() {
  group('RequestRepositoryImpl (CI Linux)', () {
    test(
      'list caches locally; details assembles bundle; dedupe safe',
      () async {
        final backend = MockBackend();
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final notifications = MemoryNotificationService();
        final analytics = MemoryAnalyticsService();
        final repo = RequestRepositoryImpl(
          remote: backend,
          local: LocalRequestStore(db),
          isOnline: () async => true,
          notifications: notifications,
          analytics: analytics,
        );

        final customer = (backend.signIn(
          'customer@demo.test',
          'demo1234',
        ) as Ok<AppUser>).value;
        final tech =
            (backend.signIn('tech@demo.test', 'demo1234') as Ok<AppUser>).value;
        final sup = (backend.signIn(
          'supervisor@demo.test',
          'demo1234',
        ) as Ok<AppUser>).value;

        // customer sees own
        final mine = await repo.listForUser(customer);
        expect((mine as Ok<List<ServiceRequest>>).value, isNotEmpty);

        // create + assign + details bundle
        final created = await repo.create(
          customer,
          const RequestDraft(
            serviceId: 'svc-ac-repair',
            description: 'صوت زنة عالي من الوحدة الخارجية',
            address: '5 شارع جامعة الدول، المهندسين',
            governorate: 'الجيزة',
            phone: '01000000001',
          ),
        );
        final req = (created as Ok<ServiceRequest>).value;

        final assigned = await repo.assign(
          by: sup,
          requestId: req.id,
          technicianId: tech.id,
          idempotencyKey: 'op-assign-1',
        );
        expect((assigned as Ok<ServiceRequest>).value.status, 'assigned');

        // duplicate op key returns current without side effects
        final dup = await repo.assign(
          by: sup,
          requestId: req.id,
          technicianId: tech.id,
          idempotencyKey: 'op-assign-1',
        );
        expect((dup as Ok<ServiceRequest>).value.status, 'assigned');
        expect(backend.timelines[req.id]!.length, 2);

        // technician list + details bundle
        final jobs = await repo.listForUser(tech);
        expect(
          (jobs as Ok<List<ServiceRequest>>).value.map((r) => r.id),
          contains(req.id),
        );
        final details = await repo.details(req.id);
        final bundle = (details as Ok<RequestDetails>).value;
        expect(bundle.assignment?.technicianId, tech.id);
        expect(
          bundle.timeline.map((e) => e.to),
          containsAll(['new', 'assigned']),
        );
        expect(await repo.syncState(req.id), 'synced');

        // service hooks: tech notified, analytics recorded
        final techInbox = await notifications.inbox(tech.id);
        expect(techInbox.any((e) => e.kind == 'assignment'), isTrue);
        expect(
          analytics.events.map((e) => e.name),
          containsAll(['request_created', 'assigned']),
        );
      },
      skip: Platform.isWindows
          ? 'host lacks sqlite3.dll; runs on CI Linux'
          : false,
    );

    test(
      'offline create queues, reconnect flushes, no duplicates',
      () async {
        final backend = MockBackend();
        final db = AppDatabase.memory();
        addTearDown(db.close);
        var online = false;
        final oplog = MemoryOpLog();
        final repo = RequestRepositoryImpl(
          remote: backend,
          local: LocalRequestStore(db),
          oplog: oplog,
          isOnline: () async => online,
        );
        final customer = (backend.signIn(
          'customer@demo.test',
          'demo1234',
        ) as Ok<AppUser>).value;

        // Morning sync while online (catalogs + users cached for offline).
        online = true;
        await repo.services();
        await repo.listForUser(customer);
        online = false;

        // Offline: provisional Ok, nothing on server, op pending.
        final created = await repo.create(
          customer,
          const RequestDraft(
            serviceId: 'svc-ac-repair',
            description: 'الوحدة بتنقط مية على الحيطة',
            address: '8 شارع السودان، المهندسين',
            governorate: 'الجيزة',
            phone: '01000000001',
          ),
        );
        final req = (created as Ok<ServiceRequest>).value;
        expect(req.status, 'new');
        expect(backend.requests.containsKey(req.id), isFalse);
        expect(await repo.syncState(req.id), 'pending');

        // Offline read path serves the provisional entity.
        final mine = await repo.listForUser(customer);
        expect(
          (mine as Ok<List<ServiceRequest>>).value.map((r) => r.id),
          contains(req.id),
        );

        // Reconnect: flush applies once; same client id, no duplicate.
        online = true;
        await repo.flushOutbox();
        expect(backend.requests.containsKey(req.id), isTrue);
        expect(await repo.syncState(req.id), 'synced');

        // Details render the local bundle offline and online alike.
        final details = await repo.details(req.id);
        expect((details as Ok<RequestDetails>).value.request.id, req.id);
      },
      skip: Platform.isWindows
          ? 'host lacks sqlite3.dll; runs on CI Linux'
          : false,
    );
  });
}
