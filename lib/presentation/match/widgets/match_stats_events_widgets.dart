import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';

/// Marca de minuto alineada con el tema de la app.
class _MinuteBadge extends StatelessWidget {
  /// Crea el badge de minuto opcional.
  const _MinuteBadge({this.minute});

  final int? minute;

  /// Construye el badge con el minuto formateado.
  /// Lo hace con un Container y estilo del tema.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (minute == null) {
      return SizedBox(width: 44, child: const SizedBox.shrink());
    }
    return SizedBox(
      width: 44,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            "${minute!}'",
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge(this.points);

  final double? points;

  @override
  Widget build(BuildContext context) {
    if (points == null || points == 0.0) return const SizedBox.shrink();
    final isPositive = points! > 0;
    final label = (points! > 0 ? '+' : '') + points!.toStringAsFixed(1);
    final bg = isPositive ? Colors.green.shade300 : Colors.red.shade300;
    final fg = isPositive ? Colors.white : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: bg.withOpacity(0.15), blurRadius: 4)],
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class MatchStatusChangeItem extends StatelessWidget {
  /// Crea el item de cambio de estado o accion legacy.
  const MatchStatusChangeItem({
    super.key,
    required this.label,
    this.minute,
    this.labelWidget,
    this.pointsDelta,
  });

  final String label;
  final int? minute;

  /// Si no es null, sustituye al [Text] central (p. ej. nombre en negrita + nota).
  final Widget? labelWidget;

  /// Puntos asociados a este evento (positivos o negativos). Se muestra arriba
  /// si es positivo y abajo si es negativo.
  final double? pointsDelta;

  /// Construye el item con linea y etiqueta central.
  /// Muestra `pointsDelta` arriba (positivo) o abajo (negativo).
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lower = label.toLowerCase();
    Color? accent;

    if (lower.contains('buen ') ||
        lower.contains('buena ') ||
        lower.contains('good pass') ||
        lower.contains('good play') ||
        lower.contains('pase clave') ||
        lower.contains('key pass') ||
        lower.contains('gana posesión') ||
        lower.contains('gana posicion') ||
        lower.contains('recupera posesión') ||
        lower.contains('recupera posesion') ||
        lower.contains('recuperación') ||
        lower.contains('recuperacion') ||
        lower.contains('ball recovered') ||
        lower.contains('jugada clave') ||
        lower.contains('buena parada') ||
        lower.contains('increíble parada') ||
        lower.contains('increible parada') ||
        lower.contains('great save')) {
      accent = scheme.tertiary;
    }

    if (lower.contains('mal ') ||
        lower.contains('mala ') ||
        lower.contains('pase impreciso') ||
        lower.contains('poor pass') ||
        lower.contains('jugada imprecisa') ||
        lower.contains('poor play') ||
        lower.contains('pierde ') ||
        lower.contains('gol concedido') ||
        lower.contains('gol en propia') ||
        lower.contains('autogol') ||
        lower.contains('own goal')) {
      accent = scheme.error;
    }

    final textStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: accent ?? scheme.onSurface,
    );

    final topBadge = (pointsDelta != null && pointsDelta! > 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    final bottomBadge = (pointsDelta != null && pointsDelta! < 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBadge,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MinuteBadge(minute: minute),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child:
                          labelWidget ??
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: textStyle,
                            softWrap: true,
                          ),
                    ),
                    Expanded(
                      child: Divider(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomBadge,
        ],
      ),
    );
  }
}

class MatchSubstitutionItem extends StatelessWidget {
  /// Crea el item de sustitucion con jugador que entra y sale.
  const MatchSubstitutionItem({
    super.key,
    required this.minute,
    required this.inPlayer,
    required this.outPlayer,
    this.inFallbackId,
    this.outFallbackId,
    this.pointsDelta,
  });

  final int minute;
  final Player? inPlayer;
  final Player? outPlayer;
  final int? inFallbackId;
  final int? outFallbackId;
  final double? pointsDelta;

  /// Construye el item de sustitucion con nombres y flechas.
  /// Lo hace resolviendo nombres o ids de respaldo.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nameStyle = textTheme.bodyMedium;
    final l10n = AppLocalizations.of(context)!;

    // Construye el nombre lateral con estilo y fallback.
    Widget sideName(
      Player? p,
      int? id, {
      required TextAlign align,
      Color? color,
    }) {
      final s = color != null ? nameStyle?.copyWith(color: color) : nameStyle;
      if (p != null) {
        return PlayerDorsalNameText(player: p, style: s, textAlign: align);
      }
      final t = id != null ? l10n.matchUnknownPlayerId(id) : '—';
      return Text(
        t,
        textAlign: align,
        style: s?.copyWith(fontWeight: FontWeight.w600),
      );
    }

