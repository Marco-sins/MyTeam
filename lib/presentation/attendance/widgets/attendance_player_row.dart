import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/attendance/models/attendance_status.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_status_option_chip.dart';

class AttendancePlayerRow extends StatelessWidget {
  final Player player;
  final AttendanceStatus currentStatus;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkAbsent;

  const AttendancePlayerRow({
    super.key,
    required this.player,
    required this.currentStatus,
    required this.onMarkPresent,
    required this.onMarkAbsent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    /// Ancho mínimo del diseño (dorsal + huecos + chips); si el padre es más
    /// estrecho, [FittedBox] escala todo sin overflow horizontal.
    const minRowLayoutWidth = 268.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = math.max(
            constraints.maxWidth,
            minRowLayoutWidth,
          );
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: targetWidth,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      player.number?.toString() ?? '–',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PlayerNameText(
                      player: player,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: AttendanceStatusOptionChip(
                        isSelected:
                            currentStatus == AttendanceStatus.present,
                        onTap: onMarkPresent,
                        selectedColor: scheme.primary,
                        child: const Icon(Icons.check_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: AttendanceStatusOptionChip(
                        isSelected:
                            currentStatus == AttendanceStatus.absent,
                        onTap: onMarkAbsent,
                        selectedColor: scheme.error,
                        child: const Text('X'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
