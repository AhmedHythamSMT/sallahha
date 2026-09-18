import 'package:flutter/material.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Thin scaffold for Phase-2 placeholder screens. Phase 3 replaces bodies
/// with real features; the banner + a11y labels stay.
class PlaceholderScaffold extends StatelessWidget {
  final String title;
  final String? body;
  final List<Widget> actions;
  const PlaceholderScaffold({
    super.key,
    required this.title,
    this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  body ?? l.pagePlaceholder,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
