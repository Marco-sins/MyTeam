import 'package:flutter/material.dart';
import 'package:football_manager/core/theme/team_screen_tint.dart';

/// Medidas del PNG exportado (compartidas con [generateConvocationImage]).
abstract final class ConvocationImageTheme {
  static const double exportWidth = 1080;
  static const double overlayMargin = 40;
  /// Cabecera: título, franja del partido y chips.
  static const double headerHeight = 248;
  static const double headerBottomGap = 28;
  static const double cardCornerRadius = 32;
  /// Radio de las tarjetas de datos en el cuerpo.
  static const double detailCardRadius = 20;
}

/// Colores de la convocatoria exportada: por defecto verde app, o según
/// `teams.color` vía [fromTeamColor].
class ConvocationImagePalette {
  const ConvocationImagePalette({
    required this.pitch,
    required this.pitchBright,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.gold,
    required this.goldDeep,
    required this.tertiary,
  });

  final Color pitch;
  final Color pitchBright;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color gold;
  final Color goldDeep;
  final Color tertiary;

  /// Misma apariencia que los colores fijos históricos (verde).
  static final ConvocationImagePalette classic = ConvocationImagePalette(
    pitch: const Color(0xFF14532D),
    pitchBright: const Color(0xFF1A7A45),
    surface: const Color(0xFFF0FAF3),
    surfaceLow: const Color(0xFFE8F4EC),
    surfaceContainer: const Color(0xFFDCEFE2),
    onSurface: const Color(0xFF0D1F14),
    onSurfaceVariant: const Color(0xFF3D5246),
    outline: const Color(0xFF6B8274),
    outlineVariant: const Color(0xFFADCCB8),
    primaryContainer: const Color(0xFFA8D4B8),
    onPrimaryContainer: const Color(0xFF002110),
    secondaryContainer: const Color(0xFFF5E7B5),
    onSecondaryContainer: const Color(0xFF3D2F00),
    gold: const Color(0xFFE6C229),
    goldDeep: const Color(0xFFB8941A),
    tertiary: const Color(0xFF0F5C4A),
  );

  static Color _contrastOn(Color background) {
    final l = background.computeLuminance();
    return l > 0.55 ? const Color(0xFF0D1F14) : Colors.white;
  }

  factory ConvocationImagePalette.fromTeamColor(String? colorHex) {
    final accent = TeamScreenTint.accentColor(colorHex);
    // Cabecera y fondo: el tono es exactamente el de la paleta; solo se oscurece
    // ligeramente una esquina del gradiente mezclando negro sobre el mismo hex.
    final pitch = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.22),
      accent,
    );
    final pitchBright = accent;

    const baseSurface = Color(0xFFF5F7F6);
    final surface = Color.alphaBlend(
      accent.withValues(alpha: 0.09),
      baseSurface,
    );
    final surfaceLow = Color.alphaBlend(
      accent.withValues(alpha: 0.12),
      const Color(0xFFEEF1EF),
    );
    final surfaceContainer = Color.alphaBlend(
      accent.withValues(alpha: 0.2),
      const Color(0xFFE2E8E5),
    );

    final primaryContainer = Color.alphaBlend(
      accent.withValues(alpha: 0.42),
      const Color(0xFFE8F4EC),
    );
    final onPrimaryContainer = _contrastOn(primaryContainer);

    final secondaryContainer = Color.alphaBlend(
      accent.withValues(alpha: 0.2),
      const Color(0xFFF5E7B5),
    );
    final onSecondaryContainer = _contrastOn(secondaryContainer);

    final gold = Color.lerp(const Color(0xFFE6C229), accent, 0.18)!;
    final goldDeep = Color.lerp(const Color(0xFFB8941A), accent, 0.22)!;

    final tertiary = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.18),
      accent,
    );

    final onSurface = const Color(0xFF0D1F14);
    final onSurfaceVariant = Color.alphaBlend(
      accent.withValues(alpha: 0.35),
      const Color(0xFF3D5246),
    );
    final outline = Color.alphaBlend(
      accent.withValues(alpha: 0.32),
      const Color(0xFF6B8274),
    );
    final outlineVariant = Color.alphaBlend(
      accent.withValues(alpha: 0.22),
      const Color(0xFFADCCB8),
    );

    return ConvocationImagePalette(
      pitch: pitch,
      pitchBright: pitchBright,
      surface: surface,
      surfaceLow: surfaceLow,
      surfaceContainer: surfaceContainer,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      gold: gold,
      goldDeep: goldDeep,
      tertiary: tertiary,
    );
  }
}
