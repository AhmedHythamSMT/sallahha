import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/backend/mock_remote_api.dart';
import 'package:sallahha/core/storage/app_database.dart' hide ServiceRequest;
import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/core/sync/op_log.dart';
import 'package:sallahha/features/auth/data/session_store.dart';
import 'package:sallahha/features/requests/data/request_repository_impl.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

void main() {
  group('secure session (memory)', () {
    test('save → restore → clear', () async {
      final store = MemorySessionStore();
      expect(await store.restore(), isNull);
      const user = AppUser(
        id: 'u-1',
        name: 'Test',
        phone: '01001234567',
        role: 'technician',
      );
      await store.save(user);
      expect((await store.restore())?.id, 'u-1');
      await store.clear();
      expect(await store.restore(), isNull);
    });
  });

  group('photo validation', () {
    RequestRepositoryImpl repo() => RequestRepositoryImpl(
      remote: MockRemoteApi(),
      local: LocalRequestStore(AppDatabase.memory()),
      oplog: MemoryOpLog(),
      isOnline: () async => true,
    );

    test('rejects bad extensions, tolerates missing demo files', () {
      final r = repo();
      expect(r.validatePhoto('note.txt'), isNotNull);
      expect(r.validatePhoto('photo.webp'), isNotNull);
      expect(r.validatePhoto('/no/such/photo.jpg'), isNull);
    });

    test('rejects oversized real files', () async {
      final dir = await Directory.systemTemp.createTemp('sallahha');
      addTearDown(() => dir.delete(recursive: true));
      final big = File('${dir.path}/big.jpg');
      await big.writeAsBytes(List.filled(6 * 1024 * 1024, 0));
      expect(repo().validatePhoto(big.path), isNotNull);
      final small = File('${dir.path}/small.png');
      await small.writeAsBytes(List.filled(100, 0));
      expect(repo().validatePhoto(small.path), isNull);
    });
  });
}
