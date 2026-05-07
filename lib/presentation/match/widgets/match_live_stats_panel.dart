import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';

/// Panel de estadísticas en vivo del partido (tiros, faltas, córners).
///
/// Estilo alineado con las tarjetas del gestor: superficie contenida, tipografía
/// clara y bloques duales “nosotros / rival”.
class MatchLiveStatsPanel extends StatelessWidget {
  /// Crea el panel con los contadores y callbacks opcionales.
  const MatchLiveStatsPanel({
    super.key,
    required this.layoutScale,
    required this.readOnly,
    required this.shotsOur,
    required this.shotsRival,
    required this.foulsOur,
    required this.foulsRival,
    required this.cornersOur,
    required this.cornersRival,
    required this.offsidesOur,
    required this.offsidesRival,
    required this.yellowCardsOur,
    required this.yellowCardsRival,
    required this.redCardsOur,
    required this.redCardsRival,
    required this.l10n,
    this.onRemoveShot,
    this.onAddShot,
    this.onRemoveRivalShot,
    this.onAddRivalShot,
    this.onRemoveRivalFoul,
    this.onAddRivalFoul,
    this.onRemoveCorner,
    this.onAddCorner,
    this.onRemoveRivalCorner,
    this.onAddRivalCorner,
    this.onRemoveRivalOffside,
    this.onAddRivalOffside,
    this.onRemoveRivalYellowCard,
    this.onAddRivalYellowCard,
    this.onRemoveRivalRedCard,
    this.onAddRivalRedCard,
  });

  final double layoutScale;
  final bool readOnly;
  final int shotsOur;
  final int shotsRival;
  final int foulsOur;
  final int foulsRival;
  final int cornersOur;
  final int cornersRival;
  final int offsidesOur;
  final int offsidesRival;
  final int yellowCardsOur;
  final int yellowCardsRival;
  final int redCardsOur;
  final int redCardsRival;
  final AppLocalizations l10n;

  final VoidCallback? onRemoveShot;
  final VoidCallback? onAddShot;
  final VoidCallback? onRemoveRivalShot;
  final VoidCallback? onAddRivalShot;
  final VoidCallback? onRemoveRivalFoul;
  final VoidCallback? onAddRivalFoul;
  final VoidCallback? onRemoveCorner;
  final VoidCallback? onAddCorner;
  final VoidCallback? onRemoveRivalCorner;
  final VoidCallback? onAddRivalCorner;
  final VoidCallback? onRemoveRivalOffside;
  final VoidCallback? onAddRivalOffside;
  final VoidCallback? onRemoveRivalYellowCard;
  final VoidCallback? onAddRivalYellowCard;
  final VoidCallback? onRemoveRivalRedCard;
  final VoidCallback? onAddRivalRedCard;

  /// Construye el panel con secciones de tiros, faltas y corners.
  /// Lo hace componiendo bloques con contadores y botones.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = layoutScale;

