import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/theme/app_theme.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Role-aware home: premium nav cards filtered by the authorization matrix,
/// with a gradient hero header and staggered entrance animations.
///
/// Also owns the background freshness policy: Supabase realtime is the
/// low-latency fast path, while a lightweight lifecycle-aware poller keeps
/// the inbox badge and request lists current even when the websocket is
/// slow, drops, or simply never connected (tables not yet in the realtime
/// publication). Polling pauses while the app is backgrounded.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  Timer? _inboxTimer;
  Timer? _listTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimers();
      _syncNow();
    } else {
      _stopTimers();
    }
  }

  /// Replaces the cached providers so the screen reflects server state
  /// without waiting for the poller's next tick.
  void _syncNow() {
    final user = ref.read(sessionUserProvider);
    if (user != null) ref.invalidate(inboxProvider(user.id));
    _invalidateRequests();
  }

  void _invalidateRequests() {
    final role = ref.read(sessionRoleProvider);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(requestDetailsProvider);
    if (role == 'supervisor' || role == 'admin') {
      ref.invalidate(dispatchQueueProvider);
      ref.invalidate(workloadProvider);
    }
  }

  void _startTimers() {
    if (ref.read(sessionUserProvider) == null) return;
    _inboxTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      final user = ref.read(sessionUserProvider);
      if (user != null) ref.invalidate(inboxProvider(user.id));
    });
    _listTimer ??= Timer.periodic(const Duration(seconds: 25), (_) {
      _invalidateRequests();
    });
  }

  void _stopTimers() {
    _inboxTimer?.cancel();
    _inboxTimer = null;
    _listTimer?.cancel();
    _listTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final role = ref.watch(sessionRoleProvider);
    final user = ref.watch(sessionUserProvider);
    final unread = user == null
        ? 0
        : ref.watch(unreadInboxProvider(user.id)).valueOrNull ?? 0;

    // Keep the polling active while signed in; stop when signed out.
    ref.listen(sessionUserProvider, (previous, next) {
      if (next != null) {
        _startTimers();
        _syncNow();
      } else {
        _stopTimers();
      }
    });

    // Live inbox fast path: server push → invalidate the local mirror so
    // the badge (and the inbox screen) reflect cross-device deliveries.
    ref.listen(notificationRealtimeProvider(user?.id ?? ''), (_, next) {
      next.whenData((_) {
        if (user != null) ref.invalidate(inboxProvider(user.id));
      });
    });

    // Live requests fast path: any service_requests child-table change
    // invalidates the lists, dispatch queue, workload and open details.
    ref.listen(requestRealtimeProvider, (_, next) {
      next.whenData((_) => _invalidateRequests());
    });

    final tiles = <_NavTile>[
      if (role == 'customer')
        _NavTile(
          title: l.newRequestTitle,
          route: '/requests/new',
          icon: Symbols.add_circle_rounded,
          hero: true,
        ),
      _NavTile(
        title: l.navRequests,
        route: '/requests',
        icon: Symbols.pending_actions_rounded,
      ),
      _NavTile(
        title: l.navInbox,
        route: '/notifications',
        icon: Symbols.notifications_active_rounded,
        badge: unread,
      ),
      if (role == 'technician' || role == 'supervisor' || role == 'admin')
        _NavTile(
          title: l.navJobs,
          route: '/jobs',
          icon: Symbols.construction_rounded,
        ),
      if (role == 'supervisor' || role == 'admin') ...[
        _NavTile(
          title: l.navDispatch,
          route: '/dispatch',
          icon: Symbols.route_rounded,
        ),
        _NavTile(
          title: l.navReports,
          route: '/reports',
          icon: Symbols.bar_chart_rounded,
        ),
      ],
      _NavTile(
        title: l.navProfile,
        route: '/profile',
        icon: Symbols.person_rounded,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeHeader(
                      name: user?.name,
                      role: role,
                      onToggleLocale: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(locale == 'ar' ? 'en' : 'ar'),
                      locale: locale,
                      onSignIn:
                          role == null ? () => context.go('/login') : null,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 24.h),
                      child: Column(
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                              ),
                              child: _NavCard(
                                tile: tiles[i],
                                hero: tiles[i].hero && role == 'customer',
                              ),
                            ),
                            if (i < tiles.length - 1) SizedBox(height: 8.h),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String? name;
  final String? role;
  final String locale;
  final VoidCallback onToggleLocale;
  final VoidCallback? onSignIn;
  const _HomeHeader({
    required this.name,
    required this.role,
    required this.locale,
    required this.onToggleLocale,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final signedIn = name != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22.w),
        decoration: BoxDecoration(
          gradient: AppGradients.teal,
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          boxShadow: AppShadows.soft(Theme.of(context).colorScheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    signedIn ? '${l.greetingPrefix} 👋' : l.appTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onToggleLocale,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                  child: Text(
                    locale == 'ar' ? 'EN' : 'عربي',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            if (signedIn)
              Text(
                name!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            SizedBox(height: 4.h),
            if (signedIn)
              Text(
                _roleLabel(l, role),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            SizedBox(height: 18.h),
            if (!signedIn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTokens.seedDeep,
                    minimumSize: Size.fromHeight(52.h),
                  ),
                  icon: Icon(Symbols.login_rounded, size: 20.sp),
                  label: Text(l.signInAction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(SallahhaLocalizations l, String? role) {
  return switch (role) {
    'customer' => l.roleCustomer,
    'technician' => l.roleTechnician,
    'supervisor' => l.roleSupervisor,
    'admin' => l.roleAdmin,
    _ => l.homeSubtitle,
  };
}

class _NavTile {
  final String title;
  final String route;
  final IconData icon;
  final bool hero;
  final int badge;
  const _NavTile({
    required this.title,
    required this.route,
    required this.icon,
    this.hero = false,
    this.badge = 0,
  });
}

class _NavCard extends StatelessWidget {
  final _NavTile tile;
  final bool hero;
  const _NavCard({required this.tile, required this.hero});

  @override
  Widget build(BuildContext context) {
    // push (not go): sections keep history so the AppBar back button
    // and the Android back gesture traverse back instead of exiting.
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      onTap: () => context.push(tile.route),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
        decoration: BoxDecoration(
          gradient: hero ? AppGradients.accent : null,
          color: hero ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: hero
              ? null
              : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: hero
              ? [
                  BoxShadow(
                    color: AppTokens.accent.withValues(alpha: 0.35),
                    blurRadius: 18.r,
                    offset: const Offset(0, 8),
                  ),
                ]
              : AppShadows.soft(Theme.of(context).colorScheme),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: hero
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTokens.seed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                tile.icon,
                color: hero ? Colors.white : AppTokens.seedDeep,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                tile.title,
                style: TextStyle(
                  color: hero ? Colors.white : const Color(0xFF1B1F1E),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (tile.badge > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTokens.seed,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${tile.badge}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Icon(
              Symbols.chevron_right_rounded,
              color: hero
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey.shade400,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}