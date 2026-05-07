import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';

/// Tabla de convocatoria con estado de asignacion y rating.
/// Renderiza lista o columna segun el modo de scroll.
class MatchConvocationTable extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Player> convokedPlayers;
  final List<Player?> positionPlayers;
  final Player? selectedPlayer;
  final Set<int> sentOffPlayerIds;
  final Set<int> yellowCardPlayerIds;
  final Map<int, double> playerRatings;

  /// Minutos disputados por [Player.id] (solo gestores; null = no mostrar).
  final Map<int, int>? minutesPlayedByPlayerId;

  /// Si es true, no se usa [ListView] interno: el padre aporta el scroll.
  final bool scrollingChild;
  final void Function(Player player, bool isSentOff) onPlayerTap;
  final bool readOnly;

  /// Crea la tabla con datos de convocatoria y handlers.
  const MatchConvocationTable({
    super.key,
    required this.loading,
    required this.error,
    required this.convokedPlayers,
    required this.positionPlayers,
    required this.selectedPlayer,
    required this.sentOffPlayerIds,
    required this.yellowCardPlayerIds,
    required this.playerRatings,
    this.minutesPlayedByPlayerId,
    this.scrollingChild = false,
    this.readOnly = false,
    required this.onPlayerTap,
  });

  /// Construye la tabla con estados de carga, error o lista.
  /// Lo hace eligiendo entre columna o ListView.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(child: Text(error!, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    if (convokedPlayers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Text(
          l10n.matchConvocationTableEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (scrollingChild) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < convokedPlayers.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            _buildPlayerRow(context, convokedPlayers[index]),
          ],
        ],
      );
    }

    return ListView.separated(
      itemCount: convokedPlayers.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
      itemBuilder: (context, index) =>
          _buildPlayerRow(context, convokedPlayers[index]),
    );
  }

  /// Construye una fila de jugador con indicadores y acciones.
  /// Lo hace calculando estado asignado/expulsado/seleccionado.
  Widget _buildPlayerRow(BuildContext context, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dorsal = player.number?.toString() ?? '-';
    final assignedIndex = positionPlayers.indexWhere(
      (p) => p != null && p.id == player.id,
    );
    final isAssigned = assignedIndex != -1;
    final isSelected = selectedPlayer?.id == player.id;
    final isSentOff = sentOffPlayerIds.contains(player.id);
    final hasYellow = yellowCardPlayerIds.contains(player.id);
    final minutesPlayed = minutesPlayedByPlayerId?[player.id];
    final rating = playerRatings[player.id] ?? 5.0;
    final rowBg = isSentOff
        ? scheme.errorContainer.withValues(alpha: 0.4)
        : hasYellow
        ? Colors.amber.withValues(alpha: 0.25)
        : null;
    final rowRadius = BorderRadius.circular(12);
    final circleBorder = scheme.outlineVariant.withValues(alpha: 0.6);
    final circleFill = isSentOff
        ? scheme.error
        : hasYellow
        ? Colors.amber
        : isAssigned
        ? scheme.primary
        : Colors.transparent;
    final showTick = isAssigned && !isSentOff && !hasYellow;
    final tickColor = scheme.onPrimary;

    Color ratingColor(double value) {
      if (value <= 5.0) {
        final t = value / 5.0;
        return Color.lerp(Colors.red, Colors.yellow, t)!;
      }
      final t = (value - 5.0) / 5.0;
      return Color.lerp(Colors.yellow, Colors.blue, t)!;
    }

    final row = Container(
      decoration: BoxDecoration(color: rowBg, borderRadius: rowRadius),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: scheme.surfaceContainerHigh,
              foregroundColor: scheme.onSurface,
              child: Text(
                dorsal,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PlayerNameText(
              player: player,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (minutesPlayed != null)
                  Tooltip(
                    message: '${l10n.matchStatsMinutesPlayed}: $minutesPlayed',
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        "$minutesPlayed'",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                Tooltip(
                  message: 'Media: ${rating.toStringAsFixed(1)}',
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ratingColor(rating.clamp(0.0, 10.0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                if (!readOnly && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.touch_app,
                      color: scheme.tertiary,
                      size: 20,
                    ),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleFill,
                    border: Border.all(
                      color: isSentOff || hasYellow ? circleFill : circleBorder,
                      width: 2,
                    ),
                  ),
                  child: showTick
                      ? Icon(Icons.check, size: 16, color: tickColor)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (readOnly) {
      return row;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: () => onPlayerTap(player, isSentOff), child: row),
    );
  }
}
