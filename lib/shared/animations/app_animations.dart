import 'package:flutter/material.dart';

/// Centralized animation constants and helpers.
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;

  /// Slide + fade for page content
  static Widget slideFadeIn({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(0, 0.1),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: standard)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Scale pop for buttons/cards on tap
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.96,
    Duration duration = fast,
  }) {
    return _ScaleOnTap(
      child: child,
      onTap: onTap,
      scale: scale,
      duration: duration,
    );
  }

  /// Pulse animation for sync badges / attention
  static Widget pulse({
    required Widget child,
    required AnimationController controller,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: minScale,
        end: maxScale,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      child: child,
    );
  }

  /// Staggered list item animation
  static Widget staggeredListItem({
    required Widget child,
    required Animation<double> animation,
    int index = 0,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    final delayedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        (index * delay.inMilliseconds / 1000).clamp(0.0, 0.8),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    return slideFadeIn(
      child: child,
      animation: delayedAnimation,
      begin: const Offset(0, 0.15),
    );
  }

  /// Shimmer loading placeholder
  static Widget shimmer({
    required Widget child,
    required AnimationController controller,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return _Shimmer(
      controller: controller,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration duration;

  const _ScaleOnTap({
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.duration = AppAnimations.fast,
  });

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  final AnimationController controller;
  final Color baseColor;
  final Color highlightColor;

  const _Shimmer({
    required this.child,
    required this.controller,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: widget.controller, curve: Curves.easeInOut),
    );
    widget.controller.repeat(period: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Page route transition with slide + fade
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideFadePageRoute({
    required this.page,
    this.duration = AppAnimations.normal,
    RouteSettings? settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         settings: settings,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return SlideTransition(
             position:
                 Tween<Offset>(
                   begin: const Offset(0.0, 0.1),
                   end: Offset.zero,
                 ).animate(
                   CurvedAnimation(
                     parent: animation,
                     curve: AppAnimations.standard,
                   ),
                 ),
             child: FadeTransition(opacity: animation, child: child),
           );
         },
       );
}

/// Shared animation controller for list animations
class ListAnimationController extends ChangeNotifier {
  final AnimationController controller;
  ListAnimationController({required this.controller});

  void start() {
    if (!controller.isAnimating) {
      controller.forward(from: 0.0);
    }
  }

  void reset() {
    controller.reset();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
