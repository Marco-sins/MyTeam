import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';

/// Tipos de acciones que se pueden registrar para un jugador
/// desde el gestor de partido.
enum MatchPlayerActionType {
  goal,
  goodPass,
  goodPlay,
  goodSave,
  shot,
  ballRecovery,
  yellowCard,
  redCard,
  badPass,
  badPlay,
  foul,
  offside,
  cantada,
}

class MatchPlayerActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  /// Crea un boton de accion con estilo y color opcional.
  const MatchPlayerActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.textColor,
  });

  /// Construye el boton con alineacion a la izquierda.
  /// Lo hace con ElevatedButton y padding.
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

/// Muestra un modal con acciones disponibles para el jugador.
/// Lo hace con un Dialog y devuelve la accion seleccionada.
Future<MatchPlayerActionType?> showMatchPlayerActionModal(
  BuildContext context,
  Player player,
) {
  return showDialog<MatchPlayerActionType>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620, minWidth: 280),
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
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.dialogClose,
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
                        label: l10n.matchActionLabelGoal,
                        textColor: Colors.green,
                        onTap: () =>
                            Navigator.of(ctx).pop(MatchPlayerActionType.goal),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelGoodPass,
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.goodPass),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelGoodPlay,
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.goodPlay),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelGoodSave,
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.goodSave),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelShot,
                        textColor: Colors.green,
                        onTap: () =>
                            Navigator.of(ctx).pop(MatchPlayerActionType.shot),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelBallRecovery,
                        textColor: Colors.green,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.ballRecovery),
                      ),
                      const SizedBox(height: 8),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelYellowCard,
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.yellowCard),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelRedCard,
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.redCard),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelBadPass,
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.badPass),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelBadPlay,
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.badPlay),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelFoul,
                        textColor: Colors.red,
                        onTap: () =>
                            Navigator.of(ctx).pop(MatchPlayerActionType.foul),
                      ),
                      MatchPlayerActionButton(
                        label: 'Fuera de juego',
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.offside),
                      ),
                      MatchPlayerActionButton(
                        label: l10n.matchActionLabelCantada,
                        textColor: Colors.red,
                        onTap: () => Navigator.of(
                          ctx,
                        ).pop(MatchPlayerActionType.cantada),
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
