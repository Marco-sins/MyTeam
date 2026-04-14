import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/team.dart';

class AttendanceHeader extends StatelessWidget {
  final Team team;

  const AttendanceHeader({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.fact_check_rounded,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      team.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        scheme.secondaryContainer.withValues(alpha: 0.65),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
