import 'package:flutter/material.dart';

import 'package:football_manager/core/theme/app_responsive_tokens.dart';

export 'app_responsive_tokens.dart';

Iterable<ThemeExtension<dynamic>> _mergeResponsiveThemeExtensions(
  ThemeData base,
  double layoutScale,
  double screenWidth,
) sync* {
  for (final e in base.extensions.values) {
    if (e is! AppResponsiveTokens) {
      yield e;
    }
  }
  yield AppResponsiveTokens(
    layoutScale: layoutScale,
    screenWidth: screenWidth,
  ) as ThemeExtension<dynamic>;
}

/// Ajustes globales para distintos tamaños de pantalla y de texto del sistema.
///
/// El escalado de fuente (accesibilidad) se limita suavemente para evitar
/// desbordes masivos en layouts con alturas fijas; el rango sigue siendo amplio.
///
/// [layoutScaleFactor] y [themeWithLayout] unifican tipografía, iconos, márgenes
/// de componentes Material y [AppResponsiveTokens] para espaciados manuales.
abstract final class AppResponsive {
  AppResponsive._();

  /// Factor mínimo respecto al tamaño base (texto muy pequeño del sistema).
  static const double minTextScaleFactor = 0.82;

  /// Factor máximo (texto grande / accesibilidad).
  static const double maxTextScaleFactor = 1.52;

  /// Ancho por debajo del cual se considera “móvil estrecho”.
  static const double narrowWidthBreakpoint = 360;

  /// Ancho por debajo del cual se usa padding horizontal reducido.
  static const double compactWidthBreakpoint = 400;

  /// Ancho de referencia para [layoutScaleFactor] (≈1.0 por encima).
  static const double _layoutReferenceWidth = 600;

  /// Factor de densidad global (~0.88 en ~320px → ~1.0 en pantallas anchas).
  static double layoutScaleFactor(double width) {
    const minS = 0.88;
    const maxS = 1.0;
    if (width >= _layoutReferenceWidth) return maxS;
    if (width <= 0) return minS;
    final t = width / _layoutReferenceWidth;
    return minS + (maxS - minS) * t;
  }

