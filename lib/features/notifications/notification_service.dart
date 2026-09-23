import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Who a notification is for: explicit users and/or entire roles.
/// Roles resolve server-side (profiles table); explicit ids are direct.
class NotifyTarget {
  final List<String> userIds;
  final List<String> roles;
  const NotifyTarget({this.userIds = const [], this.roles = const []});

  NotifyTarget.user(String id)
      : userIds = [id],
        roles = const [];

  NotifyTarget.roles(this.roles) : userIds = const [];

  bool get isEmpty => userIds.isEmpty && roles.isEmpty;
}

/// Notification abstraction. Stored strings are Arabic (default locale);
/// kinds are stable codes. Inbox is offline-first: optimistic local rows
/// while offline, replaced by the server mirror on [mergeInbox].
abstract class NotificationService {
  Future<void> notify({
    required String userId,
    required String kind,
    required String title,
    required String body,
  });
  Future<List<InboxItem>> inbox(String userId);
  Future<void> markRead(int id);

  /// Replaces this user's local inbox with the authoritative server rows.
  Future<void> mergeInbox(String userId, List<InboxItem> items);
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

  @override
  Future<void> mergeInbox(String userId, List<InboxItem> items) async {
    _box[userId] = List.of(items);
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

  @override
  Future<void> mergeInbox(String userId, List<InboxItem> items) =>
      local.mergeInbox(userId, items);
}
