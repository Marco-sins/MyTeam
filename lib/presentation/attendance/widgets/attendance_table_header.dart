import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';

class AttendanceTableHeader extends StatelessWidget {
  const AttendanceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minRowWidth = 280.0;
          final targetW = math.max(constraints.maxWidth, minRowWidth);
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: targetW,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '#',
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tableColumnPlayer,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      l10n.tableColumnAttends,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 56,
                    child: Text(
                      l10n.tableColumnAbsent,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
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
