import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/app/home_page.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/routing/unauthorized_page.dart';
import 'package:sallahha/features/auth/presentation/login_page.dart';
import 'package:sallahha/features/debug/presentation/debug_database_page.dart';
import 'package:sallahha/features/dispatch/presentation/dispatch_page.dart';
import 'package:sallahha/features/jobs/presentation/job_details_page.dart';
import 'package:sallahha/features/jobs/presentation/jobs_page.dart';
import 'package:sallahha/features/notifications/presentation/inbox_page.dart';
import 'package:sallahha/features/profile/presentation/profile_page.dart';
import 'package:sallahha/features/reports/presentation/reports_page.dart';
import 'package:sallahha/features/requests/presentation/new_request_page.dart';
import 'package:sallahha/features/requests/presentation/request_details_page.dart';
import 'package:sallahha/features/requests/presentation/requests_page.dart';
import 'package:sallahha/shared/animations/app_animations.dart';

/// Full MVP route map with role guards (UI-level; server enforces).
/// Rebuilt when the mock session role changes — cheap for MVP scale.
final routerProvider = Provider<GoRouter>((ref) {
  final role = ref.watch(sessionRoleProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/login') {
        return role == null ? null : '/';
      }
      if (loc == '/unauthorized' || loc == '/') return null;
      if (role == null) return '/login';
      if ((loc.startsWith('/dispatch') || loc.startsWith('/reports')) &&
          role != 'supervisor' &&
          role != 'admin') {
        return '/unauthorized';
      }
      if (loc.startsWith('/jobs') &&
          role != 'technician' &&
          role != 'supervisor' &&
          role != 'admin') {
        return '/unauthorized';
      }
      return null;
    },
    routes: _routes(),
  );
});

List<RouteBase> _routes() => [
  GoRoute(
    path: '/',
    pageBuilder: (context, state) => _slidePage(const HomePage()),
  ),
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) => _slidePage(const LoginPage()),
  ),
  GoRoute(
    path: '/unauthorized',
    pageBuilder: (context, state) => _slidePage(const UnauthorizedPage()),
  ),
  GoRoute(
    path: '/requests',
    pageBuilder: (context, state) => _slidePage(const RequestsPage()),
  ),
  GoRoute(
    path: '/requests/new',
    pageBuilder: (context, state) => _slidePage(const NewRequestPage()),
  ),
  GoRoute(
    path: '/requests/:id',
    pageBuilder: (context, state) =>
        _slidePage(RequestDetailsPage(id: state.pathParameters['id']!)),
  ),
  GoRoute(
    path: '/jobs',
    pageBuilder: (context, state) => _slidePage(const JobsPage()),
  ),
  GoRoute(
    path: '/jobs/:id',
    pageBuilder: (context, state) =>
        _slidePage(JobDetailsPage(id: state.pathParameters['id']!)),
  ),
  GoRoute(
    path: '/dispatch',
    pageBuilder: (context, state) => _slidePage(const DispatchPage()),
  ),
  GoRoute(
    path: '/reports',
    pageBuilder: (context, state) => _slidePage(const ReportsPage()),
  ),
  GoRoute(
    path: '/profile',
    pageBuilder: (context, state) => _slidePage(const ProfilePage()),
  ),
  GoRoute(
    path: '/notifications',
    pageBuilder: (context, state) => _slidePage(const InboxPage()),
  ),
  if (kEnableDebugDbViewer)
    GoRoute(
      path: '/debug/db',
      pageBuilder: (context, state) => _slidePage(const DebugDatabasePage()),
    ),
];

MaterialPage<void> _slidePage(Widget child) => MaterialPage<void>(child: child);

Widget _pageForRoute(String location) {
  switch (location) {
    case '/':
      return const HomePage();
    case '/login':
      return const LoginPage();
    case '/unauthorized':
      return const UnauthorizedPage();
    case '/requests':
      return const RequestsPage();
    case '/requests/new':
      return const NewRequestPage();
    case '/dispatch':
      return const DispatchPage();
    case '/reports':
      return const ReportsPage();
    case '/profile':
      return const ProfilePage();
    case '/notifications':
      return const InboxPage();
    default:
      if (location.startsWith('/requests/')) {
        final id = location.split('/').last;
        return RequestDetailsPage(id: id);
      }
      if (location.startsWith('/jobs/')) {
        final id = location.split('/').last;
        return JobDetailsPage(id: id);
      }
      if (location == '/jobs') return const JobsPage();
      return const UnauthorizedPage();
  }
}
