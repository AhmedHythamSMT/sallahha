import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sallahha/core/analytics/analytics_service.dart';
import 'package:sallahha/core/backend/remote_api.dart';
import 'package:sallahha/core/backend/supabase_api.dart';
import 'package:sallahha/core/config/app_config.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/storage/app_database.dart' as drift;
import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/features/auth/data/supabase_auth_repository.dart';
import 'package:sallahha/features/auth/domain/auth_repository.dart';
import 'package:sallahha/features/notifications/notification_service.dart';
import 'package:sallahha/features/payments/payment_service.dart';
import 'package:sallahha/features/requests/data/request_repository_impl.dart';
import 'package:sallahha/features/requests/domain/ai_service.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/features/requests/domain/request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Supabase client (null when not configured).
final supabaseClientProvider = Provider<sb.SupabaseClient?>((ref) {
  if (!AppConfig.usesSupabase) return null;
  try {
    return sb.Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

/// Default locale is Arabic. Persisted across launches.
final localeProvider = StateNotifierProvider<LocaleController, String>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<String> {
  static const key = 'locale';
  LocaleController() : super('ar') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(key) ?? 'ar';
  }

  Future<void> setLocale(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

/// Signed-in user (client-owned; Supabase session in real mode).
final sessionUserProvider = StateProvider<AppUser?>((ref) => null);

/// One-shot session restore at startup from the Supabase client's
/// persisted session (no-op when Supabase isn't configured).
final sessionRestoreProvider = FutureProvider<void>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return;
  final user = await SupabaseAuthRepository(client).restoreSession();
  if (user != null) ref.read(sessionUserProvider.notifier).state = user;
});

/// Active role for guards. Overridable in tests.
final sessionRoleProvider = Provider<String?>(
  (ref) => ref.watch(sessionUserProvider)?.role,
);

/// Connectivity stream → offline banner + sync trigger (Phase 4 consumes).
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Explicit check at startup: the stream may never emit (e.g. airplane
/// mode toggled before launch), leaving the banner blind. Assume online
/// when the check itself is unavailable (tests/desktop), never offline.
final _initialOnlineProvider = FutureProvider<bool>((ref) async {
  try {
    final current = await Connectivity().checkConnectivity();
    return current.any((r) => r != ConnectivityResult.none);
  } catch (_) {
    return true;
  }
});

final isOfflineProvider = Provider<bool>((ref) {
  final streamed = ref.watch(connectivityProvider).valueOrNull;
  if (streamed != null) {
    return streamed.every((r) => r == ConnectivityResult.none);
  }
  final initial = ref.watch(_initialOnlineProvider).valueOrNull;
  if (initial != null) return !initial;
  return false;
});

// --- Backend + repositories (Supabase always; unconfigured = hard error) ---

/// The engine's server surface. Supabase when configured; throws when the
/// app runs without credentials so we never silently fall back to fake data.
final remoteApiProvider = Provider<RemoteApi>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseApi(client);
  throw StateError(
    'Supabase is not configured: set SUPABASE_URL and SUPABASE_ANON_KEY',
  );
});

final databaseProvider = Provider<drift.AppDatabase>((ref) {
  final db = drift.AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final localStoreProvider = Provider<LocalRequestStore>(
  (ref) => LocalRequestStore(ref.watch(databaseProvider)),
);

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepositoryImpl(
    remote: ref.watch(remoteApiProvider),
    local: ref.watch(localStoreProvider),
    notifications: ref.watch(notificationServiceProvider),
    analytics: ref.watch(analyticsProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseAuthRepository(client);
  throw StateError(
    'Supabase is not configured: set SUPABASE_URL and SUPABASE_ANON_KEY',
  );
});

// --- Feature state (Future-based + invalidate on mutation) ---

final servicesProvider = FutureProvider<List<ServiceInfo>>((ref) async {
  final res = await ref.watch(requestRepositoryProvider).services();
  return switch (res) {
    Ok(value: final v) => v,
    Err(error: final e) => throw e,
  };
});

final techniciansProvider = FutureProvider<List<AppUser>>((ref) async {
  final res = await ref.watch(requestRepositoryProvider).technicians();
  return switch (res) {
    Ok(value: final v) => v,
    Err(error: final e) => throw e,
  };
});

final myRequestsProvider = FutureProvider<List<ServiceRequest>>((ref) async {
  final user = ref.watch(sessionUserProvider);
  if (user == null) return [];
  final res = await ref.watch(requestRepositoryProvider).listForUser(user);
  return switch (res) {
    Ok(value: final v) => v,
    Err(error: final e) => throw e,
  };
});

final requestDetailsProvider = FutureProvider.family<RequestDetails, String>((
  ref,
  id,
) async {
  final res = await ref.watch(requestRepositoryProvider).details(id);
  return switch (res) {
    Ok(value: final v) => v,
    Err(error: final e) => throw e,
  };
});

final dispatchQueueProvider =
    FutureProvider.family<List<ServiceRequest>, String>((ref, view) async {
      final res = await ref
          .watch(requestRepositoryProvider)
          .dispatchQueue(view);
      return switch (res) {
        Ok(value: final v) => v,
        Err(error: final e) => throw e,
      };
    });

final workloadProvider = FutureProvider<Map<String, int>>((ref) async {
  final res = await ref.watch(requestRepositoryProvider).technicianWorkload();
  return switch (res) {
    Ok(value: final v) => v,
    Err(error: final e) => throw e,
  };
});

/// Per-entity badge state: synced | pending | failed.
final syncStateProvider = FutureProvider.family<String, String>((
  ref,
  entityId,
) async {
  return ref.watch(requestRepositoryProvider).syncState(entityId);
});

/// One-shot outbox flush at startup; reconnect flushes via _AutoSync.
final startupFlushProvider = FutureProvider<void>((ref) async {
  await ref.watch(requestRepositoryProvider).flushOutbox();
});

// --- Phase 5 services (all keyless; adapters land behind flags) ---

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => DriftNotificationService(ref.watch(localStoreProvider)),
);

final analyticsProvider = Provider<MemoryAnalyticsService>(
  (ref) => MemoryAnalyticsService(),
);

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => MockPaymentGateway(local: ref.watch(localStoreProvider)),
);

final aiServiceProvider = Provider<AIService>(
  (ref) => RuleBasedTriageService(),
);

final inboxProvider = FutureProvider.family<List<InboxItem>, String>((
  ref,
  userId,
) async {
  // Pull the server mirror first (offline → local rows stay), then
  // serve the local Inbox — the read path never blocks on the network.
  await ref.watch(requestRepositoryProvider).refreshInbox(userId);
  return ref.watch(notificationServiceProvider).inbox(userId);
});

/// Unread count for the home nav badge (derived from the inbox mirror).
final unreadInboxProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final items = await ref.watch(inboxProvider(userId).future);
  return items.where((e) => !e.read).length;
});

