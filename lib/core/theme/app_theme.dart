import 'package:flutter/material.dart';

/// Paleta “amateur football”: césped, banquillo verde, líneas claras y acento oro.
abstract final class AppTheme {
  static const Color _pitch = Color(0xFF14532D);
  static const Color _pitchBright = Color(0xFF1A7A45);
  static const Color _scaffoldBg = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFF0FAF3);
  static const Color _gold = Color(0xFFE6C229);
  static const Color _goldDeep = Color(0xFFB8941A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _pitchBright,
      brightness: Brightness.light,
    ).copyWith(
      primary: _pitch,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFA8D4B8),
      onPrimaryContainer: const Color(0xFF002110),
      secondary: _gold,
      onSecondary: const Color(0xFF1F1700),
      secondaryContainer: const Color(0xFFF5E7B5),
      onSecondaryContainer: const Color(0xFF3D2F00),
      tertiary: const Color(0xFF0F5C4A),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFB8E8DC),
      onTertiaryContainer: const Color(0xFF002019),
      surface: _surface,
      onSurface: const Color(0xFF0D1F14),
      onSurfaceVariant: const Color(0xFF3D5246),
      outline: const Color(0xFF6B8274),
      outlineVariant: const Color(0xFFADCCB8),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFE8F4EC),
      surfaceContainer: const Color(0xFFDCEFE2),
      surfaceContainerHigh: const Color(0xFFC8E5D3),
      surfaceContainerHighest: const Color(0xFFB0D9C1),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    final outline = scheme.outlineVariant;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _scaffoldBg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.22),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: 0.45),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.85)),
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: _pitchBright,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          // No usar Size.fromHeight: el ancho sería infinito y rompe filas/listas.
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _pitchBright,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 3,
        highlightElevation: 3,
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.08),
        shadowColor: Colors.transparent,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHigh,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: scheme.onError,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: scheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.35,
        ),
        bodySmall: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Acento oro para detalles (badges, highlights) sin depender del contexto.
  static Color get accentGold => _gold;

  static Color get accentGoldDeep => _goldDeep;
}
