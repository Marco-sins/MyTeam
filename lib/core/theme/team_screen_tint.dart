import 'package:flutter/material.dart';

/// Color de acento por defecto (mismo verde césped que [AppTheme]).
abstract final class TeamScreenTint {
  static const Color defaultAccent = Color(0xFF14532D);

  /// Tonos habituales en equipaciones (clubs, selecciones). Hex en `teams.color`.
  static const List<({String label, String hex})> palette = [
    (label: 'Rojo clásico', hex: '#C8102E'),
    (label: 'Rojo carmesí', hex: '#B71C1C'),
    (label: 'Bermellón', hex: '#7B1129'),
    (label: 'Granate', hex: '#5C0E12'),
    (label: 'Azul marino', hex: '#00205B'),
    (label: 'Azul royal', hex: '#0039A6'),
    (label: 'Celeste', hex: '#5EA3D4'),
    (label: 'Turquesa', hex: '#007C92'),
    (label: 'Verde botella', hex: '#0D4F2B'),
    (label: 'Verde campo', hex: '#14532D'),
    (label: 'Verde esmeralda', hex: '#008759'),
    (label: 'Amarillo oro', hex: '#E5A800'),
    (label: 'Naranja', hex: '#E85D04'),
    (label: 'Violeta', hex: '#5B21B6'),
    (label: 'Morado uva', hex: '#4A148C'),
    (label: 'Negro', hex: '#181818'),
    (label: 'Gris acero', hex: '#455A64'),
    (label: 'Azul petróleo', hex: '#004D4A'),
  ];

  static Color accentColor(String? stored) {
    if (stored == null || stored.trim().isEmpty) return defaultAccent;
    var hex = stored.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v == null) return defaultAccent;
      return Color(0xFF000000 | v);
    }
    if (hex.length == 8) {
      final v = int.tryParse(hex, radix: 16);
      if (v == null) return defaultAccent;
      return Color(v);
    }
    return defaultAccent;
  }

  /// Contenido (texto/icono) legible sobre [accent] sin cambiar el tono de la paleta.
  static Color onAccent(Color accent) {
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.light
        ? const Color(0xFF0D1F14)
        : Colors.white;
  }

  static LinearGradient bodyGradient(BuildContext context, String? stored) {
    final accent = accentColor(stored);
    final base = Theme.of(context).scaffoldBackgroundColor;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(accent.withValues(alpha: 0.16), base),
        Color.alphaBlend(accent.withValues(alpha: 0.04), base),
        base,
      ],
      stops: const [0.0, 0.42, 1.0],
    );
  }

  /// Mezcla el acento sobre [base] con opacidad fija (misma “suavidad” para cualquier color).
  static Color wash(String? stored, double alpha, Color base) {
    return Color.alphaBlend(accentColor(stored).withValues(alpha: alpha), base);
  }

  /// Superficie principal tipo #F0FAF3 cuando el acento es el verde por defecto.
  static Color teamSurface(String? stored) => wash(stored, 0.058, Colors.white);

  static Color teamSurfaceContainerLow(String? stored) =>
      wash(stored, 0.092, Colors.white);

  static Color teamSurfaceContainer(String? stored) =>
      wash(stored, 0.125, Colors.white);

  static Color teamSurfaceContainerHigh(String? stored) =>
      wash(stored, 0.168, const Color(0xFFFAFAFA));

  static Color teamSurfaceContainerHighest(String? stored) =>
      wash(stored, 0.215, const Color(0xFFF5F5F5));

  /// Misma claridad que el primaryContainer verde (#A8D4B8) con acento por defecto.
  static Color teamPrimaryContainer(String? stored) =>
      wash(stored, 0.36, const Color(0xFFE8EFEA));

  static Color teamOnPrimaryContainer(String? stored) {
    final bg = teamPrimaryContainer(stored);
    final l = bg.computeLuminance();
    return l > 0.55 ? const Color(0xFF0D1F14) : Colors.white;
  }

  static Color teamOutline(String? stored) =>
      wash(stored, 0.22, const Color(0xFF7A847E));

  static Color teamOutlineVariant(String? stored) =>
      wash(stored, 0.14, const Color(0xFFC5CEC8));

  static Color teamOnSurfaceVariant(String? stored) =>
      wash(stored, 0.2, const Color(0xFF3D5246));

  /// Chips / contenedores secundarios: lavado del acento sobre crema (sustituye el verde).
  static Color teamSecondaryContainer(String? stored) =>
      wash(stored, 0.17, const Color(0xFFF5E8D6));

  static Color teamOnSecondaryContainer(String? stored) {
    final bg = teamSecondaryContainer(stored);
    final l = bg.computeLuminance();
    return l > 0.58 ? const Color(0xFF2A2100) : Colors.white;
  }
}
