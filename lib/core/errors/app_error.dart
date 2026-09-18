// Typed domain errors. UI maps these to localized AR/EN messages.
sealed class AppError {
  final String code;
  const AppError(this.code);
}

class IllegalTransition extends AppError {
  final String from;
  final List<String> legalNext;
  const IllegalTransition(this.from, this.legalNext)
    : super('ILLEGAL_TRANSITION');
}

class NotFound extends AppError {
  const NotFound() : super('NOT_FOUND');
}

class PermissionDenied extends AppError {
  const PermissionDenied() : super('PERMISSION_DENIED');
}

class ValidationFailed extends AppError {
  final String field;
  const ValidationFailed(this.field) : super('VALIDATION_FAILED');
}

class SyncFailed extends AppError {
  final String reason;
  const SyncFailed(this.reason) : super('SYNC_FAILED');
}

class Unauthorized extends AppError {
  const Unauthorized() : super('UNAUTHORIZED');
}
