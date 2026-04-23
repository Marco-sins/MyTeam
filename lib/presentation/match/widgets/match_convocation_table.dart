import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/match/utils/match_player_discipline_highlight.dart';

class MatchConvocationTable extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Player> convokedPlayers;
  final List<Player?> positionPlayers;
  final Player? selectedPlayer;
  final Set<int> sentOffPlayerIds;
  final Map<int, double> playerRatings;

  /// Minutos disputados por [Player.id] (solo gestores; null = no mostrar).
  final Map<int, int>? minutesPlayedByPlayerId;

  /// Si es true, no se usa [ListView] interno: el padre aporta el scroll.
  final bool scrollingChild;
  final void Function(Player player, bool isSentOff) onPlayerTap;
  final bool readOnly;

  /// Fondo / banda de tarjeta (amarilla o roja) en cada fila de la convocatoria.
  final MatchPlayerDisciplineHighlight Function(int playerId) playerDiscipline;

  const MatchConvocationTable({
    super.key,
    required this.loading,
    required this.error,
    required this.convokedPlayers,
    required this.positionPlayers,
    required this.selectedPlayer,
    required this.sentOffPlayerIds,
    required this.playerRatings,
    this.minutesPlayedByPlayerId,
    this.scrollingChild = false,
    this.readOnly = false,
    required this.onPlayerTap,
    required this.playerDiscipline,
  });

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
    final minutesPlayed = minutesPlayedByPlayerId?[player.id];
    final d = playerDiscipline(player.id);

    final row = Padding(
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
                if (!readOnly) _buildRatingCircle(context, player),
                _buildPlayingFieldIndicator(
                  scheme: scheme,
                  isOnField: isAssigned,
                  isSentOff: isSentOff,
                ),
                if (!readOnly && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.touch_app,
                      color: scheme.tertiary,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final isDark = theme.brightness == Brightness.dark;
    final yellowRowFill = Color.alphaBlend(
      const Color(0xFFFFC107).withValues(alpha: isDark ? 0.14 : 0.22),
      scheme.surface,
    );
    final decorated = d == MatchPlayerDisciplineHighlight.none
        ? row
        : DecoratedBox(
            decoration: BoxDecoration(
              color: d == MatchPlayerDisciplineHighlight.red
                  ? scheme.errorContainer.withValues(
                      alpha: isDark ? 0.48 : 0.38,
                    )
                  : yellowRowFill,
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: d == MatchPlayerDisciplineHighlight.red
                      ? intenseDisciplineRed(scheme)
                      : const Color(0xFFF9A825),
                ),
              ),
            ),
            child: row,
          );

    if (readOnly) {
      return decorated;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onPlayerTap(player, isSentOff),
        child: decorated,
      ),
    );
  }

  static const double _kPlayingOnFieldSize = 22;

  /// Expulsado: círculo rojo con [Icons.style] (tarjeta, como en la cronología).
  Widget _buildPlayingFieldIndicator({
    required ColorScheme scheme,
    required bool isOnField,
    required bool isSentOff,
  }) {
    if (isSentOff) {
      return Container(
        width: _kPlayingOnFieldSize,
        height: _kPlayingOnFieldSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: intenseDisciplineRed(scheme),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.style,
          size: 14,
          color: Color(0xFF1A0404),
        ),
      );
    }
    if (isOnField) {
      return Icon(
        Icons.check_circle,
        color: scheme.primary,
        size: _kPlayingOnFieldSize,
      );
    }
    return SizedBox(
      width: _kPlayingOnFieldSize,
      height: _kPlayingOnFieldSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.9),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCircle(BuildContext context, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final rating = playerRatings[player.id] ?? 5.0;
    final color = _ratingColor(rating);
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(
        rating.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  Color _ratingColor(double rating) {
    final value = rating.clamp(0.0, 10.0);
    if (value <= 5.0) {
      final t = value / 5.0;
      return Color.lerp(Colors.red, Colors.amber, t)!;
    } else {
      final t = (value - 5.0) / 5.0;
      return Color.lerp(Colors.amber, Colors.blue, t)!;
    }
  }
}
