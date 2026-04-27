import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            const minW = 280.0;
            final targetW = math.max(constraints.maxWidth, minW);
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: targetW,
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      tooltip: l10n.tooltipChange,
                    ),
                  ],
                ),
              ),
            );
          },
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
                Expanded(
                  child: Text(
                    l10n.convDatetimeSectionTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minW = 280.0;
                  final targetW = math.max(constraints.maxWidth, minW);
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: targetW,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 22,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              formattedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: onPickDate,
                            icon: const Icon(
                              Icons.edit_calendar_outlined,
                              size: 20,
                            ),
                            tooltip: l10n.convPickDateTooltip,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            timeRow(
              icon: Icons.sports_soccer,
              label: l10n.convocationImageLabelMatchTime,
              value: formattedMatchTime,
              onPick: onPickMatchTime,
              pickIcon: Icons.schedule,
            ),
            const SizedBox(height: 10),
            timeRow(
              icon: Icons.groups,
              label: l10n.convocationImageLabelCallTime,
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
