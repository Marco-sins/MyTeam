import 'package:flutter/material.dart';

/// Marca de minuto alineada con el tema de la app.
class _MinuteBadge extends StatelessWidget {
  const _MinuteBadge({this.minute});

  final int? minute;

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

class MatchStatusChangeItem extends StatelessWidget {
  const MatchStatusChangeItem({super.key, required this.label, this.minute});

  final String label;
  final int? minute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lower = label.toLowerCase();
    Color? accent;

    if (lower.contains('buen ') ||
        lower.contains('buena ') ||
        lower.contains('pase clave') ||
        lower.contains('gana posesión') ||
        lower.contains('gana posicion') ||
        lower.contains('recupera posesión') ||
        lower.contains('recupera posesion') ||
        lower.contains('jugada clave') ||
        lower.contains('buena parada') ||
        lower.contains('increíble parada') ||
        lower.contains('increible parada')) {
      accent = scheme.tertiary;
    }

    if (lower.contains('mal ') ||
        lower.contains('mala ') ||
        lower.contains('pierde ') ||
        lower.contains('gol concedido') ||
        lower.contains('gol en propia')) {
      accent = scheme.error;
    }

    final textStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: accent ?? scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MinuteBadge(minute: minute),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.5))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchSubstitutionItem extends StatelessWidget {
  const MatchSubstitutionItem({
    super.key,
    required this.minute,
    required this.inName,
    required this.outName,
  });

  final int minute;
  final String inName;
  final String outName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MinuteBadge(minute: minute),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      inName,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
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
                    child: Text(
                      outName,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_upward_rounded, size: 18, color: scheme.error),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchCardItem extends StatelessWidget {
  const MatchCardItem({
    super.key,
    required this.minute,
    required this.playerName,
    required this.isRed,
  });

  final int minute;
  final String playerName;
  final bool isRed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Color cardColor =
        isRed ? scheme.error : scheme.secondary;
    final String label = isRed ? 'Tarjeta roja' : 'Tarjeta amarilla';
    final Color textColor =
        isRed ? scheme.error : scheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MinuteBadge(minute: minute),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 20,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.35),
                        width: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$label · $playerName',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
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

class MatchGoalItem extends StatelessWidget {
  const MatchGoalItem({
    super.key,
    required this.minute,
    required this.isOurGoal,
    required this.isAgainstGoal,
    this.scorerName,
    this.assistName,
  });

  final int minute;
  final bool isOurGoal;
  final bool isAgainstGoal;
  final String? scorerName;
  final String? assistName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isOurGoal && scorerName != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MinuteBadge(minute: minute),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sports_soccer_rounded, size: 22, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scorerName!,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (assistName != null) ...[
                      Icon(Icons.directions_run_rounded, size: 20, color: scheme.tertiary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          assistName!,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onTertiaryContainer,
                          ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MinuteBadge(minute: minute),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment:
                  isOurGoal ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  isOurGoal ? 'Gol a favor' : 'Gol encajado',
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
    );
  }
}
