import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signIn(String email, String password);

  /// Registers a new account. With email confirmation enabled the session
  /// is absent right after sign-up; the caller should still surface the
  /// created user and instruct them to confirm their inbox.
  Future<Result<AppUser>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  });

  Future<void> signOut();
}
