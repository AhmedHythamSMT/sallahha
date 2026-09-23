import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sallahha/core/config/app_config.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/core/theme/app_theme.dart';

const _roleChoices = ['customer', 'technician', 'supervisor', 'admin'];

/// Real registration (Supabase email+password when configured). In mock
/// mode it validates locally so interviews can run the full flow keyless.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'customer';
  String? _error;
  String? _info;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    // Switch out of demo/interview mode before a real sign-up.
    ref.read(demoModeProvider.notifier).state = false;
    final res = await ref.read(authRepositoryProvider).signUp(
      name: _name.text,
      phone: _phone.text,
      email: _email.text,
      password: _password.text,
      role: _role,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (res) {
      case Ok(value: final user):
        final signedIn = AppConfig.isMock ||
            (user.id.isNotEmpty &&
                ref
                    .read(supabaseClientProvider)
                    ?.auth
                    .currentSession !=
                    null);
        if (!signedIn) {
          // Supabase with email confirmation enabled.
          setState(
            () => _info = SallahhaLocalizations.of(context).registerCheckEmail,
          );
          return;
        }
        ref.read(sessionUserProvider.notifier).state = user;
        await ref.read(sessionStoreProvider).save(user);
        if (!mounted) return;
        context.go('/');
      case Err(error: ValidationFailed(field: final field)):
        setState(() {
          _error = field == 'email'
              ? SallahhaLocalizations.of(context).registerEmailTaken
              : field == 'password'
              ? SallahhaLocalizations.of(context).registerPasswordShort
              : errorMessage(context, res.error);
        });
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
                          onPressed: () => context.go('/login'),
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
                          Symbols.badge_rounded,
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
                        l.registerTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 120.ms),
                      SizedBox(height: 6.h),
                      Text(
                        l.registerSubtitle,
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
                    padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 24.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: AppShadows.soft(Theme.of(context).colorScheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.registerNameLabel,
                            prefixIcon: const Icon(Symbols.person_rounded),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.registerPhoneLabel,
                            prefixIcon: const Icon(Symbols.phone_rounded),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
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
                        SizedBox(height: 20.h),
                        Text(
                          l.registerRoleLabel,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            for (final r in _roleChoices)
                              ChoiceChip(
                                label: Text(_roleName(l, r)),
                                selected: _role == r,
                                onSelected: (_) => setState(() => _role = r),
                              ),
                          ],
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
                        if (_info != null) ...[
                          SizedBox(height: 12.h),
                          Text(
                            _info!,
                            style: TextStyle(
                              color: AppTokens.seedDeep,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
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
                              : Text(l.registerAction),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l.loginInstead),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: Icon(Symbols.badge_rounded, size: 18.sp),
                label: Text(l.demoHint),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  textStyle: TextStyle(fontSize: 12.sp),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  String _roleName(SallahhaLocalizations l, String role) {
    return switch (role) {
      'customer' => l.roleCustomer,
      'technician' => l.roleTechnician,
      'supervisor' => l.roleSupervisor,
      'admin' => l.roleAdmin,
      _ => role,
    };
  }
}