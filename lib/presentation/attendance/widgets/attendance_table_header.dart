import 'package:flutter/material.dart';

class AttendanceTableHeader extends StatelessWidget {
  const AttendanceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
          fontSize: 12,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#', textAlign: TextAlign.center, style: labelStyle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Jugador', style: labelStyle)),
          SizedBox(
            width: 56,
            child: Text(
              'Asiste',
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 56,
            child: Text(
              'Falta',
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}
