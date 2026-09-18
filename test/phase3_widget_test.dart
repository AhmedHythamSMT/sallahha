import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sallahha/app/app.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/routing/router.dart';
import 'package:sallahha/features/notifications/notification_service.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

import 'helpers/fake_repository.dart';

const _customer = AppUser(
  id: 'u-customer-1',
  name: 'Salma Ahmed',
  phone: '01000000001',
  email: 'customer@demo.test',
  role: 'customer',
);

FakeRequestRepository _fake() => FakeRequestRepository(
  serviceList: const [
    ServiceInfo(
      id: 'svc-ac-repair',
      code: 'ac-repair',
      nameAr: 'إصلاح تكييف',
      nameEn: 'AC repair',
      defaultSlaHours: 24,
    ),
  ],
  techList: const [],
  requests: [fakeRequest()],
  detailsMap: {'req-1': fakeDetails(fakeRequest())},
);

ProviderContainer _container(FakeRequestRepository fake, {AppUser? user}) {
  return ProviderContainer(
    overrides: [
      connectivityProvider.overrideWith(
        (ref) => Stream.value([ConnectivityResult.wifi]),
      ),
      requestRepositoryProvider.overrideWith((ref) => fake),
      if (user != null) sessionUserProvider.overrideWith((ref) => user),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('login rejects bad credentials', (tester) async {
    final container = _container(_fake());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'البريد الإلكتروني'),
      'nope@demo.test',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'كلمة المرور'),
      'wrong',
    );
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('بيانات الدخول غير صحيحة'), findsOneWidget);
  });

  testWidgets('demo customer login lands on role home', (tester) async {
    final container = _container(_fake());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();

    await tester.tap(find.text('customer@demo.test'));
    await tester.pumpAndSettle();
    expect(find.text('Salma Ahmed'), findsOneWidget);
    expect(find.text('طلب صيانة جديد'), findsOneWidget);
  });

  testWidgets('new request validates before submitting', (tester) async {
    final fake = _fake();
    final container = _container(fake, user: _customer);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/requests/new');
    await tester.pumpAndSettle();

    await tester.tap(find.text('إرسال الطلب'));
    await tester.pump();
    expect(fake.calls, isEmpty); // domain validation blocked submit
    expect(find.text('إرسال الطلب'), findsOneWidget);
  });

  testWidgets('requests list renders cached items', (tester) async {
    final container = _container(_fake(), user: _customer);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/requests');
    await tester.pumpAndSettle();
    expect(find.textContaining('ما بيبردش'), findsOneWidget);
  });

  testWidgets('full chain backs out section by section', (tester) async {
    final container = _container(_fake(), user: _customer);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Home -> Requests (section push) -> details (drill push).
    await tester.tap(find.text('الطلبات').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ما بيبردش'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    // System back pops details -> list, then list -> home.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('ما بيبردش'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Salma Ahmed'), findsOneWidget);
  });

  testWidgets('details shows live sync badge', (tester) async {
    final container = _container(_fake(), user: _customer);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).push('/requests/req-1');
    await tester.pumpAndSettle();
    expect(find.text('تمت المزامنة'), findsOneWidget);
  });

  testWidgets('inbox renders notifications and marks read', (tester) async {
    final inbox = MemoryNotificationService();
    await inbox.notify(
      userId: 'u-tech-1',
      kind: 'assignment',
      title: 'طلب جديد مُسند',
      body: '#req-1',
    );
    const tech = AppUser(
      id: 'u-tech-1',
      name: 'Hassan Ali',
      phone: '01000000002',
      email: 'tech@demo.test',
      role: 'technician',
    );
    final container = ProviderContainer(
      overrides: [
        connectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
        requestRepositoryProvider.overrideWith((ref) => _fake()),
        sessionUserProvider.overrideWith((ref) => tech),
        notificationServiceProvider.overrideWith((ref) => inbox),
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
    container.read(routerProvider).push('/notifications');
    await tester.pumpAndSettle();
    expect(find.text('طلب جديد مُسند'), findsOneWidget);
    await tester.tap(find.text('طلب جديد مُسند'));
    await tester.pumpAndSettle();
    expect((await inbox.inbox('u-tech-1')).single.read, isTrue);
  });

  testWidgets('nav cards expose semantics labels', (tester) async {
    final handle = tester.ensureSemantics();
    final container = _container(_fake(), user: _customer);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SallahhaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الطلبات'), findsOneWidget);
    expect(find.bySemanticsLabel('التنبيهات'), findsOneWidget);
    handle.dispose();
  });
}
