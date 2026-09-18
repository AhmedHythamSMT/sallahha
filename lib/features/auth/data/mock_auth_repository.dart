import 'package:sallahha/core/backend/mock_backend.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/auth/domain/auth_repository.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

class MockAuthRepository implements AuthRepository {
  final MockBackend backend;
  MockAuthRepository(this.backend);

  @override
  Future<Result<AppUser>> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return backend.signIn(email.trim(), password);
  }

  @override
  Future<void> signOut() async {}
}
