import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration sourced from `.env` (loaded in main) with
/// `--dart-define` override support for CI.
///
/// Data source selection:
///   * default  → mock backend (keyless, offline demo)
///   * SUPABASE_URL + SUPABASE_ANON_KEY set → Supabase backend
///   * or force with `--dart-define=DATA_SOURCE=supabase|mock`
class AppConfig {
  static const _sourceOverride = String.fromEnvironment('DATA_SOURCE');

  AppConfig._();

  static String? _env(String key) {
    try {
      final v = dotenv.env[key]?.trim();
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      // DotEnv not loaded (tests / keyless builds) → config absent.
      return null;
    }
  }

  static String? get supabaseUrl => _env('SUPABASE_URL');
  static String? get supabaseAnonKey => _env('SUPABASE_ANON_KEY');

  static bool get usesSupabase {
    if (_sourceOverride.isNotEmpty) return _sourceOverride == 'supabase';
    final envSource = _env('DATA_SOURCE');
    if (envSource != null) return envSource == 'supabase';
    return supabaseUrl != null && supabaseAnonKey != null;
  }

  static bool get isMock => !usesSupabase;
}
