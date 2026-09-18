import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signIn(String email, String password);
  Future<void> signOut();
}
