import 'package:flutter/material.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/theme/app_theme.dart';
import 'package:sallahha/shared/animations/app_animations.dart';

/// Required UI states, one place: loading / empty / error / offline.
/// Every feature screen must use these instead of ad-hoc placeholders.
class AppLoading extends StatefulWidget {
  const AppLoading({super.key});

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _rotation,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppTokens.spaceMd),
          Text(l.stateLoading),
        ],
      ),
    );
  }
}

class AppEmpty extends StatelessWidget {
  final IconData icon;
  const AppEmpty({super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: AppTokens.spaceMd),
          Text(l.stateEmpty, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppTokens.spaceMd),
            Text(l.stateError, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.spaceSm),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spaceMd),
              AppAnimations.scaleOnTap(
                onTap: onRetry!,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: Text(l.actionRetry),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
