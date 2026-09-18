import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/rules.dart';
import 'package:sallahha/shared/widgets/app_states.dart';

/// Basic supervisor report: completed count, average rating, overdue now.
/// Demo-scale loop over details; a server aggregate replaces it (Phase 5).
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = SallahhaLocalizations.of(context);
    final done = ref.watch(dispatchQueueProvider('done'));
    final overdue = ref.watch(dispatchQueueProvider('overdue'));
    return Scaffold(
      appBar: AppBar(title: Text(l.reportsTitle)),
      body: Column(
        children: [
          Expanded(
            child: switch (done) {
              AsyncData(value: final items) => _Body(
                done: items.length,
                overdue: overdue.valueOrNull?.length ?? 0,
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
}

class _Body extends ConsumerWidget {
  final int done;
  final int overdue;
  const _Body({required this.done, required this.overdue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = SallahhaLocalizations.of(context);
    final ratingsAsync = ref.watch(_ratingsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(title: Text(l.reportsCompleted), trailing: Text('$done')),
        ListTile(
          title: Text(l.reportsAvgRating),
          trailing: switch (ratingsAsync) {
            AsyncData(value: final avg) => Text(
              avg == null ? '—' : avg.toStringAsFixed(1),
            ),
            _ => const Text('…'),
          },
        ),
        ListTile(title: Text(l.reportsOverdue), trailing: Text('$overdue')),
      ],
    );
  }
}

final _ratingsProvider = FutureProvider<double?>((ref) async {
  final repo = ref.watch(requestRepositoryProvider);
  final doneRes = await repo.dispatchQueue('done');
  switch (doneRes) {
    case Err():
      return null;
    case Ok(value: final done):
      var sum = 0;
      var count = 0;
      for (final r in done) {
        final d = await repo.details(r.id);
        final rating = switch (d) {
          Ok(value: final v) => v.rating,
          Err() => null,
        };
        if (rating != null) {
          sum += rating.stars;
          count++;
        }
      }
      if (count == 0) return null;
      return sum / count;
  }
});

/// Keeps overdue logic unit-adjacent: pure helper reused by widgets.
bool reportIsOverdue(DateTime slaDueAt, String status) =>
    isOverdue(slaDueAt, status, DateTime.now());
