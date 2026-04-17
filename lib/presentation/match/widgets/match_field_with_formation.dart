import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';

/// Campo táctil: colocación por **jugador seleccionado en la lista + toque en la posición**.
/// Se evitó [DragTarget]/arrastre desde lista porque en scrollables dispara asserts de
/// semántica (`!semantics.parentDataDirty`) y congela la UI en varias versiones de Flutter.
class MatchFieldWithFormation extends StatelessWidget {
  final List<int> formationLines;
  final List<Player?> positionPlayers;
  final Player? selectedPlayer;
  final Set<int> sentOffPlayerIds;
  final int Function() currentPlayersOnField;
  final int Function() maxPlayersOnField;
  final void Function(String message, {bool error}) showSnack;
  final void Function(List<Player?> newPositions) onPositionsChanged;
  final void Function(Player playerIn, Player? playerOut)
  onSubstitutionRequested;
  final void Function(Player player) onPlayerActionRequested;
  final bool readOnly;

  const MatchFieldWithFormation({
    super.key,
    required this.formationLines,
    required this.positionPlayers,
    required this.selectedPlayer,
    required this.sentOffPlayerIds,
    required this.currentPlayersOnField,
    required this.maxPlayersOnField,
    required this.showSnack,
    required this.onPositionsChanged,
    required this.onSubstitutionRequested,
    required this.onPlayerActionRequested,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        final fieldWidth = constraints.maxWidth;
        final fieldHeight = constraints.maxHeight;
        final rows = formationLines.length;

        final List<Widget> children = [
          Positioned.fill(
            child: Image.asset('media/campo.png', fit: BoxFit.contain),
          ),
        ];

        int positionNumber = 1;
        for (int row = 0; row < rows; row++) {
          // Invertimos las filas para que el portero (primera línea) quede abajo
          final displayRow = rows - 1 - row;
          final countInRow = formationLines[row];
          final top = fieldHeight * ((displayRow + 1) / (rows + 1));

          for (int col = 0; col < countInRow; col++) {
            final left = fieldWidth * ((col + 1) / (countInRow + 1));
            final index = positionNumber - 1;
            final assignedPlayer = index < positionPlayers.length
                ? positionPlayers[index]
                : null;
            final displayNumber = assignedPlayer?.number?.toString() ?? '';

            children.add(
              Positioned(
                left: left - 16,
                top: top - 16,
                child: GestureDetector(
                  onTap: () {
                    if (readOnly) {
                      return;
                    }
                    // Si no hay jugador seleccionado desde la lista y
                    // esta posición tiene jugador en el campo, abrimos
                    // el modal de acciones para ese jugador.
                    if (selectedPlayer == null && assignedPlayer != null) {
                      onPlayerActionRequested(assignedPlayer);
                      return;
                    }

                    if (selectedPlayer == null && assignedPlayer == null) {
                      showSnack(
                        'Selecciona primero un jugador en la lista',
                        error: true,
                      );
                      return;
                    }

                    if (sentOffPlayerIds.contains(selectedPlayer!.id)) {
                      showSnack(
                        'Jugador expulsado, no puede volver a entrar',
                        error: true,
                      );
                      return;
                    }

                    final existingIndex = positionPlayers.indexWhere(
                      (p) => p != null && p.id == selectedPlayer!.id,
                    );

                    // Ya está en esta posición: no hacemos nada.
                    if (existingIndex == index) {
                      return;
                    }

                    final newPositions = List<Player?>.from(
                      positionPlayers,
                    );

                    // Intercambio de posiciones entre dos jugadores en campo.
                    if (existingIndex != -1 && assignedPlayer != null) {
                      newPositions[existingIndex] = assignedPlayer;
                      newPositions[index] = selectedPlayer;
                      onPositionsChanged(newPositions);
                      return;
                    }

                    // Máximo de jugadores en campo según expulsiones.
                    if (existingIndex == -1 &&
                        assignedPlayer == null &&
                        currentPlayersOnField() >= maxPlayersOnField()) {
                      showSnack(
                        l10n.matchFieldMaxPlayersExpulsionRule,
                        error: true,
                      );
                      return;
                    }

                    // Sustitución / entrada: coloca al seleccionado y sale el que había.
                    if (existingIndex != -1) {
                      newPositions[existingIndex] = null;
                    }

                    newPositions[index] = selectedPlayer;
                    onPositionsChanged(newPositions);
                    onSubstitutionRequested(
                      selectedPlayer!,
                      assignedPlayer,
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: assignedPlayer != null
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest
                            .withValues(alpha: 0.92),
                    child: Text(
                      displayNumber,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: assignedPlayer != null
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );

            positionNumber++;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: children,
        );
      },
    );
  }
}
