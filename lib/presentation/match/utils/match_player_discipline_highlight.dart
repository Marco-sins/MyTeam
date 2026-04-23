import 'package:flutter/material.dart';

/// Aviso visual de disciplina (tarjetas) para un jugador en el partido en curso.
enum MatchPlayerDisciplineHighlight { none, yellow, red }

/// Rojo más intenso que [ColorScheme.error] (tarjeta roja / expulsión).
Color intenseDisciplineRed(ColorScheme scheme) {
  return Color.lerp(const Color(0xFFB71C1C), scheme.error, 0.38)!;
}
