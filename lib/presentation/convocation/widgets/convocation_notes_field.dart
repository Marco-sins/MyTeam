import 'package:flutter/material.dart';

class ConvocationNotesField extends StatelessWidget {
  final TextEditingController notesController;

  const ConvocationNotesField({super.key, required this.notesController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: TextFormField(
        controller: notesController,
        minLines: 2,
        maxLines: null,
        decoration: const InputDecoration(
          labelText: 'Observaciones',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
