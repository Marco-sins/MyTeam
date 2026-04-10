import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';

class MatchLineupSection extends StatelessWidget {
  const MatchLineupSection({
    super.key,
    required this.startingPlayers,
    required this.substitutePlayers,
    required this.playerRatings,
    required this.onPlayerTap,
    this.showRatings = true,
  });

  final List<Player> startingPlayers;
  final List<Player> substitutePlayers;
  final Map<int, double> playerRatings;
  final void Function(Player) onPlayerTap;
  final bool showRatings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          const Text(
            'Plantilla del partido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (startingPlayers.isNotEmpty) ...[
            const Text(
              'Titulares',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final p in startingPlayers)
              _MatchLineupPlayerRow(
                player: p,
                label: 'Titular',
                rating: playerRatings[p.id],
                showRating: showRatings,
                onTap: () => onPlayerTap(p),
              ),
            const SizedBox(height: 12),
          ],
          if (substitutePlayers.isNotEmpty) ...[
            const Text(
              'Suplentes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final p in substitutePlayers)
              _MatchLineupPlayerRow(
                player: p,
                label: 'Suplente',
                rating: playerRatings[p.id],
                showRating: showRatings,
                onTap: () => onPlayerTap(p),
              ),
          ],
        ],
      ),
    );
  }
}

class _MatchLineupPlayerRow extends StatelessWidget {
  const _MatchLineupPlayerRow({
    required this.player,
    required this.label,
    required this.onTap,
    this.rating,
    this.showRating = true,
  });

  final Player player;
  final String label;
  final VoidCallback onTap;
  final double? rating;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    final value = (rating ?? 5.0).clamp(0.0, 10.0);

    Color ratingColor(double v) {
      if (v <= 5.0) {
        final t = v / 5.0;
        return Color.lerp(Colors.red, Colors.yellow, t)!;
      } else {
        final t = (v - 5.0) / 5.0;
        return Color.lerp(Colors.yellow, Colors.blue, t)!;
      }
    }

    final color = ratingColor(value.toDouble());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                player.number?.toString() ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                player.fullName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            if (showRating)
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                alignment: Alignment.center,
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: label == 'Titular'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blueGrey.withOpacity(0.1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: label == 'Titular'
                      ? Colors.green[800]
                      : Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
