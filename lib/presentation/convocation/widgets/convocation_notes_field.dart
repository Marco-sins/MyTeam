import 'package:flutter/material.dart';

class ConvocationNotesField extends StatelessWidget {
  final TextEditingController notesController;

  const ConvocationNotesField({super.key, required this.notesController});

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
                Icon(Icons.notes, size: 22, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Observaciones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Material, puntualidad, mensaje al grupo…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
