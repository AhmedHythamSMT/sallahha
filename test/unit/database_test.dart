import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/storage/app_database.dart';
import 'package:sallahha/core/storage/seed_data.dart';

void main() {
  group('drift schema v1 (host-safe: metadata only)', () {
    test('table inventory matches ERD', () {
      // NOTE: the constructor only wires a lazy connection — no I/O happens
      // until the first query, so this runs on hosts without sqlite3.dll.
      // The live open + seed roundtrip runs on CI Linux (see test below).
      final db = AppDatabase.memory();
      expect(
        db.tableInventory,
        containsAll([
          'users',
          'customer_profiles',
          'technician_profiles',
          'services',
          'service_requests',
          'job_assignments',
          'status_history',
          'job_notes',
          'job_photos',
          'parts',
          'job_part_usage',
          'ratings',
          'payments',
          'notifications',
          'audit_events',
          'sync_operations',
        ]),
      );
    });

    test('seed builders produce coherent demo data', () {
      final users = demoUsers();
      final services = demoServices();
      final parts = demoParts();
      final requests = demoRequests(DateTime(2026, 9, 17));
      expect(users.map((u) => u.role.value).toSet(), {
        'customer',
        'technician',
        'supervisor',
        'admin',
      });
      expect(users.length, 5);
      expect(services.length, 4);
      expect(parts.length, 6);
      expect(requests.length, 8);
      // every request points at a seeded customer + service
      final userIds = users.map((u) => u.id.value).toSet();
      final serviceIds = services.map((s) => s.id.value).toSet();
      for (final r in requests) {
        expect(userIds, contains(r.customerId.value));
        expect(serviceIds, contains(r.serviceId.value));
        expect(r.idempotencyKey.value, startsWith('seed-'));
      }
      // statuses spread across the machine
      final statuses = requests.map((r) => r.status.value).toSet();
      expect(
        statuses,
        containsAll(['new', 'assigned', 'in_progress', 'completed']),
      );
    });
  });

  group('live sqlite roundtrip (CI Linux)', () {
    test(
      'open + seed + counts',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        await seedDemoData(db);
        expect(await db.select(db.users).get(), hasLength(5));
        expect(await db.select(db.serviceRequests).get(), hasLength(8));
        // one active tech has repair skill
        final techs = await db.select(db.technicianProfiles).get();
        expect(techs.any((t) => t.skillsCsv.contains('ac-repair')), isTrue);
      },
      skip: Platform.isWindows
          ? 'host lacks sqlite3.dll; runs on CI Linux'
          : false,
    );
  });
}
