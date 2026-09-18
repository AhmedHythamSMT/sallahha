import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Live sync badge for one entity: synced | pending | failed(+retry).
/// Drop into AppBar actions of detail screens.
class EntitySyncBadge extends ConsumerWidget {
  final String entityId;
  final VoidCallback? onChanged;
  const EntitySyncBadge({super.key, required this.entityId, this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider(entityId));
    return state.when(
      data: (s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: SyncBadge(
            state: switch (s) {
              'failed' => SyncBadgeState.failed,
              'pending' => SyncBadgeState.pending,
              _ => SyncBadgeState.synced,
            },
            onRetry: s == 'failed'
                ? () async {
                    await ref
                        .read(requestRepositoryProvider)
                        .retryEntity(entityId);
                    ref.invalidate(syncStateProvider(entityId));
                    onChanged?.call();
                  }
                : null,
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
