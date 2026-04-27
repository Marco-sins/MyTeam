import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Tokens de layout derivados del ancho de pantalla, expuestos vía [ThemeExtension].
///
/// Usa [layoutScale] para espaciados manuales: `EdgeInsets.all(16 * context.layoutScale)`.
@immutable
class AppResponsiveTokens extends ThemeExtension<AppResponsiveTokens> {
  const AppResponsiveTokens({
    required this.layoutScale,
    required this.screenWidth,
  });

  /// Factor ~0.88–1.0: pantallas estrechas reducen densidad de forma uniforme.
  final double layoutScale;

  final double screenWidth;

  double gap(double logical) => logical * layoutScale;

  EdgeInsets paddingSymmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(
        horizontal: horizontal * layoutScale,
        vertical: vertical * layoutScale,
      );

  EdgeInsets paddingAll(double value) => EdgeInsets.all(value * layoutScale);

  @override
  AppResponsiveTokens copyWith({
    double? layoutScale,
    double? screenWidth,
  }) {
    return AppResponsiveTokens(
      layoutScale: layoutScale ?? this.layoutScale,
      screenWidth: screenWidth ?? this.screenWidth,
    );
  }

  @override
  AppResponsiveTokens lerp(
    ThemeExtension<AppResponsiveTokens>? other,
    double t,
  ) {
    if (other is! AppResponsiveTokens) return this;
    return AppResponsiveTokens(
      layoutScale: lerpDouble(layoutScale, other.layoutScale, t)!,
      screenWidth: lerpDouble(screenWidth, other.screenWidth, t)!,
    );
  }
}

extension AppResponsiveBuildContext on BuildContext {
  /// Factor de layout del tema (1.0 si no hay extensión).
  double get layoutScale =>
      Theme.of(this).extension<AppResponsiveTokens>()?.layoutScale ?? 1.0;

  AppResponsiveTokens? get responsiveTokens =>
      Theme.of(this).extension<AppResponsiveTokens>();
}