/// Supabase realtime stream: emits on an INSERT into `notifications` for
/// the current user. Watched by the home screen to invalidate the inbox,
/// so cross-device deliveries refresh without a manual pull. No-ops
/// (empty stream) when Supabase isn't configured (tests/keyless dev).
final notificationRealtimeProvider = StreamProvider.family<void, String>((
  ref,
  userId,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  final channel = client.channel('inbox-$userId');
  final controller = StreamController<void>.broadcast();
  channel
      .onPostgresChanges(
        event: sb.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => controller.add(null),
      )
      .subscribe();
  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });
  return controller.stream;
});

/// Real-time feed for the request domain: any INSERT/UPDATE/DELETE on the
/// service_requests child tables emits a tick so screens invalidate their
/// caches. Low-latency fast path; the home poller keeps screens current
/// even when the websocket is unavailable. No-op when Supabase isn't
/// configured (tests/keyless dev).
final requestRealtimeProvider = StreamProvider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  const tables = [
    'service_requests',
    'job_assignments',
    'status_history',
    'job_notes',
    'job_photos',
    'job_part_usage',
    'service_ratings',
  ];
  final controller = StreamController<void>.broadcast();
  final channel = client.channel('requests');
  for (final table in tables) {
    for (final event in sb.PostgresChangeEvent.values) {
      if (event == sb.PostgresChangeEvent.all) continue;
      channel.onPostgresChanges(
        event: event,
        schema: 'public',
        table: table,
        callback: (_) => controller.add(null),
      );
    }
  }
  channel.subscribe();
  ref.onDispose(() {
    client.removeChannel(channel);
    controller.close();
  });
  return controller.stream;
});

/// Client-generated idempotency key per mutation (UUID-grade enough for MVP).
int _opSeq = 0;
String newOpKey(String userId) =>
    '$userId-${DateTime.now().microsecondsSinceEpoch}-${_opSeq++}';
