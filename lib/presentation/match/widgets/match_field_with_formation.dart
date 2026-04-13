import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';

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
                child: DragTarget<Player>(
                  onWillAccept: (player) {
                    if (readOnly) return false;
                    if (player == null) return false;
                    if (sentOffPlayerIds.contains(player.id)) {
                      showSnack(
                        'Jugador expulsado, no puede volver a entrar',
                        error: true,
                      );
                      return false;
                    }

                    final existingIndex = positionPlayers.indexWhere(
                      (p) => p != null && p.id == player.id,
                    );

                    if (existingIndex == -1 &&
                        assignedPlayer == null &&
                        currentPlayersOnField() >= maxPlayersOnField()) {
                      showSnack(
                        'No puedes tener más jugadores en el campo. Por cada expulsado debe quedar un hueco libre.',
                        error: true,
                      );
                      return false;
                    }
                    return true;
                  },
                  onAccept: (player) {
                    if (readOnly) return;
                    final existingIndex = positionPlayers.indexWhere(
                      (p) => p != null && p.id == player.id,
                    );
                    final currentAtPos = index < positionPlayers.length
                        ? positionPlayers[index]
                        : null;

                    // Si ya está en esta posición, no hacemos nada.
                    if (existingIndex == index) {
                      return;
                    }

                    final newPositions = List<Player?>.from(positionPlayers);

                    // Si el jugador ya está en el campo y esta posición
                    // también tiene jugador, hacemos intercambio de
                    // posiciones sin registrar sustitución.
                    if (existingIndex != -1 && currentAtPos != null) {
                      newPositions[existingIndex] = currentAtPos;
                      newPositions[index] = player;
                      onPositionsChanged(newPositions);
                      return;
                    }

                    // Si el jugador ya está en el campo y aquí no hay
                    // nadie, simplemente lo movemos.
                    if (existingIndex != -1 && currentAtPos == null) {
                      newPositions[existingIndex] = null;
                      newPositions[index] = player;
                      onPositionsChanged(newPositions);
                      return;
                    }

                    // Jugador desde banquillo: comprobamos otra vez el
                    // máximo permitido por seguridad.
                    if (existingIndex == -1 &&
                        currentAtPos == null &&
                        currentPlayersOnField() >= maxPlayersOnField()) {
                      showSnack(
                        'No puedes tener más jugadores en el campo. Por cada expulsado debe quedar un hueco libre.',
                        error: true,
                      );
                      return;
                    }

                    // Sustitución normal (entra desde banquillo o sin
                    // posición previa y sale el que estaba en esta
                    // posición, si lo hubiera).
                    newPositions[index] = player;
                    onPositionsChanged(newPositions);
                    onSubstitutionRequested(player, currentAtPos);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return GestureDetector(
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

                        // Si el jugador seleccionado ya está en el campo y
                        // la posición destino también tiene jugador, hacemos
                        // un intercambio de posiciones sin registrar
                        // sustitución.
                        final existingIndex = positionPlayers.indexWhere(
                          (p) => p != null && p.id == selectedPlayer!.id,
                        );

                        final newPositions = List<Player?>.from(
                          positionPlayers,
                        );

                        if (existingIndex != -1 && assignedPlayer != null) {
                          newPositions[existingIndex] = assignedPlayer;
                          newPositions[index] = selectedPlayer;
                          onPositionsChanged(newPositions);
                          return;
                        }

                        // Si el jugador seleccionado no está en el campo y
                        // en esta posición no hay nadie, comprobar que no
                        // superamos el máximo permitido según expulsiones.
                        if (existingIndex == -1 &&
                            assignedPlayer == null &&
                            currentPlayersOnField() >= maxPlayersOnField()) {
                          showSnack(
                            'No puedes tener más jugadores en el campo. Por cada expulsado debe quedar un hueco libre.',
                            error: true,
                          );
                          return;
                        }

                        // Sustitución normal: entra jugador (desde banquillo
                        // o sin posición previa) y sale el que estaba en
                        // esta posición.
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
                            ? Colors.greenAccent
                            : Colors.white.withAlpha((0.85 * 255).round()),
                        child: Text(
                          displayNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );

            positionNumber++;
          }
        }

        return Stack(children: children);
      },
    );
  }
}
