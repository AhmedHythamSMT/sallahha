import 'package:flutter/material.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/theme/app_theme.dart';

/// Required UI states, one place: loading / empty / error / offline.
/// Every feature screen must use these instead of ad-hoc placeholders.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
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
          Icon(icon, size: 48),
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
              ElevatedButton(onPressed: onRetry, child: Text(l.actionRetry)),
            ],
          ],
        ),
      ),
    );
  }
}