  /// Aplica [layoutScaleFactor] a tipografía, iconos, botones y densidad
  /// visual de Material sobre [base].
  static ThemeData themeWithLayout(ThemeData base, double width) {
    final s = layoutScaleFactor(width);
    final compact = s < 0.93;
    final dens = compact ? VisualDensity.compact : VisualDensity.standard;
    final iconSize = (base.iconTheme.size ?? 24) * s;
    final appBarIcon = (base.appBarTheme.iconTheme?.size ?? 22) * s;
    final appBarTitleFs = (base.appBarTheme.titleTextStyle?.fontSize ?? 18) * s;

    return base.copyWith(
      extensions: _mergeResponsiveThemeExtensions(base, s, width),
      visualDensity: dens,
      textTheme: base.textTheme.apply(fontSizeFactor: s),
      iconTheme: base.iconTheme.copyWith(size: iconSize),
      primaryIconTheme: base.primaryIconTheme.copyWith(size: iconSize),
      appBarTheme: base.appBarTheme.copyWith(
        toolbarHeight: kToolbarHeight * s,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontSize: appBarTitleFs,
        ),
        iconTheme: base.appBarTheme.iconTheme?.copyWith(size: appBarIcon),
        actionsIconTheme: base.appBarTheme.actionsIconTheme?.copyWith(
          size: appBarIcon,
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4 * s),
        titleTextStyle: base.listTileTheme.titleTextStyle?.copyWith(
          fontSize: (base.listTileTheme.titleTextStyle?.fontSize ?? 16) * s,
        ),
        subtitleTextStyle: base.listTileTheme.subtitleTextStyle?.copyWith(
          fontSize: (base.listTileTheme.subtitleTextStyle?.fontSize ?? 13) * s,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * s,
          vertical: 14 * s,
        ),
        labelStyle: _scaleTextStyle(base.inputDecorationTheme.labelStyle, s),
        floatingLabelStyle: _scaleTextStyle(
          base.inputDecorationTheme.floatingLabelStyle,
          s,
        ),
        hintStyle: _scaleTextStyle(base.inputDecorationTheme.hintStyle, s),
        helperStyle: _scaleTextStyle(base.inputDecorationTheme.helperStyle, s),
        errorStyle: _scaleTextStyle(base.inputDecorationTheme.errorStyle, s),
        prefixStyle: _scaleTextStyle(base.inputDecorationTheme.prefixStyle, s),
        suffixStyle: _scaleTextStyle(base.inputDecorationTheme.suffixStyle, s),
        counterStyle: _scaleTextStyle(base.inputDecorationTheme.counterStyle, s),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        contentTextStyle: base.snackBarTheme.contentTextStyle?.copyWith(
          fontSize: (base.snackBarTheme.contentTextStyle?.fontSize ?? 14) * s,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _scaleButtonPadding(
          base.filledButtonTheme.style,
          minW: 64 * s,
          minH: 48 * s,
          horizontal: 20 * s,
          vertical: 14 * s,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _scaleButtonPadding(
          base.elevatedButtonTheme.style,
          minW: 64 * s,
          minH: 48 * s,
          horizontal: 20 * s,
          vertical: 14 * s,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _scaleButtonPadding(
          base.outlinedButtonTheme.style,
          minW: 64 * s,
          minH: 44 * s,
          horizontal: 20 * s,
          vertical: 12 * s,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _scaleButtonPadding(
          base.textButtonTheme.style,
          minW: 48 * s,
          minH: 40 * s,
          horizontal: 12 * s,
          vertical: 8 * s,
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        iconSize: (base.floatingActionButtonTheme.iconSize ?? 24) * s,
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        strokeWidth: (base.progressIndicatorTheme.strokeWidth ?? 4) * s,
      ),
      cardTheme: _scaleCardTheme(base.cardTheme, s),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: base.dialogTheme.titleTextStyle?.copyWith(
          fontSize: (base.dialogTheme.titleTextStyle?.fontSize ?? 18) * s,
        ),
        contentTextStyle: base.dialogTheme.contentTextStyle?.copyWith(
          fontSize: (base.dialogTheme.contentTextStyle?.fontSize ?? 14) * s,
        ),
      ),
    );
  }

  static TextStyle? _scaleTextStyle(TextStyle? style, double s) {
    if (style == null) return null;
    final fs = style.fontSize;
    if (fs == null) return style;
    return style.copyWith(fontSize: fs * s);
  }

  static ButtonStyle? _scaleButtonPadding(
    ButtonStyle? style, {
    required double minW,
    required double minH,
    required double horizontal,
    required double vertical,
  }) {
    if (style == null) return null;
    return style.copyWith(
      minimumSize: WidgetStateProperty.all(Size(minW, minH)),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      ),
    );
  }

  static CardThemeData _scaleCardTheme(CardThemeData card, double s) {
    final shape = card.shape;
    if (shape is RoundedRectangleBorder) {
      final r = shape.borderRadius.resolve(TextDirection.ltr);
      final top = r.topLeft.x;
      return card.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(top * s),
          side: shape.side,
        ),
      );
    }
    return card;
  }

  /// [MaterialApp.builder]: limita el [TextScaler] del sistema y aplica tema
  /// responsive (densidad, tipografía, iconos, botones).
  static Widget materialAppBuilder(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: minTextScaleFactor,
      maxScaleFactor: maxTextScaleFactor,
      child: Builder(
        builder: (context) {
          final width = MediaQuery.sizeOf(context).width;
          final themed = themeWithLayout(Theme.of(context), width);
          return Theme(
            data: themed,
            child: content,
          );
        },
      ),
    );
  }

  /// Padding horizontal habitual de página (listas, scaffolds).
  static double pageHorizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final s = layoutScaleFactor(w);
    if (w < narrowWidthBreakpoint) return 12 * s;
    if (w < compactWidthBreakpoint) return 14 * s;
    return 16 * s;
  }

  /// Ancho máximo de contenido centrado en tablet / escritorio.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w > 900) return 720;
    if (w > 600) return 560;
    return w;
  }

  static bool isNarrowScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidthBreakpoint;
}