    return Padding(
      padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 12 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10 * s),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8 * s),
                  child: Icon(
                    Icons.insights_outlined,
                    color: scheme.primary,
                    size: 22 * s,
                  ),
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Text(
                  l10n.matchLiveStatsCardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.05),
                  blurRadius: 12 * s,
                  offset: Offset(0, 4 * s),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(14 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(
                    icon: Icons.sports_soccer_outlined,
                    label: l10n.matchShotsOnGoalSection,
                    scheme: scheme,
                    s: s,
                    theme: theme,
                  ),
                  SizedBox(height: 12 * s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CornerBlock(
                          value: shotsOur,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.primary,
                          readOnly: readOnly,
                          onMinus: onRemoveShot,
                          onPlus: onAddShot,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _CornerBlock(
                          value: shotsRival,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.tertiary,
                          readOnly: readOnly,
                          onMinus: onRemoveRivalShot,
                          onPlus: onAddRivalShot,
                          tooltipMinus: l10n.matchRivalShotRemoveTooltip,
                          tooltipPlus: l10n.matchRivalShotAddTooltip,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14 * s),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  _SectionLabel(
                    icon: Icons.front_hand_outlined,
                    label: l10n.matchFoulsShort,
                    scheme: scheme,
                    s: s,
                    theme: theme,
                  ),
                  SizedBox(height: 10 * s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CornerBlock(
                          value: foulsOur,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.primary,
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _CornerBlock(
                          value: foulsRival,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.tertiary,
                          readOnly: readOnly,
                          onMinus: onRemoveRivalFoul,
                          onPlus: onAddRivalFoul,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14 * s),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  _SectionLabel(
                    icon: Icons.flag_outlined,
                    label: l10n.matchCornersShort,
                    scheme: scheme,
                    s: s,
                    theme: theme,
                  ),
                  SizedBox(height: 12 * s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CornerBlock(
                          value: cornersOur,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.primary,
                          readOnly: readOnly,
                          onMinus: onRemoveCorner,
                          onPlus: onAddCorner,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _CornerBlock(
                          value: cornersRival,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.tertiary,
                          readOnly: readOnly,
                          onMinus: onRemoveRivalCorner,
                          onPlus: onAddRivalCorner,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14 * s),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  _SectionLabel(
                    icon: Icons.outlined_flag,
                    label: 'Fuera de juego',
                    scheme: scheme,
                    s: s,
                    theme: theme,
                  ),
                  SizedBox(height: 10 * s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CornerBlock(
                          value: offsidesOur,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.primary,
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _CornerBlock(
                          value: offsidesRival,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.tertiary,
                          readOnly: readOnly,
                          onMinus: onRemoveRivalOffside,
                          onPlus: onAddRivalOffside,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14 * s),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  _SectionLabel(
                    icon: Icons.style_outlined,
                    label: l10n.matchActionLabelYellowCard,
                    scheme: scheme,
                    s: s,
                    theme: theme,
                  ),
                  SizedBox(height: 10 * s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CornerBlock(
                          value: yellowCardsOur,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.primary,
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _CornerBlock(
                          value: yellowCardsRival,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.tertiary,
                          readOnly: readOnly,
                          onMinus: onRemoveRivalYellowCard,
                          onPlus: onAddRivalYellowCard,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14 * s),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  _SectionLabel(
                    icon: Icons.stop_circle_outlined,
                    label: l10n.matchActionLabelRedCard,
                    scheme: scheme,
                    s: s,
                    theme: theme,
                  ),
                  SizedBox(height: 10 * s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CornerBlock(
                          value: redCardsOur,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.primary,
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _CornerBlock(
                          value: redCardsRival,
                          scheme: scheme,
                          theme: theme,
                          s: s,
                          accent: scheme.tertiary,
                          readOnly: readOnly,
                          onMinus: onRemoveRivalRedCard,
                          onPlus: onAddRivalRedCard,
                          tooltipMinus: l10n.matchCounterRemoveTooltip,
                          tooltipPlus: l10n.matchCounterAddTooltip,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  /// Crea la etiqueta de seccion con icono.
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.s,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final double s;
  final ThemeData theme;

  /// Construye la fila con icono y texto.
  /// Lo hace con un Row simple.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18 * s, color: scheme.primary.withValues(alpha: 0.9)),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: scheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniCounterButton extends StatelessWidget {
  /// Crea el boton compacto de suma/resta.
  const _MiniCounterButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.scheme,
    required this.s,
    this.filled = false,
    this.compact = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme scheme;
  final double s;
  final bool filled;
  final bool compact;

  /// Construye el boton con estilos y tooltip.
  /// Lo hace usando Material e InkWell.
  @override
  Widget build(BuildContext context) {
    final pad = compact ? 3.5 * s : 6 * s;
    final iconSize = compact ? 14.0 * s : 20 * s;
    final radius = compact ? 7.0 * s : 10 * s;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled
            ? scheme.primaryContainer.withValues(alpha: 0.75)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Icon(
              icon,
              size: iconSize,
              color: filled ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerBlock extends StatelessWidget {
  /// Crea el bloque de contador con botones opcionales.
  const _CornerBlock({
    required this.value,
    required this.scheme,
    required this.theme,
    required this.s,
    required this.accent,
    required this.readOnly,
    this.onMinus,
    this.onPlus,
    this.tooltipMinus,
    this.tooltipPlus,
  });

  final int value;
  final ColorScheme scheme;
  final ThemeData theme;
  final double s;
  final Color accent;
  final bool readOnly;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final String? tooltipMinus;
  final String? tooltipPlus;

  /// Construye el bloque segun el modo lectura o editable.
  /// Lo hace alternando entre texto fijo y botones.
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 8 * s),
        child: readOnly
            ? Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accent,
                      height: 1,
                    ),
                  ),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MiniCounterButton(
                    tooltip: tooltipMinus!,
                    icon: Icons.remove_rounded,
                    onPressed: onMinus,
                    scheme: scheme,
                    s: s,
                    compact: true,
                  ),
                  SizedBox(width: 4 * s),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '$value',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4 * s),
                  _MiniCounterButton(
                    tooltip: tooltipPlus!,
                    icon: Icons.add_rounded,
                    onPressed: onPlus,
                    scheme: scheme,
                    s: s,
                    compact: true,
                    filled: true,
                  ),
                ],
              ),
      ),
    );
  }
}
