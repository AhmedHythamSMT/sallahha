import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';

/// Global connectivity banner. Shown when offline; sync engine (Phase 4)
/// also listens to the same provider to flush the outbox.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    if (!offline) return const SizedBox.shrink();
    final l = SallahhaLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        l.stateOffline,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Per-job / per-change sync badge. States mirror the sync state machine doc.
enum SyncBadgeState { synced, pending, failed }

class SyncBadge extends StatelessWidget {
  final SyncBadgeState state;
  final VoidCallback? onRetry;
  const SyncBadge({super.key, required this.state, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return switch (state) {
      SyncBadgeState.synced => Chip(label: Text(l.syncSynced)),
      SyncBadgeState.pending => Chip(label: Text(l.syncPending)),
      SyncBadgeState.failed => ActionChip(
        label: Text(l.syncFailed),
        onPressed: onRetry,
      ),
    };
  }
}
