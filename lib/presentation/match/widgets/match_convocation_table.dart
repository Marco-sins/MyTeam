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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (convokedPlayers.isEmpty) {
      return const Center(
        child: Text('No hay jugadores convocados para este partido'),
      );
    }

    final listView = ListView.separated(
      shrinkWrap: scrollingChild,
      physics: scrollingChild ? const ClampingScrollPhysics() : null,
      itemCount: convokedPlayers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final player = convokedPlayers[index];
        final dorsal = player.number?.toString() ?? '-';
        final name = player.firstName;
        final lastName = player.lastName ?? '';
        final display = lastName.isNotEmpty
            ? '$dorsal  $name $lastName,'
            : '$dorsal  $name,';

        final assignedIndex = positionPlayers.indexWhere(
          (p) => p != null && p.id == player.id,
        );
        final isAssigned = assignedIndex != -1;

        final isSelected = selectedPlayer?.id == player.id;
        final isSentOff = sentOffPlayerIds.contains(player.id);

        final tile = ListTile(
          title: Text(display),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!readOnly) _buildRatingCircle(player),
              if (isAssigned) const Icon(Icons.check, color: Colors.green),
              if (isSentOff)
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.block, color: Colors.red),
                ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.person_outline, color: Colors.orange),
                ),
            ],
          ),
          onTap: () => onPlayerTap(player, isSentOff),
        );

        if (isSentOff || readOnly) {
          // No permitimos arrastrar jugadores expulsados.
          return tile;
        }

        return LongPressDraggable<Player>(
          data: player,
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Opacity(opacity: 0.9, child: tile),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: tile),
          child: tile,
        );
      },
    );

    return listView;
  }

  Widget _buildRatingCircle(Player player) {
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }

  Color _ratingColor(double rating) {
    final value = rating.clamp(0.0, 10.0);
    if (value <= 5.0) {
      final t = value / 5.0;
      return Color.lerp(Colors.red, Colors.yellow, t)!;
    } else {
      final t = (value - 5.0) / 5.0;
      return Color.lerp(Colors.yellow, Colors.blue, t)!;
    }
  }
}
