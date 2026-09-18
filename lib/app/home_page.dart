import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Role-aware home: nav cards filtered by the authorization matrix.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final role = ref.watch(sessionRoleProvider);
    final user = ref.watch(sessionUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(localeProvider.notifier)
                .setLocale(locale == 'ar' ? 'en' : 'ar'),
            child: Text(locale == 'ar' ? 'EN' : 'عربي'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (role == null)
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l.signInAction),
                  )
                else ...[
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  if (role == 'customer')
                    _NavCard(title: l.newRequestTitle, route: '/requests/new'),
                  _NavCard(title: l.navRequests, route: '/requests'),
                  _NavCard(title: l.navInbox, route: '/notifications'),
                  if (role == 'technician' ||
                      role == 'supervisor' ||
                      role == 'admin')
                    _NavCard(title: l.navJobs, route: '/jobs'),
                  if (role == 'supervisor' || role == 'admin') ...[
                    _NavCard(title: l.navDispatch, route: '/dispatch'),
                    _NavCard(title: l.navReports, route: '/reports'),
                  ],
                  _NavCard(title: l.navProfile, route: '/profile'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String route;
  const _NavCard({required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    // push (not go): sections keep history so the AppBar back button
    // and the Android back gesture traverse back instead of exiting.
    return Card(
      child: ListTile(title: Text(title), onTap: () => context.push(route)),
    );
  }
}
