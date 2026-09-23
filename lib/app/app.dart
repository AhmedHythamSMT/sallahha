import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/routing/router.dart';
import 'package:sallahha/core/theme/app_theme.dart';

class SallahhaApp extends ConsumerWidget {
  const SallahhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    // Kick the outbox flush once at startup (offline queue from last run).
    ref.watch(startupFlushProvider);
    // Restore persisted session (silent when absent).
    ref.watch(sessionRestoreProvider);
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: 'Sallahha',
        theme: AppTheme.light(),
        locale: Locale(locale),
        supportedLocales: SallahhaLocalizations.supportedLocales,
        localizationsDelegates: const [
          SallahhaLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _AutoSync()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flushes the outbox when connectivity returns, then refreshes lists.
/// Invisible; lives above all routes.
class _AutoSync extends ConsumerWidget {
  const _AutoSync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityProvider, (_, next) async {
      final online = (next.valueOrNull ?? const []).any(
        (r) => r != ConnectivityResult.none,
      );
      if (!online) return;
      await ref.read(requestRepositoryProvider).flushOutbox();
      ref
        ..invalidate(myRequestsProvider)
        ..invalidate(dispatchQueueProvider);
    });
    return const SizedBox.shrink();
  }
}
