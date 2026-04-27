import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: scheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                l10n.matchLineupSquadTitle,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (startingPlayers.isNotEmpty) ...[
            Text(
              l10n.matchLineupStarters,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (final p in startingPlayers)
              _MatchLineupPlayerRow(
                player: p,
                label: l10n.matchLineupStarterTag,
                isStarter: true,
                rating: playerRatings[p.id],
                showRating: showRatings,
                onTap: () => onPlayerTap(p),
              ),
            const SizedBox(height: 12),
          ],
          if (substitutePlayers.isNotEmpty) ...[
            Text(
              l10n.matchLineupSubstitutes,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (final p in substitutePlayers)
              _MatchLineupPlayerRow(
                player: p,
                label: l10n.matchLineupSubstituteTag,
                isStarter: false,
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
    required this.isStarter,
    required this.onTap,
    this.rating,
    this.showRating = true,
  });

  final Player player;
  final String label;
  final bool isStarter;
  final VoidCallback onTap;
  final double? rating;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  player.number?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PlayerNameText(
                  player: player,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              if (showRating)
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
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
                  color: isStarter
                      ? scheme.primaryContainer.withValues(alpha: 0.85)
                      : scheme.secondaryContainer.withValues(alpha: 0.65),
                ),
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isStarter
                        ? scheme.onPrimaryContainer
                        : scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
