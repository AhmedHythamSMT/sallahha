import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/format/formatters.dart';
import 'package:sallahha/core/localization/labels.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/features/requests/domain/rules.dart';
import 'package:sallahha/shared/widgets/app_states.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Customer: own requests + create. Supervisor/admin: all (via listForUser).
class RequestsPage extends ConsumerWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final role = ref.watch(sessionRoleProvider);
    final list = ref.watch(myRequestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.queueTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myRequestsProvider),
          ),
        ],
      ),
      floatingActionButton: role == 'customer'
          ? FloatingActionButton(
              tooltip: l.newRequestTitle,
              onPressed: () => context.push('/requests/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: switch (list) {
              AsyncData(value: final items) =>
                items.isEmpty
                    ? const AppEmpty()
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final r = items[i];
                          final overdue = isOverdue(
                            r.slaDueAt,
                            r.status,
                            DateTime.now(),
                          );
                          return Card(
                            child: ListTile(
                              title: Text(
                                '#${r.id} · ${l.statusLabel(r.status)}',
                              ),
                              subtitle: Text(
                                '${r.description}\n${l.slaDueLabel}: '
                                '${formatDateTime(r.slaDueAt, locale)}'
                                '${overdue ? ' · ${l.overdueLabel}' : ''}',
                              ),
                              isThreeLine: true,
                              trailing: Text(l.priorityLabel(r.priority)),
                              onTap: () => context.push('/requests/${r.id}'),
                            ),
                          );
                        },
                      ),
              AsyncError(:final error) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(myRequestsProvider),
              ),
              _ => const AppLoading(),
            },
          ),
        ],
      ),
    );
  }
}