    final topBadge = (pointsDelta != null && pointsDelta! > 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    final bottomBadge = (pointsDelta != null && pointsDelta! < 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBadge,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MinuteBadge(minute: minute),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: sideName(
                          inPlayer,
                          inFallbackId,
                          align: TextAlign.left,
                          color: scheme.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: 20,
                          color: scheme.outline,
                        ),
                      ),
                      Expanded(
                        child: sideName(
                          outPlayer,
                          outFallbackId,
                          align: TextAlign.right,
                          color: scheme.error,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomBadge,
        ],
      ),
    );
  }
}

class MatchCardItem extends StatelessWidget {
  /// Crea el item de tarjeta amarilla o roja.
  const MatchCardItem({
    super.key,
    required this.minute,
    required this.player,
    this.fallbackPlayerId,
    required this.isRed,
    this.pointsDelta,
  });

  final int minute;
  final Player? player;
  final int? fallbackPlayerId;
  final bool isRed;
  final double? pointsDelta;

  /// Construye el item con color y nombre del jugador.
  /// Lo hace variando estilos segun el tipo de tarjeta.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    const amberCard = Color(0xFFFFC107);
    final Color cardChipColor = isRed ? scheme.error : amberCard;
    final Color panelBg = isRed
        ? scheme.errorContainer.withValues(alpha: 0.42)
        : const Color(0xFFFFF8E1);
    final Color panelBorder = isRed
        ? scheme.error.withValues(alpha: 0.55)
        : amberCard.withValues(alpha: 0.75);
    final String label = isRed
        ? l10n.matchActionLabelRedCard
        : l10n.matchActionLabelYellowCard;
    final Color textColor = isRed ? scheme.error : const Color(0xFF5D4000);

    final topBadge = (pointsDelta != null && pointsDelta! > 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    final bottomBadge = (pointsDelta != null && pointsDelta! < 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBadge,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MinuteBadge(minute: minute),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: panelBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 14,
                        height: 20,
                        decoration: BoxDecoration(
                          color: cardChipColor,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isRed
                                ? scheme.onError.withValues(alpha: 0.35)
                                : Colors.black26,
                            width: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$label: ',
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              if (player != null)
                                ...playerDorsalNameSpanList(
                                  player!,
                                  textTheme.bodyMedium!.copyWith(
                                    color: textColor,
                                  ),
                                )
                              else
                                TextSpan(
                                  text: fallbackPlayerId != null
                                      ? l10n.matchUnknownPlayerId(
                                          fallbackPlayerId!,
                                        )
                                      : '—',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                            ],
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomBadge,
        ],
      ),
    );
  }
}

class MatchGoalItem extends StatelessWidget {
  /// Crea el item de gol para el timeline.
  const MatchGoalItem({
    super.key,
    required this.minute,
    required this.isOurGoal,
    required this.isAgainstGoal,
    this.isOwnGoal = false,
    this.scorerPlayer,
    this.assistPlayer,
    this.pointsDelta,
  });

  final int minute;
  final bool isOurGoal;
  final bool isAgainstGoal;

  /// [true] si el gol es en propia puerta (distinto de un gol encajado del rival).
  final bool isOwnGoal;
  final Player? scorerPlayer;
  final Player? assistPlayer;
  final double? pointsDelta;

  /// Construye el item de gol con estilos segun tipo.
  /// Lo hace mostrando goleador/asis. o chip de rival.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    if (isOurGoal && scorerPlayer != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MinuteBadge(minute: minute),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        size: 22,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PlayerDorsalNameText(
                        player: scorerPlayer!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (pointsDelta != null && pointsDelta! != 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: _PointsBadge(pointsDelta),
                      ),
                    if (assistPlayer != null) ...[
                      Icon(
                        Icons.directions_run_rounded,
                        size: 20,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: PlayerDorsalNameText(
                          player: assistPlayer!,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final chipBg = isOurGoal ? scheme.primary : scheme.error;
    final chipFg = isOurGoal ? scheme.onPrimary : scheme.onError;

    final topBadge = (pointsDelta != null && pointsDelta! > 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    final bottomBadge = (pointsDelta != null && pointsDelta! < 0)
        ? Row(
            children: [
              const SizedBox(width: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PointsBadge(pointsDelta),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBadge,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MinuteBadge(minute: minute),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: isOurGoal
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: chipBg.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isOurGoal
                          ? l10n.matchStatsOurGoalChip
                          : (isOwnGoal
                                ? l10n.matchStatsOwnGoalChip
                                : l10n.matchLiveConcededDefault),
                      style: textTheme.labelLarge?.copyWith(
                        color: chipFg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomBadge,
        ],
      ),
    );
  }
}
