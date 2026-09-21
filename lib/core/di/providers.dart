import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sallahha/core/analytics/analytics_service.dart';
import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/storage/app_database.dart' as drift;
import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/core/storage/seed_data.dart';
import 'package:sallahha/features/auth/data/mock_auth_repository.dart';
import 'package:sallahha/features/auth/data/session_store.dart';
import 'package:sallahha/features/auth/domain/auth_repository.dart';
import 'package:sallahha/features/notifications/notification_service.dart';
import 'package:sallahha/features/payments/payment_service.dart';
import 'package:sallahha/features/requests/data/request_repository_impl.dart';
import 'package:sallahha/features/requests/domain/ai_service.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/features/requests/domain/request_repository.dart';

/// Feature flags (debug only). Change to false for clean real-data runs.
const bool kSeedDemoData = false ;
const bool kEnableDebugDbViewer = true;

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

/// Signed-in user (mock session; Supabase session in Phase 5).
final sessionUserProvider = StateProvider<AppUser?>((ref) => null);

/// Secure session persistence (memory in tests via override).
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

/// One-shot session restore at startup.
final sessionRestoreProvider = FutureProvider<void>((ref) async {
  final user = await ref.watch(sessionStoreProvider).restore();
  if (user != null) ref.read(sessionUserProvider.notifier).state = user;
});

/// Active role for guards. Overridable in tests.
final sessionRoleProvider = Provider<String?>(
  (ref) => ref.watch(sessionUserProvider)?.role,
);

/// Connectivity stream → offline banner + sync trigger (Phase 4 consumes).
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
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

// --- Backend + repositories (mock remote default; Supabase swaps here) ---

final backendProvider = Provider<MockBackend>((ref) => MockBackend());

final databaseProvider = Provider<drift.AppDatabase>((ref) {
  final db = drift.AppDatabase();
  ref.onDispose(() => db.close());
  if (kSeedDemoData) {
    // Fire-and-forget: seeds only on first run (idempotent via unique constraints)
    seedDemoData(db).catchError((_) {});
  }
  return db;
});

final localStoreProvider = Provider<LocalRequestStore>(
  (ref) => LocalRequestStore(ref.watch(databaseProvider)),
);

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepositoryImpl(
    remote: ref.watch(backendProvider),
    local: ref.watch(localStoreProvider),
    notifications: ref.watch(notificationServiceProvider),
    analytics: ref.watch(analyticsProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(backendProvider)),
);

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
final syncStateProvider =
    FutureProvider.family<String, String>((ref, entityId) async {
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

final inboxProvider = FutureProvider.family<List<InboxItem>, String>((ref, userId) async {
  return ref.watch(notificationServiceProvider).inbox(userId);
});

/// Client-generated idempotency key per mutation (UUID-grade enough for MVP).
int _opSeq = 0;
String newOpKey(String userId) =>
    '$userId-${DateTime.now().microsecondsSinceEpoch}-${_opSeq++}';