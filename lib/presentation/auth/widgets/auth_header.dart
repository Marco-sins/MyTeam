import 'package:flutter/material.dart';
import 'package:football_manager/core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final bool isRegisterMode;

  const AuthHeader({super.key, required this.isRegisterMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Equipaso',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.98),
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isRegisterMode ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
