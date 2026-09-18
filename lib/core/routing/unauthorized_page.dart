import 'package:flutter/material.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/shared/widgets/placeholder_scaffold.dart';

/// Shown when a signed-in role opens a route outside its matrix.
/// Mirrors docs/backend/authorization-matrix.md at UI level
/// (server-side enforcement lands with the remote adapter).
class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return PlaceholderScaffold(
      title: l.unauthorizedTitle,
      body: l.unauthorizedBody,
    );
  }
}
