import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';

class MatchConvocationTable extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Player> convokedPlayers;
  final List<Player?> positionPlayers;
  final Player? selectedPlayer;
  final Set<int> sentOffPlayerIds;
  final Map<int, double> playerRatings;

  /// Si es true, no se usa [ListView] interno: el padre aporta el scroll.
  final bool scrollingChild;
  final void Function(Player player, bool isSentOff) onPlayerTap;
  final bool readOnly;

  const MatchConvocationTable({
    super.key,
    required this.loading,
    required this.error,
    required this.convokedPlayers,
    required this.positionPlayers,
    required this.selectedPlayer,
    required this.sentOffPlayerIds,
    required this.playerRatings,
    this.scrollingChild = false,
    this.readOnly = false,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: scheme.primary),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (convokedPlayers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Text(
          'No hay jugadores convocados para este partido',
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
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.35),
      ),
      itemBuilder: (context, index) =>
          _buildPlayerRow(context, convokedPlayers[index]),
    );
  }

  Widget _buildPlayerRow(BuildContext context, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final dorsal = player.number?.toString() ?? '-';
    final name = player.firstName;
    final lastName = player.lastName ?? '';
    final displayName = lastName.isNotEmpty ? '$name $lastName' : name;

    final assignedIndex = positionPlayers.indexWhere(
      (p) => p != null && p.id == player.id,
    );
    final isAssigned = assignedIndex != -1;
    final isSelected = selectedPlayer?.id == player.id;
    final isSentOff = sentOffPlayerIds.contains(player.id);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!readOnly) _buildRatingCircle(context, player),
              if (isAssigned)
                Icon(Icons.check_circle, color: scheme.primary, size: 22),
              if (isSentOff)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.block, color: scheme.error, size: 22),
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
        ],
      ),
    );

    if (readOnly) {
      return row;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onPlayerTap(player, isSentOff),
        child: row,
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
