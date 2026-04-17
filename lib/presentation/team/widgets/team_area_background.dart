import 'package:flutter/material.dart';
import 'package:football_manager/core/theme/team_screen_tint.dart';
import 'package:football_manager/domain/entities/team.dart';

/// Fondo con tinte suave según `team.color` (vacío → verde por defecto de la app).
class TeamAreaBackground extends StatelessWidget {
  final Team team;
  final Widget child;

  const TeamAreaBackground({
    super.key,
    required this.team,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: TeamScreenTint.bodyGradient(context, team.color),
      ),
      child: child,
    );
  }
}
