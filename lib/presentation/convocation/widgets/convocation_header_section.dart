import 'package:flutter/material.dart';

class ConvocationHeaderSection extends StatelessWidget {
  final TextEditingController rivalController;
  final TextEditingController awayLocationController;
  final bool isHome;
  final ValueChanged<bool> onHomeAwayChanged;

  const ConvocationHeaderSection({
    super.key,
    required this.rivalController,
    required this.awayLocationController,
    required this.isHome,
    required this.onHomeAwayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer, size: 22, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Partido',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: rivalController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Rival',
                prefixIcon: const Icon(Icons.groups_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sede',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Theme(
              data: theme.copyWith(
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
                    maximumSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    side: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return BorderSide(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant.withValues(alpha: 0.55),
                        width: selected ? 1.25 : 1,
                      );
                    }),
                  ),
                ),
              ),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(
                      'Casa',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded, size: 17),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(
                      'Fuera',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    icon: const Icon(Icons.flight_takeoff_rounded, size: 17),
                  ),
                ],
                selected: {isHome},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  onHomeAwayChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: awayLocationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Lugar (opcional)',
                hintText: 'Pabellón o dirección · aparece en la imagen',
                prefixIcon: const Icon(Icons.place_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
