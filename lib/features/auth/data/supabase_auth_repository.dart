import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/auth/domain/auth_repository.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Supabase-backed auth. Signs in with email+password against the hosted
/// project, then reads the user's profile row (created by the
/// `handleNewUser` trigger — see docs/backend/supabase.migration.sql).
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient client;
  SupabaseAuthRepository(this.client);

  @override
  Future<Result<AppUser>> signIn(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final supaUser = res.user;
      if (supaUser == null) return const Err(Unauthorized());
      final profile = await _profile(supaUser.id);
      return Ok(
        AppUser(
          id: supaUser.id,
          name: profile?['name'] ?? supaUser.email ?? '',
          phone: profile?['phone'] ?? '',
          email: supaUser.email,
          role: profile?['role'] ?? 'customer',
        ),
      );
    } on AuthException catch (e) {
      // Supabase surfaces "Invalid login credentials" for bad email/password.
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('log in')) {
        return const Err(Unauthorized());
      }
      return Err(SyncFailed('supabase_auth: ${e.message}'));
    } catch (e) {
      return Err(SyncFailed('supabase_network: $e'));
    }
  }

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        email.trim().isEmpty ||
        password.length < 8) {
      return const Err(ValidationFailed('inline'));
    }
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'name': name.trim(),
          'phone': phone.trim(),
          'role': role,
        },
      );
      final supaUser = res.user;
      return Ok(
        AppUser(
          id: supaUser?.id ?? '',
          name: name.trim(),
          phone: phone.trim(),
          email: email.trim(),
          role: role,
        ),
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already') || msg.contains('registered')) {
        return const Err(ValidationFailed('email'));
      }
      if (msg.contains('password')) {
        return const Err(ValidationFailed('password'));
      }
      return Err(SyncFailed('supabase_auth: ${e.message}'));
    } catch (e) {
      return Err(SyncFailed('supabase_network: $e'));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (_) {}
  }

  /// Restores the persisted Supabase session (auto-loaded at cold start)
  /// as an [AppUser], or null when signed out.
  Future<AppUser?> restoreSession() async {
    final supaUser = client.auth.currentSession?.user;
    if (supaUser == null) return null;
    final profile = await _profile(supaUser.id);
    return AppUser(
      id: supaUser.id,
      name: profile?['name'] ?? supaUser.email ?? '',
      phone: profile?['phone'] ?? '',
      email: supaUser.email,
      role: profile?['role'] ?? 'customer',
    );
  }

  Future<Map<String, dynamic>?> _profile(String uid) async {
    try {
      final rows = await client
          .from('profiles')
          .select('id, name, phone, role')
          .eq('id', uid)
          .limit(1);
      if (rows.isEmpty) return null;
      return rows.first;
    } catch (_) {
      return null;
    }
  }
}
