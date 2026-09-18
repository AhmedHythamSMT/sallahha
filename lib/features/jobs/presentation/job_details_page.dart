import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/format/formatters.dart';
import 'package:sallahha/core/localization/labels.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/jobs/domain/job_status.dart';
import 'package:sallahha/shared/widgets/app_states.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';
import 'package:sallahha/shared/widgets/entity_sync_badge.dart';

/// Technician job execution: guarded status buttons, diagnosis/labor
/// notes, parts from catalog, estimate. Photo capture lands in Phase 6
/// hardening (path recorded via outbox already).
class JobDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const JobDetailsPage({super.key, required this.id});

  @override
  ConsumerState<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends ConsumerState<JobDetailsPage> {
  final _note = TextEditingController();
  final _estimate = TextEditingController();
  final _reason = TextEditingController();
  String _noteKind = 'diagnosis';

  @override
  void dispose() {
    _note.dispose();
    _estimate.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(requestDetailsProvider(widget.id));
    ref.invalidate(myRequestsProvider);
    ref.invalidate(dispatchQueueProvider);
    ref.invalidate(syncStateProvider(widget.id));
  }

  void _fail(Object e) {
    if (e is AppError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
    }
  }

  Future<void> _transition(String to, int baseVersion) async {
    final user = ref.read(sessionUserProvider);
    if (user == null) return;
    final res = await ref
        .read(requestRepositoryProvider)
        .transition(
          by: user,
          requestId: widget.id,
          to: to,
          baseVersion: baseVersion,
          idempotencyKey: newOpKey(user.id),
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        );
    if (res case Err(error: final e)) _fail(e);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final user = ref.watch(sessionUserProvider);
    final async = ref.watch(requestDetailsProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.id}'),
        // Explicit (not implied): see RequestDetailsPage.
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/jobs');
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.request.description,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${d.request.address} — ${d.request.governorate}',
                          ),
                          Text(d.request.phone),
                          Text(
                            '${l.statusLabel(d.request.status)} · '
                            '${l.priorityLabel(d.request.priority)}',
                          ),
                          if (d.request.estimateEgp != null)
                            Text(
                              '${l.estimateLabel}: '
                              '${formatEgp(d.request.estimateEgp!, locale)}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final next in nextStates(d.request.status))
                        Semantics(
                          button: true,
                          label: l.statusLabel(next),
                          child: ElevatedButton(
                            onPressed: user == null
                                ? null
                                : () => _transition(next, d.request.version),
                            child: Text(l.statusLabel(next)),
                          ),
                        ),
                    ],
                  ),
                  if (['assigned', 'accepted'].contains(d.request.status)) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reason,
                      decoration: InputDecoration(hintText: l.cancelReasonHint),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    l.detailsNotes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final n in d.notes)
                    ListTile(
                      dense: true,
                      title: Text(n.body),
                      subtitle: Text(n.kind),
                    ),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _noteKind,
                        items: const [
                          DropdownMenuItem(
                            value: 'diagnosis',
                            child: Text('diagnosis'),
                          ),
                          DropdownMenuItem(
                            value: 'labor',
                            child: Text('labor'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _noteKind = v!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _note,
                          decoration: InputDecoration(
                            hintText: _noteKind == 'diagnosis'
                                ? l.noteDiagnosisHint
                                : l.noteLaborHint,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: user == null || _note.text.trim().isEmpty
                            ? null
                            : () async {
                                final res = await ref
                                    .read(requestRepositoryProvider)
                                    .addNote(
                                      by: user,
                                      requestId: widget.id,
                                      kind: _noteKind,
                                      body: _note.text,
                                      idempotencyKey: newOpKey(user.id),
                                    );
                                if (res case Err(error: final e)) {
                                  _fail(e);
                                } else {
                                  _note.clear();
                                }
                                _refresh();
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.detailsPhotos,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (d.photos.isNotEmpty)
                    SizedBox(
                      height: 96,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final photo in d.photos)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: _LocalThumb(
                                path: photo.localPath,
                                label: photo.kind,
                              ),
                            ),
                        ],
                      ),
                    ),
                  _PhotoCapture(requestId: widget.id),
                  const SizedBox(height: 16),
                  Text(
                    l.detailsParts,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final p in d.parts)
                    ListTile(
                      dense: true,
                      title: Text('${p.partName} ×${p.qty}'),
                      trailing: Text(formatEgp(p.priceEgp * p.qty, locale)),
                    ),
                  _PartsAdder(requestId: widget.id),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _estimate,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l.estimateLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: user == null
                            ? null
                            : () async {
                                final amount = int.tryParse(
                                  _estimate.text.trim(),
                                );
                                if (amount == null) return;
                                final res = await ref
                                    .read(requestRepositoryProvider)
                                    .setEstimate(
                                      by: user,
                                      requestId: widget.id,
                                      amountEgp: amount,
                                      idempotencyKey: newOpKey(user.id),
                                    );
                                if (res case Err(error: final e)) {
                                  _fail(e);
                                }
                                _refresh();
                              },
                        child: Text(l.setEstimateAction),
                      ),
                    ],
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
}

