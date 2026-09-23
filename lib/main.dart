import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sallahha/app/app.dart';
import 'package:sallahha/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether the global dotenv already holds both Supabase settings
/// (avoids re-entering a NotInitializedError when a prior optional load
/// failed outright).
Future<bool> _configComplete() async {
  try {
    return dotenv.isEveryDefined(['SUPABASE_URL', 'SUPABASE_ANON_KEY']);
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the status + nav bars (edge-to-edge). Content keeps its
  // own insets via SafeArea/AppBar; dark icons on light surfaces by default.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Optional env config (.env is git-ignored; copy .env.example).
  // NOTE: must load into the GLOBAL `dotenv` singleton — AppConfig reads it.
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e) {
    if (kDebugMode) debugPrint('MAIN: DotEnv .env FAILED: $e');
  }
  if (!(await _configComplete())) {
    try {
      await dotenv.load(fileName: 'assets/.env', isOptional: true);
    } catch (e) {
      if (kDebugMode) debugPrint('MAIN: DotEnv assets/.env FAILED: $e');
    }
  }
  if (kDebugMode) {
    debugPrint('MAIN: envCount=${dotenv.env.length} keys=${dotenv.env.keys.toList()}');
    debugPrint('MAIN: usesSupabase=${AppConfig.usesSupabase}');
  }

  if (AppConfig.usesSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl!,
        publishableKey: AppConfig.supabaseAnonKey!,
      );
      if (kDebugMode) debugPrint('MAIN: Supabase.initialize OK');
    } catch (e) {
      if (kDebugMode) debugPrint('MAIN: Supabase.initialize FAILED: $e');
    }
  }

  runApp(const ProviderScope(child: SallahhaApp()));
}
