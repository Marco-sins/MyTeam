import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/presentation/common/loading_cubit.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<LoadingCubit, bool>(
              builder: (context, isLoading) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: isLoading ? null : onSave,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
