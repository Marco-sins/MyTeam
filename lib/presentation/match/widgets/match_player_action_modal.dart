import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/data/team_scoring_config_storage.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team_scoring_config.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/match/utils/team_scoring_line_match_save.dart';
import 'package:football_manager/presentation/team/utils/team_scoring_builtin_label.dart';

String _lineButtonTitle(AppLocalizations l10n, TeamScoringLine line) {
  if (line.isCustom) {
    final n = line.name?.trim();
    if (n == null || n.isEmpty) {
      return l10n.teamScoringUnnamed;
    }
    return n;
  }
  return teamScoringBuiltinTitle(l10n, line.id);
}

/// Acciones posibles según la valoración guardada del equipo ([teamId]).
Future<MatchPlayerScoringSelection?> showMatchPlayerActionModal(
  BuildContext context,
  Player player, {
  required int teamId,
}) {
  return showDialog<MatchPlayerScoringSelection>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final storage = ctx.read<TeamScoringConfigStorage>();
      final saved = storage.load(teamId);
      var lines = saved?.lines ?? TeamScoringConfig.defaultBuiltInLines();
      if (lines.isEmpty) {
        lines = TeamScoringConfig.defaultBuiltInLines();
      }
      final config = TeamScoringConfig(lines: lines);
      final rows = sortedScoringLinesForPlayerModal(
        scoringLinesForPlayerActionList(
          List<TeamScoringLine>.from(config.lines),
        ),
      );

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620, minWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PlayerNameText(
                        player: player,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.dialogClose,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ...rows.expand((line) {
                      final kind = teamScoringLineToSaveKind(line);
                      if (kind == null) {
                        return <Widget>[];
                      }
                      final label = _lineButtonTitle(l10n, line);
                      final isNeg = scoringLineUsesNegativeColor(line);
                      final textColor = isNeg ? Colors.red : Colors.green;
                      return <Widget>[
                        MatchPlayerActionButton(
                          label: label,
                          textColor: textColor,
                          onTap: () {
                            final sel = MatchPlayerScoringSelection(
                              confirmLabel: label,
                              kind: kind,
                            );
                            Navigator.of(ctx).pop(sel);
                          },
                        ),
                      ];
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class MatchPlayerActionButton extends StatelessWidget {
  const MatchPlayerActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(color: textColor)),
        ),
      ),
    );
  }
}
