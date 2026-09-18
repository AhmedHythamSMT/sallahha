import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';

/// Email+password against the mock auth (demo accounts). Phase 5: Supabase.
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
        await ref.read(sessionStoreProvider).save(user);
        if (!mounted) return;
        context.go('/');
      case Err(error: Unauthorized()):
        // Wrong credentials on sign-in reads better than "session expired".
        setState(() => _error = SallahhaLocalizations.of(context).signInFailed);
      case Err(error: final e):
        setState(() => _error = errorMessage(context, e));
    }
  }

  void _fill(String email) {
    _email.text = email;
    _password.text = 'demo1234';
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.loginTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.loginSubtitle),
          const SizedBox(height: 8),
          Text(l.demoHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.emailLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l.passwordLabel),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: Text(l.signInAction),
          ),
          const SizedBox(height: 24),
          for (final email in [
            'customer@demo.test',
            'tech@demo.test',
            'supervisor@demo.test',
            'admin@demo.test',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  _fill(email);
                  _submit();
                },
                child: Text(email),
              ),
            ),
        ],
      ),
    );
  }
}
