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
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Casa'),
                  icon: Icon(Icons.home_outlined),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Fuera'),
                  icon: Icon(Icons.flight_takeoff),
                ),
              ],
              selected: {isHome},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                onHomeAwayChanged(selection.first);
              },
            ),
            if (!isHome) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: awayLocationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Pabellón o dirección (opcional)',
                  hintText: 'Aparecerá en la imagen de convocatoria',
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
          ],
        ),
      ),
    );
  }
}