class _PartsAdder extends ConsumerStatefulWidget {
  final String requestId;
  const _PartsAdder({required this.requestId});

  @override
  ConsumerState<_PartsAdder> createState() => _PartsAdderState();
}

class _PartsAdderState extends ConsumerState<_PartsAdder> {
  String? _partId = 'part-capacitor';
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final user = ref.watch(sessionUserProvider);
    const catalog = [
      ('part-capacitor', 'مكثف / Capacitor'),
      ('part-filter', 'فلتر / Filter'),
      ('part-freon', 'فريون / Freon'),
      ('part-thermostat', 'ثرموستات / Thermostat'),
      ('part-fan-motor', 'موتور مروحة / Fan motor'),
      ('part-remote', 'ريموت / Remote'),
    ];
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: _partId,
            isExpanded: true,
            items: [
              for (final p in catalog)
                DropdownMenuItem(value: p.$1, child: Text(p.$2)),
            ],
            onChanged: (v) => setState(() => _partId = v),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
        ),
        Text('${l.qtyLabel}: $_qty'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => setState(() => _qty++),
        ),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: user == null || _partId == null
              ? null
              : () async {
                  final res = await ref
                      .read(requestRepositoryProvider)
                      .addPart(
                        by: user,
                        requestId: widget.requestId,
                        partId: _partId!,
                        qty: _qty,
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
                  ref.invalidate(requestDetailsProvider(widget.requestId));
                },
        ),
      ],
    );
  }
}

/// Local thumbnail with kind label. Broken/missing files degrade to an icon
/// (offline paths, cleared caches) instead of crashing the job view.
class _LocalThumb extends StatelessWidget {
  final String path;
  final String label;
  const _LocalThumb({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : const Icon(Icons.image_outlined, size: 40),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Before/after capture. Downsized at capture (1024px, q80) for low-end
/// devices; files queue in the outbox like any other mutation.
class _PhotoCapture extends ConsumerStatefulWidget {
  final String requestId;
  const _PhotoCapture({required this.requestId});

  @override
  ConsumerState<_PhotoCapture> createState() => _PhotoCaptureState();
}

class _PhotoCaptureState extends ConsumerState<_PhotoCapture> {
  bool _busy = false;

  Future<void> _capture(String kind) async {
    final user = ref.read(sessionUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;
      final res = await ref
          .read(requestRepositoryProvider)
          .addPhoto(
            by: user,
            requestId: widget.requestId,
            kind: kind,
            localPath: picked.path,
            idempotencyKey: newOpKey(user.id),
          );
      if (res case Err(error: final e) when mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
      }
      ref.invalidate(requestDetailsProvider(widget.requestId));
      ref.invalidate(syncStateProvider(widget.requestId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SallahhaLocalizations.of(context).stateError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _capture('before'),
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(l.photoBeforeAction),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _capture('after'),
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(l.photoAfterAction),
        ),
      ],
    );
  }
}
