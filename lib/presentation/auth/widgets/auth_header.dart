import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final bool isRegisterMode;

  const AuthHeader({super.key, required this.isRegisterMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Equipaso",
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black26,
                offset: Offset(0, 3),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          isRegisterMode ? "Nice to meet you!" : "Welcome back!",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black26,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
