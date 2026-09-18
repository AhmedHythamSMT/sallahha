import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Notification abstraction. Mock/drift now; FCM adapter later behind a
/// flag (the app must boot with zero keys — see cost-audit).
/// Stored strings are Arabic (default locale); kinds are stable codes.
abstract class NotificationService {
  Future<void> notify({
    required String userId,
    required String kind,
    required String title,
    required String body,
  });
  Future<List<InboxItem>> inbox(String userId);
  Future<void> markRead(int id);
}

class MemoryNotificationService implements NotificationService {
  int _seq = 1;
  final Map<String, List<InboxItem>> _box = {};

  @override
  Future<void> notify({
    required String userId,
    required String kind,
    required String title,
    required String body,
  }) async {
    final list = _box.putIfAbsent(userId, () => []);
    list.add(
      InboxItem(
        id: _seq++,
        kind: kind,
        title: title,
        body: body,
        read: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<InboxItem>> inbox(String userId) async =>
      List.of(_box[userId] ?? const []);

  @override
  Future<void> markRead(int id) async {
    for (final list in _box.values) {
      final i = list.indexWhere((e) => e.id == id);
      if (i >= 0) {
        list[i] = InboxItem(
          id: list[i].id,
          kind: list[i].kind,
          title: list[i].title,
          body: list[i].body,
          read: true,
          createdAt: list[i].createdAt,
        );
      }
    }
  }
}

class DriftNotificationService implements NotificationService {
  final LocalRequestStore local;
  DriftNotificationService(this.local);

  @override
  Future<void> notify({
    required String userId,
    required String kind,
    required String title,
    required String body,
  }) => local.addNotification(
    userId: userId,
    kind: kind,
    title: title,
    body: body,
  );

  @override
  Future<List<InboxItem>> inbox(String userId) =>
      local.notificationsFor(userId);

  @override
  Future<void> markRead(int id) => local.markNotificationRead(id);
}
