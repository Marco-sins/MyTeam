import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';

class ConvocationActionsRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ConvocationActionsRow({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.65)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<LoadingCubit, bool>(
            builder: (context, isLoading) {
              return FilledButton(
                onPressed: isLoading ? null : onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Guardar'),
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}
