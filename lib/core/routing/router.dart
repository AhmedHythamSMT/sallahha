import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/app/home_page.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/routing/unauthorized_page.dart';
import 'package:sallahha/features/auth/presentation/login_page.dart';
import 'package:sallahha/features/dispatch/presentation/dispatch_page.dart';
import 'package:sallahha/features/jobs/presentation/job_details_page.dart';
import 'package:sallahha/features/jobs/presentation/jobs_page.dart';
import 'package:sallahha/features/notifications/presentation/inbox_page.dart';
import 'package:sallahha/features/profile/presentation/profile_page.dart';
import 'package:sallahha/features/reports/presentation/reports_page.dart';
import 'package:sallahha/features/requests/presentation/new_request_page.dart';
import 'package:sallahha/features/requests/presentation/request_details_page.dart';
import 'package:sallahha/features/requests/presentation/requests_page.dart';

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
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),
      GoRoute(
        path: '/requests',
        builder: (context, state) => const RequestsPage(),
      ),
      GoRoute(
        path: '/requests/new',
        builder: (context, state) => const NewRequestPage(),
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) =>
            RequestDetailsPage(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/jobs', builder: (context, state) => const JobsPage()),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) =>
            JobDetailsPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/dispatch',
        builder: (context, state) => const DispatchPage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const InboxPage(),
      ),
    ],
  );
});
