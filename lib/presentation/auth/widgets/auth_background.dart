import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A2415),
            Color(0xFF14532D),
            Color(0xFF1F6B40),
            Color(0xFF2A8F55),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: child,
    );
  }
}
