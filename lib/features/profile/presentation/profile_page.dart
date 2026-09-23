import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/labels.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';

/// Profile: identity, locale toggle, sign out.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final user = ref.watch(sessionUserProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (user != null) ...[
            Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${l.roleLabel(user.role)} · ${user.phone}'),
            const SizedBox(height: 24),
          ],
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ar', label: Text('عربي')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {locale},
            onSelectionChanged: (s) =>
                ref.read(localeProvider.notifier).setLocale(s.first),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.read(sessionUserProvider.notifier).state = null;
              if (context.mounted) context.go('/login');
            },
            child: Text(l.signOutAction),
          ),
        ],
      ),
    );
  }
}
