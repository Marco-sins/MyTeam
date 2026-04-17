import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';

/// Tipos de acciones que se pueden registrar para un jugador
/// desde el gestor de partido.
enum MatchPlayerActionType {
  goal,
  goodPass,
  goodPlay,
  ballRecovery,
  yellowCard,
  redCard,
  badPass,
  badPlay,
}

class MatchPlayerActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  const MatchPlayerActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(color: textColor)),
        ),
      ),
    );
  }
}

Future<MatchPlayerActionType?> showMatchPlayerActionModal(
  BuildContext context,
  Player player,
) {
  return showDialog<MatchPlayerActionType>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, minWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PlayerNameText(
                        player: player,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      MatchPlayerActionButton(
                        label: 'Gol',
                        textColor: Colors.green,
                        onTap: () =>
                            Navigator.of(ctx).pop(MatchPlayerActionType.goal),
                      ),
                      MatchPlayerActionButton(
                        label: 'Buen pase',
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.goodPass),
                      ),
                      MatchPlayerActionButton(
                        label: 'Buena jugada',
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.goodPlay),
                      ),
                      MatchPlayerActionButton(
                        label: 'Balón recuperado',
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.ballRecovery),
                      ),
                      const SizedBox(height: 8),
                      MatchPlayerActionButton(
                        label: 'Tarjeta amarilla',
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.yellowCard),
                      ),
                      MatchPlayerActionButton(
                        label: 'Tarjeta roja',
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.redCard),
                      ),
                      MatchPlayerActionButton(
                        label: 'Pase impreciso',
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.badPass),
                      ),
                      MatchPlayerActionButton(
                        label: 'Jugada imprecisa',
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.badPlay),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
