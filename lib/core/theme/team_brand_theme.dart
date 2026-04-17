import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/core/theme/team_screen_tint.dart';

/// Tema local del equipo: superficies, contenedores y acentos usan el color guardado
/// con la misma suavidad que el verde histórico de la app (no solo la barra superior).
abstract final class TeamBrandTheme {
  static ThemeData wrap(BuildContext context, String? teamColorHex) {
    final base = Theme.of(context);
    final b = base.colorScheme;
    final accent = TeamScreenTint.accentColor(teamColorHex);
    final onPrimary = TeamScreenTint.onAccent(accent);
    final seeded = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    );
    final merged = b.copyWith(
      primary: accent,
      onPrimary: onPrimary,
      primaryContainer: TeamScreenTint.teamPrimaryContainer(teamColorHex),
      onPrimaryContainer: TeamScreenTint.teamOnPrimaryContainer(teamColorHex),
      secondary: b.secondary,
      onSecondary: b.onSecondary,
      secondaryContainer: TeamScreenTint.teamSecondaryContainer(teamColorHex),
      onSecondaryContainer:
          TeamScreenTint.teamOnSecondaryContainer(teamColorHex),
      tertiary: seeded.tertiary,
      onTertiary: seeded.onTertiary,
      tertiaryContainer: seeded.tertiaryContainer,
      onTertiaryContainer: seeded.onTertiaryContainer,
      surface: TeamScreenTint.teamSurface(teamColorHex),
      onSurface: b.onSurface,
      onSurfaceVariant: TeamScreenTint.teamOnSurfaceVariant(teamColorHex),
      outline: TeamScreenTint.teamOutline(teamColorHex),
      outlineVariant: TeamScreenTint.teamOutlineVariant(teamColorHex),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: TeamScreenTint.teamSurfaceContainerLow(teamColorHex),
      surfaceContainer: TeamScreenTint.teamSurfaceContainer(teamColorHex),
      surfaceContainerHigh:
          TeamScreenTint.teamSurfaceContainerHigh(teamColorHex),
      surfaceContainerHighest:
          TeamScreenTint.teamSurfaceContainerHighest(teamColorHex),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: merged.primary.withValues(alpha: 0.22)),
    );

    return base.copyWith(
      colorScheme: merged,
      scaffoldBackgroundColor: base.scaffoldBackgroundColor,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: merged.primary,
        foregroundColor: merged.onPrimary,
        iconTheme: IconThemeData(color: merged.onPrimary, size: 22),
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          color: merged.onPrimary,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: cardShape,
        color: merged.surface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: merged.surfaceContainerLow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: merged.primary.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: merged.primary, width: 2),
        ),
        floatingLabelStyle: TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: merged.primary,
          foregroundColor: merged.onPrimary,
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
          backgroundColor: merged.primary,
          foregroundColor: merged.onPrimary,
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
          foregroundColor: merged.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: merged.primary.withValues(alpha: 0.55)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: merged.outlineVariant.withValues(alpha: 0.45),
      ),
      listTileTheme: base.listTileTheme.copyWith(iconColor: merged.primary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: merged.primary,
        circularTrackColor: merged.surfaceContainerHigh,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: merged.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: merged.surfaceContainerLow,
        surfaceTintColor: merged.primary.withValues(alpha: 0.08),
      ),
    );
  }
}

class TeamBrandedScope extends StatelessWidget {
  final Team team;
  final Widget child;

  const TeamBrandedScope({
    super.key,
    required this.team,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: TeamBrandTheme.wrap(context, team.color),
      child: child,
    );
  }
}
