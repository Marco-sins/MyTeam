import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';

class AuthModeSelector extends StatelessWidget {
  final bool isRegisterMode;
  final VoidCallback onTap;

  const AuthModeSelector({
    super.key,
    required this.isRegisterMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = isRegisterMode
        ? l10n.authHaveAccountLogin
        : l10n.authNoAccountRegister;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.92),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white70,
        ),
      ),
      child: Text(label),
    );
  }
}
