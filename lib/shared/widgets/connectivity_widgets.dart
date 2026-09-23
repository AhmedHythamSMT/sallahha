import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/shared/animations/app_animations.dart';

/// Global connectivity banner. Shown when offline; sync engine (Phase 4)
/// also listens to the same provider to flush the outbox.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    if (!offline) return const SizedBox.shrink();
    final l = SallahhaLocalizations.of(context);
    return AnimatedContainer(
      duration: AppAnimations.normal,
      curve: AppAnimations.standard,
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

class SyncBadge extends ConsumerStatefulWidget {
  final SyncBadgeState state;
  final VoidCallback? onRetry;
  const SyncBadge({super.key, required this.state, this.onRetry});

  @override
  ConsumerState<SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends ConsumerState<SyncBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.state == SyncBadgeState.pending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SyncBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == SyncBadgeState.pending) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);

    Widget badge;
    switch (widget.state) {
      case SyncBadgeState.synced:
        badge = Chip(
          key: const ValueKey('synced'),
          label: Text(l.syncSynced),
          avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
          backgroundColor: Colors.green.withValues(alpha: 0.1),
        );
        break;
      case SyncBadgeState.pending:
        badge = _PulseBadge(
          controller: _pulseController,
          label: l.syncPending,
          icon: Icons.sync,
          color: Colors.orange,
        );
        break;
      case SyncBadgeState.failed:
        badge = ActionChip(
          key: const ValueKey('failed'),
          label: Text(l.syncFailed),
          avatar: const Icon(Icons.error_outline, size: 16, color: Colors.red),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          onPressed: widget.onRetry,
        );
        break;
    }

    return AnimatedSwitcher(duration: AppAnimations.fast, child: badge);
  }
}

class _PulseBadge extends StatelessWidget {
  final AnimationController controller;
  final String label;
  final IconData icon;
  final Color color;

  const _PulseBadge({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (controller.value * 0.05),
          child: Chip(
            label: Text(label),
            avatar: Icon(icon, size: 16, color: color),
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        );
      },
    );
  }
}
