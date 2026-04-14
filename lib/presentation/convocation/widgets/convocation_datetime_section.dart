import 'package:flutter/material.dart';

class ConvocationDateTimeSection extends StatelessWidget {
  final String formattedDate;
  final String formattedMatchTime;
  final String formattedCallTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickMatchTime;
  final VoidCallback onPickCallTime;

  const ConvocationDateTimeSection({
    super.key,
    required this.formattedDate,
    required this.formattedMatchTime,
    required this.formattedCallTime,
    required this.onPickDate,
    required this.onPickMatchTime,
    required this.onPickCallTime,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget timeRow({
      required IconData icon,
      required String label,
      required String value,
      required VoidCallback onPick,
      required IconData pickIcon,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onPick,
              icon: Icon(pickIcon, size: 20),
              tooltip: 'Cambiar',
            ),
          ],
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event, size: 22, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Fecha y horarios',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 22, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                    tooltip: 'Elegir fecha',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            timeRow(
              icon: Icons.sports_soccer,
              label: 'Hora del partido',
              value: formattedMatchTime,
              onPick: onPickMatchTime,
              pickIcon: Icons.schedule,
            ),
            const SizedBox(height: 10),
            timeRow(
              icon: Icons.groups,
              label: 'Hora de convocatoria',
              value: formattedCallTime,
              onPick: onPickCallTime,
              pickIcon: Icons.alarm,
            ),
          ],
        ),
      ),
    );
  }
}
