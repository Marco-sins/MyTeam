import 'package:flutter/material.dart';

/// Colores alineados con [AppTheme] para la imagen exportada de convocatoria.
abstract final class ConvocationImageTheme {
  /// Ancho del PNG y márgenes (deben coincidir con [generateConvocationImage]).
  static const double exportWidth = 1080;
  static const double overlayMargin = 40;
  static const double headerHeight = 208;
  static const double headerBottomGap = 36;
  static const double cardCornerRadius = 32;

  static const Color pitch = Color(0xFF14532D);
  static const Color pitchBright = Color(0xFF1A7A45);
  static const Color surface = Color(0xFFF0FAF3);
  static const Color surfaceLow = Color(0xFFE8F4EC);
  static const Color surfaceContainer = Color(0xFFDCEFE2);
  static const Color onSurface = Color(0xFF0D1F14);
  static const Color onSurfaceVariant = Color(0xFF3D5246);
  static const Color outline = Color(0xFF6B8274);
  static const Color outlineVariant = Color(0xFFADCCB8);
  static const Color primaryContainer = Color(0xFFA8D4B8);
  static const Color onPrimaryContainer = Color(0xFF002110);
  static const Color secondaryContainer = Color(0xFFF5E7B5);
  static const Color onSecondaryContainer = Color(0xFF3D2F00);
  static const Color gold = Color(0xFFE6C229);
  static const Color goldDeep = Color(0xFFB8941A);
  static const Color tertiary = Color(0xFF0F5C4A);
}
