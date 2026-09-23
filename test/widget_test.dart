import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sallahha/app/app.dart';
import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/routing/router.dart';
import 'package:sallahha/features/auth/data/mock_auth_repository.dart';

import 'helpers/fake_repository.dart';

FakeRequestRepository _fakeRepo() => FakeRequestRepository(
  serviceList: const [],
  techList: const [],
  requests: [fakeRequest()],
  detailsMap: {'req-1': fakeDetails(fakeRequest())},
);

/// Widget tests run against in-memory doubles; the production providers
/// throw when Supabase is unconfigured, so override the backend surface.
List<Override> _backendOverrides() => [
  connectivityProvider.overrideWith(
    (ref) => Stream.value([ConnectivityResult.wifi]),
  ),
  requestRepositoryProvider.overrideWith((ref) => _fakeRepo()),
  authRepositoryProvider.overrideWith(
    (ref) => MockAuthRepository(MockBackend()),
  ),
];

ProviderScope testScope({String? role, List<Override> extra = const []}) {
  return ProviderScope(
    overrides: [
      ..._backendOverrides(),
      if (role != null) sessionRoleProvider.overrideWith((ref) => role),
      ...extra,
    ],
    child: const SallahhaApp(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .implicitView!;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('signed-out home shows Arabic title + sign-in', (tester) async {
    await tester.pumpWidget(testScope());
    await tester.pumpAndSettle();
    expect(find.textContaining('صلّحها'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });

  testWidgets('locale toggle switches to English', (tester) async {
    await tester.pumpWidget(testScope());
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sallahha'), findsOneWidget);
  });

  testWidgets('customer sees requests card, not dispatch', (tester) async {
    await tester.pumpWidget(testScope(role: 'customer'));
    await tester.pumpAndSettle();
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('التوزيع'), findsNothing);
  });

  testWidgets('supervisor sees dispatch + reports', (tester) async {
    await tester.pumpWidget(testScope(role: 'supervisor'));
    await tester.pumpAndSettle();
    expect(find.text('التوزيع'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
  });

  testWidgets('customer opening /dispatch lands on unauthorized', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        ..._backendOverrides(),
        sessionRoleProvider.overrideWith((ref) => 'customer'),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/dispatch');
    await tester.pumpAndSettle();
    expect(find.text('غير مصرح'), findsOneWidget);
  });

  testWidgets('offline banner appears when connectivity is none', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.none]),
          ),
          requestRepositoryProvider.overrideWith((ref) => _fakeRepo()),
          authRepositoryProvider.overrideWith(
            (ref) => MockAuthRepository(MockBackend()),
          ),
        ],
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('لا يوجد اتصال — التغييرات محفوظة وستُزامَن'),
      findsOneWidget,
    );
  });

  testWidgets('signed-out deep link to /jobs redirects to login', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: _backendOverrides(),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/jobs/req-1');
    await tester.pumpAndSettle();
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
