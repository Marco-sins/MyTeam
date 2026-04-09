import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/attendance/attendance_status.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              player.number?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(player.fullName, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Center(
              child: AttendanceStatusOptionChip(
                label: 'A',
                selectedColor: Theme.of(context).colorScheme.primary,
                isSelected: currentStatus == AttendanceStatus.present,
                onTap: onMarkPresent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Center(
              child: AttendanceStatusOptionChip(
                label: 'X',
                selectedColor: Colors.red,
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
