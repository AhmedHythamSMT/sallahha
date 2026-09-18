import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/format/formatters.dart';
import 'package:sallahha/core/localization/labels.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/rules.dart';
import 'package:sallahha/shared/widgets/app_states.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Supervisor queue: new/active/overdue/done tabs, search, workload,
/// assign sheet, priority change. Triage hint is read-only + confirmed.
class DispatchPage extends ConsumerStatefulWidget {
  const DispatchPage({super.key});

  @override
  ConsumerState<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends ConsumerState<DispatchPage> {
  String _view = 'new';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final queue = ref.watch(dispatchQueueProvider(_view));
    final workload = ref.watch(workloadProvider);
    final techs = ref.watch(techniciansProvider);
    const views = ['new', 'active', 'overdue', 'done'];
    return Scaffold(
      appBar: AppBar(title: Text(l.navDispatch)),
      body: Column(
        children: [
          const OfflineBanner(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final v in views)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(switch (v) {
                        'new' => l.queueNew,
                        'active' => l.queueActive,
                        'overdue' => l.queueOverdue,
                        _ => l.queueDone,
                      }),
                      selected: _view == v,
                      onSelected: (_) => setState(() => _view = v),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(hintText: l.searchHint),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: switch (workload) {
              AsyncData(value: final w) => Builder(
                builder: (context) {
                  final techsById = {
                    for (final t in techs.valueOrNull ?? const []) t.id: t.name,
                  };
                  final text = w.entries
                      .map(
                        (e) =>
                            '${techsById[e.key] ?? e.key} · ${e.value} ${l.activeJobsSuffix}',
                      )
                      .join(' — ');
                  return Text(
                    text.isEmpty ? l.stateEmpty : '${l.workloadTitle}: $text',
                  );
                },
              ),
              _ => const SizedBox.shrink(),
            },
          ),
          Expanded(
            child: switch (queue) {
              AsyncData(value: final items) => Builder(
                builder: (context) {
                  final q = _search.text.trim();
                  final filtered = q.isEmpty
                      ? items
                      : items
                            .where(
                              (r) => r.id.contains(q) || r.phone.contains(q),
                            )
                            .toList();
                  if (filtered.isEmpty) return const AppEmpty();
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final r = filtered[i];
                      final suggestion = ref
                          .watch(aiServiceProvider)
                          .suggest(r.description);
                      final overdue = isOverdue(
                        r.slaDueAt,
                        r.status,
                        DateTime.now(),
                      );
                      return Card(
                        child: ListTile(
                          title: Text(
                            '#${r.id} · ${l.statusLabel(r.status)}'
                            '${overdue ? ' · ${l.overdueLabel}' : ''}',
                          ),
                          subtitle: Text(
                            '${r.description}\n'
                            '${l.triageSuggestion}: '
                            '${suggestion.category}/${suggestion.priority}\n'
                            '${l.slaDueLabel}: '
                            '${formatDateTime(r.slaDueAt, locale)}',
                          ),
                          isThreeLine: true,
                          onTap: () => context.push('/requests/${r.id}'),
                          trailing: switch (techs) {
                            AsyncData(value: final t) => IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: () => _assignSheet(context, r.id, t),
                            ),
                            _ => null,
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              AsyncError(:final error) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(dispatchQueueProvider),
              ),
              _ => const AppLoading(),
            },
          ),
        ],
      ),
    );
  }

  void _assignSheet(BuildContext context, String requestId, List techs) {
    final l = SallahhaLocalizations.of(context);
    final user = ref.read(sessionUserProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          Text(l.assignTitle, style: Theme.of(context).textTheme.titleMedium),
          for (final t in techs)
            ListTile(
              title: Text(t.name),
              subtitle: Text(t.phone),
              onTap: () async {
                Navigator.of(context).pop();
                if (user == null) return;
                final res = await ref
                    .read(requestRepositoryProvider)
                    .assign(
                      by: user,
                      requestId: requestId,
                      technicianId: t.id,
                      idempotencyKey: newOpKey(user.id),
                    );
                if (context.mounted) {
                  switch (res) {
                    case Err(error: final e):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage(context, e))),
                      );
                    case Ok():
                      break;
                  }
                }
                ref.invalidate(dispatchQueueProvider);
                ref.invalidate(myRequestsProvider);
              },
            ),
        ],
      ),
    );
  }
}
