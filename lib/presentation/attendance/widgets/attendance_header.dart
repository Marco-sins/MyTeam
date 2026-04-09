import 'package:flutter/material.dart';
import 'package:tfg1/domain/entities/team.dart';

class AttendanceHeader extends StatelessWidget {
  final Team team;

  const AttendanceHeader({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: const Icon(Icons.shield, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 10),
              Text(
                team.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
