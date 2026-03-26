import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Text(
        isRegisterMode
            ? "¿Ya tienes cuenta? Inicia sesión"
            : "¿No tienes cuenta todavía? Créala aquí",
        style: const TextStyle(
          color: Color(0xFFFFF176),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
