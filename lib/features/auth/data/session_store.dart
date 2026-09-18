import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Session persistence. Secure storage on device (tokens/identity must
/// never sit in SharedPreferences); memory in tests. All reads are
/// exception-safe — a locked keystore means signed-out, never a crash.
abstract class SessionStore {
  Future<void> save(AppUser user);
  Future<AppUser?> restore();
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  final FlutterSecureStorage _storage;
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> save(AppUser user) async {
    try {
      await _storage.write(key: 'uid', value: user.id);
      await _storage.write(key: 'name', value: user.name);
      await _storage.write(key: 'phone', value: user.phone);
      await _storage.write(key: 'email', value: user.email);
      await _storage.write(key: 'role', value: user.role);
    } catch (_) {
      // Keystore locked/unavailable: session simply won't persist.
    }
  }

  @override
  Future<AppUser?> restore() async {
    try {
      final values = await _storage.readAll();
      final id = values['uid'];
      final role = values['role'];
      if (id == null || role == null) return null;
      return AppUser(
        id: id,
        name: values['name'] ?? '',
        phone: values['phone'] ?? '',
        email: values['email'],
        role: role,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

class MemorySessionStore implements SessionStore {
  AppUser? _user;
  @override
  Future<void> save(AppUser user) async => _user = user;
  @override
  Future<AppUser?> restore() async => _user;
  @override
  Future<void> clear() async => _user = null;
}
