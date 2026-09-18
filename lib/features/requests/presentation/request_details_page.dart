import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/format/formatters.dart';
import 'package:sallahha/core/localization/labels.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/shared/widgets/app_states.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';
import 'package:sallahha/shared/widgets/entity_sync_badge.dart';

/// Read-only detail + role actions: supervisor assigns, customer confirms
/// and rates, technician jumps to the job view. Mutations invalidate.
class RequestDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const RequestDetailsPage({super.key, required this.id});

  @override
  ConsumerState<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends ConsumerState<RequestDetailsPage> {
  int _stars = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(requestDetailsProvider(widget.id));
    ref.invalidate(myRequestsProvider);
    ref.invalidate(dispatchQueueProvider);
    ref.invalidate(syncStateProvider(widget.id));
  }

  Future<void> _run(Future<Result<void>> Function() call) async {
    final res = await call();
    if (!mounted) return;
    if (res case Err(error: final e)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final role = ref.watch(sessionRoleProvider);
    final user = ref.watch(sessionUserProvider);
    final async = ref.watch(requestDetailsProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.id}'),
        // Explicit (not implied): details is reachable via go() with an
        // empty stack, where no automatic back button would appear.
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/requests');
            }
          },
        ),
        actions: [EntitySyncBadge(entityId: widget.id, onChanged: _refresh)],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: switch (async) {
              AsyncData(value: final d) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(context, d, locale),
                  const SizedBox(height: 12),
                  _section(context, l.detailsTimeline, [
                    for (final e in d.timeline)
                      ListTile(
                        dense: true,
                        title: Text(
                          '${l.statusLabel(e.from)} → ${l.statusLabel(e.to)}',
                        ),
                        subtitle: e.reason == null ? null : Text(e.reason!),
                      ),
                  ]),
                  if (d.assignment != null)
                    _section(context, l.detailsAssignment, [
                      ListTile(
                        dense: true,
                        title: Text(d.assignment!.technicianName),
                      ),
                    ]),
                  _section(context, l.detailsNotes, [
                    for (final n in d.notes)
                      ListTile(
                        dense: true,
                        title: Text(n.body),
                        subtitle: Text(n.kind),
                      ),
                    if (d.notes.isEmpty) Text(l.stateEmpty),
                  ]),
                  _section(context, l.detailsParts, [
                    for (final p in d.parts)
                      ListTile(
                        dense: true,
                        title: Text('${p.partName} ×${p.qty}'),
                        trailing: Text(formatEgp(p.priceEgp * p.qty, locale)),
                      ),
                    if (d.request.estimateEgp != null)
                      ListTile(
                        dense: true,
                        title: Text(l.estimateLabel),
                        trailing: Text(
                          formatEgp(d.request.estimateEgp!, locale),
                        ),
                      ),
                  ]),
                  if ((role == 'supervisor' || role == 'admin') &&
                      d.request.status == 'completed' &&
                      d.request.estimateEgp != null)
                    _PaymentSection(
                      requestId: widget.id,
                      amountEgp: d.request.estimateEgp!,
                    ),
                  if (role == 'customer' &&
                      d.request.status == 'completed' &&
                      !d.confirmed)
                    ElevatedButton(
                      onPressed: user == null
                          ? null
                          : () => _run(
                              () => ref
                                  .read(requestRepositoryProvider)
                                  .confirm(
                                    by: user,
                                    requestId: widget.id,
                                    idempotencyKey: newOpKey(user.id),
                                  ),
                            ),
                      child: Text(l.confirmCompletion),
                    ),
                  if (role == 'customer' &&
                      d.confirmed &&
                      d.rating == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l.ratingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            icon: Icon(
                              i <= _stars ? Icons.star : Icons.star_border,
                            ),
                            onPressed: () => setState(() => _stars = i),
                          ),
                      ],
                    ),
                    TextField(
                      controller: _comment,
                      decoration: const InputDecoration(),
                    ),
                    ElevatedButton(
                      onPressed: user == null
                          ? null
                          : () => _run(
                              () => ref
                                  .read(requestRepositoryProvider)
                                  .rate(
                                    by: user,
                                    requestId: widget.id,
                                    stars: _stars,
                                    idempotencyKey: newOpKey(user.id),
                                    comment: _comment.text.trim().isEmpty
                                        ? null
                                        : _comment.text.trim(),
                                  ),
                            ),
                      child: Text(l.ratingSubmit),
                    ),
                  ],
                  if (d.rating != null)
                    ListTile(
                      dense: true,
                      title: Text('★' * d.rating!.stars),
                      subtitle: d.rating!.comment == null
                          ? null
                          : Text(d.rating!.comment!),
                    ),
                ],
              ),
              AsyncError(:final error) => AppErrorView(
                message: error.toString(),
                onRetry: _refresh,
              ),
              _ => const AppLoading(),
            },
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, RequestDetails d, String locale) {
    final l = SallahhaLocalizations.of(context);
    final r = d.request;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.description, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${r.address} — ${r.governorate}'),
            Text('${l.slaDueLabel}: ${formatDateTime(r.slaDueAt, locale)}'),
            Text('${l.statusLabel(r.status)} · ${l.priorityLabel(r.priority)}'),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Supervisor payment collection (mock gateway). Demonstrates the
/// PaymentService abstraction; real PSP adapter plugs in post-MVP.
class _PaymentSection extends ConsumerStatefulWidget {
  final String requestId;
  final int amountEgp;
  const _PaymentSection({required this.requestId, required this.amountEgp});

  @override
  ConsumerState<_PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends ConsumerState<_PaymentSection> {
  bool _busy = false;
  String? _lastState;

  Future<void> _collect(String method) async {
    setState(() => _busy = true);
    final record = await ref
        .read(paymentServiceProvider)
        .collect(
          requestId: widget.requestId,
          amountEgp: widget.amountEgp,
          method: method,
        );
    if (mounted) {
      setState(() {
        _busy = false;
        _lastState = record.state;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final history = ref.watch(_paymentHistoryProvider(widget.requestId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.paymentStateLabel}: ${formatEgp(widget.amountEgp, ref.watch(localeProvider))}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            switch (history) {
              AsyncData(value: final items) => Wrap(
                spacing: 8,
                children: [for (final p in items) Chip(label: Text(p.state))],
              ),
              _ => const SizedBox.shrink(),
            },
            if (_lastState != null) Chip(label: Text(_lastState!)),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : () => _collect('cash'),
                  child: Text(l.collectCashAction),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _collect('test_card'),
                  child: Text(l.collectCardAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _paymentHistoryProvider =
    FutureProvider.family<List<PaymentRecord>, String>((ref, requestId) async {
      return ref.watch(paymentServiceProvider).history(requestId);
    });
