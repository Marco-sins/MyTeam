import 'package:football_manager/presentation/auth/widgets/copyright_badge.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:football_manager/presentation/auth/widgets/auth_mode_selector.dart';
import 'package:football_manager/presentation/home/pages/home_page.dart';
import 'package:football_manager/presentation/auth/pages/reset_password_page.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRegisterMode = false;
  StreamSubscription<dynamic>? _authSubscription;

  void _toggleMode() => setState(() => _isRegisterMode = !_isRegisterMode);

  Future<void> _showRegisterCheckEmailDialog(
    BuildContext context, {
    required String email,
    required bool mustConfirmBeforeLogin,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final body = mustConfirmBeforeLogin
        ? l10n.authRegisterEmailConfirm(email)
        : l10n.authRegisterEmailActive;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            Icons.mark_email_unread_outlined,
            size: 44,
            color: scheme.primary,
          ),
          title: Text(l10n.authCheckEmailTitle),
          content: Text(
            body,
            style: textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.authUnderstand),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAuthSideEffects(
    BuildContext context,
    AuthState state,
  ) async {
    if (state is AuthError) {
      if (!context.mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: scheme.error),
      );
      return;
    }

    if (state is AwaitingEmailVerification) {
      await _showRegisterCheckEmailDialog(
        context,
        email: state.email,
        mustConfirmBeforeLogin: true,
      );
      if (!context.mounted) return;
      context.read<AuthCubit>().resetToLogin();
      setState(() => _isRegisterMode = false);
      return;
    }

    if (state is Authenticated) {
      final fromRegister = _isRegisterMode;
      if (fromRegister) {
        await _showRegisterCheckEmailDialog(
          context,
          email: state.user.email,
          mustConfirmBeforeLogin: false,
        );
        if (!context.mounted) return;
        setState(() => _isRegisterMode = false);
      }
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      if (!mounted) {
        return;
      }

      if (event.event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ResetPasswordPage()));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              unawaited(_handleAuthSideEffects(context, state));
            },
            builder: (context, state) {
              return Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AuthHeader(isRegisterMode: _isRegisterMode),
                          const SizedBox(height: 24),

                          Container(
                            constraints: const BoxConstraints(maxWidth: 380),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: _isRegisterMode
                                ? const RegisterForm()
                                : const LoginForm(),
                          ),

                          const SizedBox(height: 8),
                          AuthModeSelector(
                            isRegisterMode: _isRegisterMode,
                            onTap: _toggleMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Copyright badge in bottom right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: const CopyrightBadge(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
