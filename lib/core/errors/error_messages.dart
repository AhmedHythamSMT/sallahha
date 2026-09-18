import 'package:flutter/material.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';

/// Maps typed domain errors to localized user-facing messages.
String errorMessage(BuildContext context, AppError error) {
  final l = SallahhaLocalizations.of(context);
  return switch (error) {
    IllegalTransition() => l.errorIllegalTransition,
    PermissionDenied() => l.errorPermissionDenied,
    NotFound() => l.errorNotFound,
    ValidationFailed() => l.errorValidation,
    SyncFailed() => l.errorSyncFailed,
    Unauthorized() => l.errorUnauthorized,
  };
}
