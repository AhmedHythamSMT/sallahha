import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/theme/app_theme.dart';
import 'package:sallahha/features/onboarding/onboarding_controller.dart';

/// Premium Arabic-first onboarding: 4 slides with staggered animations,
/// gradient hero, dot progress and a gradient CTA — inspired by the
/// "hotel intro" style of the Best-Flutter-UI-Templates collection.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).complete();
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    if (_index < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final slides = [
      _SlideData(
        icon: Symbols.home_repair_service_rounded,
        iconColors: AppGradients.teal,
        title: l.onbWelcomeTitle,
        subtitle: l.onbWelcomeBody,
        badge: 'صلّحها',
      ),
      _SlideData(
        icon: Symbols.pending_actions_rounded,
        iconColors: const LinearGradient(
          colors: [Color(0xFF4F83CC), Color(0xFF2B5AA5)],
        ),
        title: l.onbRequestsTitle,
        subtitle: l.onbRequestsBody,
        badge: '',
      ),
      _SlideData(
        icon: Symbols.cloud_off_rounded,
        iconColors: const LinearGradient(
          colors: [Color(0xFF7A5CC2), Color(0xFF533A96)],
        ),
        title: l.onbOfflineTitle,
        subtitle: l.onbOfflineBody,
        badge: '',
      ),
      _SlideData(
        icon: Symbols.groups_rounded,
        iconColors: AppGradients.accent,
        title: l.onbTeamTitle,
        subtitle: l.onbTeamBody,
        badge: '',
      ),
    ];
    final isLast = _index == slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTokens.seedDeep,
      ),
      child: Scaffold(
      backgroundColor: AppTokens.seedDeep,
      body: Stack(
        children: [
          // Decorative blurred orbs.
          Positioned(
            top: -80.h,
            right: -70.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100.h,
            left: -90.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        l.actionSkip,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _OnboardingSlide(data: slides[i], active: i == _index),
                  ),
                ),
                _DotsIndicator(count: slides.length, index: _index),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 28.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18.r),
                        onTap: _next,
                        child: Ink(
                          height: 60.h,
                          decoration: BoxDecoration(
                            gradient: AppGradients.accent,
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppTokens.accent.withValues(alpha: 0.4),
                                blurRadius: 20.r,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? l.actionStart : l.actionNext,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                isLast
                                    ? Symbols.arrow_forward_rounded
                                    : Symbols.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
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
        ],
      ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  final bool active;
  const _OnboardingSlide({required this.data, required this.active});

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  child: active
                      ? Container(
                              key: ValueKey(data.title),
                              width: 220.w,
                              height: 220.w,
                              decoration: BoxDecoration(
                                gradient: data.iconColors,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 30.r,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (data.badge == 'صلّحها')
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: 38.h,
                                      child: Text(
                                        data.badge,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  Icon(
                                    data.icon,
                                    size: 96.sp,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scaleY(
                              begin: 0.75,
                              end: 1.0,
                              curve: Curves.easeOutBack,
                            )
                      : const SizedBox.shrink(),
                ),
                SizedBox(height: 36.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: active
                      ? Column(
                              key: ValueKey('text-${data.title}'),
                              children: [
                                Text(
                                  data.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Text(
                                  data.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w400,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 450.ms, delay: 150.ms)
                            .slideY(begin: 0.15, end: 0)
                      : const SizedBox.shrink(),
                ),
                SizedBox(height: 8.h),
                if (data.badge == 'صلّحها')
                  Text(
                    l.onbWelcomeTagline,
                    style: TextStyle(
                      color: AppTokens.accent.withValues(alpha: 0.95),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final Gradient iconColors;
  final String title;
  final String subtitle;
  final String badge;
  const _SlideData({
    required this.icon,
    required this.iconColors,
    required this.title,
    required this.subtitle,
    this.badge = '',
  });
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: 5.w),
          width: active ? 26.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: active
                ? AppTokens.accent
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6.r),
          ),
        );
      }),
    );
  }
}
