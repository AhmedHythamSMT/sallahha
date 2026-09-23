import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/theme/app_theme.dart';

/// Email+password auth against the real backend (Supabase).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await ref
        .read(authRepositoryProvider)
        .signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (res) {
      case Ok(value: final user):
        ref.read(sessionUserProvider.notifier).state = user;
        if (!mounted) return;
        context.go('/');
      case Err(error: Unauthorized()):
        // Wrong credentials on sign-in reads better than "session expired".
        setState(() => _error = SallahhaLocalizations.of(context).signInFailed);
      case Err(error: final e):
        setState(() => _error = errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 64.h),
                decoration: BoxDecoration(
                  gradient: AppGradients.teal,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32.r),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(
                            Symbols.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                        child: Icon(
                          Symbols.home_repair_service_rounded,
                          color: Colors.white,
                          size: 40.sp,
                        ),
                      ).animate().fadeIn().scaleY(
                        begin: 0.7,
                        end: 1,
                        curve: Curves.easeOutBack,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l.loginTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 120.ms).slideX(
                        begin: -0.15,
                        end: 0,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        l.loginSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14.sp,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -32.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: AppShadows.soft(Theme.of(context).colorScheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l.emailLabel,
                            prefixIcon: const Icon(
                              Symbols.alternate_email_rounded,
                            ),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l.passwordLabel,
                            prefixIcon: const Icon(Symbols.lock_rounded),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          SizedBox(height: 12.h),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l.signInAction),
                        ),
                        SizedBox(height: 6.h),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(l.createAccountAction),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}