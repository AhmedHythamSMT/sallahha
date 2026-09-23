import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/auth/domain/auth_repository.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// In-memory auth for demo/interview and keyless dev runs. Besides the
/// built-in demo accounts it honors accounts created through [signUp],
/// so the register flow is fully exercisable without a server.
class MockAuthRepository implements AuthRepository {
  final MockBackend backend;
  MockAuthRepository(this.backend);

  final Map<String, ({AppUser user, String password})> _registered = {};

  @override
  Future<Result<AppUser>> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final emailKey = email.trim().toLowerCase();
    final account = _registered[emailKey];
    if (account != null) {
      if (account.password != password) return const Err(Unauthorized());
      return Ok(account.user);
    }
    return backend.signIn(emailKey, password);
  }

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        email.trim().isEmpty ||
        password.length < 8) {
      return const Err(ValidationFailed('inline'));
    }
    final emailKey = email.trim().toLowerCase();
    if (_registered.containsKey(emailKey) ||
        backend.users.values.any((u) => u.email?.toLowerCase() == emailKey)) {
      return const Err(ValidationFailed('email'));
    }
    final user = AppUser(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      role: role,
    );
    _registered[emailKey] = (user: user, password: password);
    return Ok(user);
  }

  @override
  Future<void> signOut() async {}
}