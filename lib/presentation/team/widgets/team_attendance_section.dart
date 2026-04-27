import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_summary_table.dart';

class TeamAttendanceSection extends StatelessWidget {
  final Team team;
  final List<Player> players;

  /// Admin / superAdmin: muestra columna de foto en la tabla de plantilla.
  final bool showPlayerPhotos;

  const TeamAttendanceSection({
    super.key,
    required this.team,
    required this.players,
    this.showPlayerPhotos = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final titleH = maxH <= 0
            ? 0.0
            : ((maxH * 0.32).clamp(12.0, 44.0)).clamp(0.0, maxH);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titleH > 0)
              SizedBox(
                height: titleH,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        l10n.screenRoster,
                        style: titleStyle,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: AttendanceSummaryTable(
                      team: team,
                      players: players,
                      showPlayerPhotos: showPlayerPhotos,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
