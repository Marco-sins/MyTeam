import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.surfaceContainerHigh,
            child: Text(
              player.number?.toString() ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.fullName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Center(
              child: AttendanceStatusOptionChip(
                label: 'A',
                selectedColor: scheme.primary,
                isSelected: currentStatus == AttendanceStatus.present,
                onTap: onMarkPresent,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 56,
            child: Center(
              child: AttendanceStatusOptionChip(
                label: 'X',
                selectedColor: scheme.error,
                isSelected: currentStatus == AttendanceStatus.absent,
                onTap: onMarkAbsent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
