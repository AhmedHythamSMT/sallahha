import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/shared/widgets/app_states.dart';

/// Notification inbox (drift-backed). FCM push lands post-MVP; the inbox
/// is the offline-capable equivalent today.
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = SallahhaLocalizations.of(context);
    final user = ref.watch(sessionUserProvider);
    final inbox = user == null
        ? const AsyncValue<List<dynamic>>.data([])
        : ref.watch(inboxProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: Text(l.inboxTitle)),
      body: switch (inbox) {
        AsyncData(value: final items) =>
          items.isEmpty
              ? const AppEmpty()
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(item.body),
                        trailing: Text(item.kind),
                        onTap: () async {
                          if (!item.read) {
                            await ref
                                .read(notificationServiceProvider)
                                .markRead(item.id);
                            ref.invalidate(inboxProvider(user!.id));
                          }
                        },
                      ),
                    );
                  },
                ),
        AsyncError(:final error) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(inboxProvider(user?.id ?? '')),
        ),
        _ => const AppLoading(),
      },
    );
  }
}
