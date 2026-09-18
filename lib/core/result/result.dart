// Typed result for repository / use-case returns. No thrown business errors.
import 'package:sallahha/core/errors/app_error.dart';

sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final AppError error;
  const Err(this.error);
}
