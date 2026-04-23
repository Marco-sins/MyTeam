import 'package:flutter/material.dart';
import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/match/utils/match_formation_utils.dart';
import 'package:football_manager/presentation/match/utils/match_player_discipline_highlight.dart';

/// Píxeles de `media/campo.png`. Debe coincidir con el asset para que [_campoContainRect]
/// reproduzca el mismo rectángulo que [BoxFit.contain] sobre la imagen.
const double _kCampoPngWidth = 374;
const double _kCampoPngHeight = 253;

/// Ancho / alto del PNG del campo. El contenedor del tablero usa esta misma relación
/// (misma altura que la imagen dibujada, sin hueco 4:3 artificial).
const double kMatchCampoAspectRatio = _kCampoPngWidth / _kCampoPngHeight;

Rect _campoContainRect(double maxWidth, double maxHeight) {
  if (maxWidth <= 0 || maxHeight <= 0) {
    return Rect.zero;
  }
  final srcAspect = _kCampoPngWidth / _kCampoPngHeight;
  final dstAspect = maxWidth / maxHeight;
  if (srcAspect > dstAspect) {
    final h = maxWidth / srcAspect;
    final top = (maxHeight - h) * 0.5;
    return Rect.fromLTWH(0, top, maxWidth, h);
  }
  final w = maxHeight * srcAspect;
  final left = (maxWidth - w) * 0.5;
  return Rect.fromLTWH(left, 0, w, maxHeight);
}

/// Rectángulo de juego dentro del PNG (marco blanco + líneas; suele haber más aire abajo).
Rect _grassRectFromFieldPaint(Rect fieldPaint) {
  if (fieldPaint.width <= 0 || fieldPaint.height <= 0) {
    return fieldPaint;
  }
  const insetL = 0.045;
  const insetR = 0.045;
  const insetT = 0.055;
  const insetB = 0.078;
  return Rect.fromLTWH(
    fieldPaint.left + fieldPaint.width * insetL,
    fieldPaint.top + fieldPaint.height * insetT,
    fieldPaint.width * (1 - insetL - insetR),
    fieldPaint.height * (1 - insetT - insetB),
  );
}

/// [nx],[ny] ∈ [0,1] dentro del césped útil (0 arriba = ataque, 1 abajo = portería).
double _grassX(Rect grass, double nx) {
  return grass.left + grass.width * nx.clamp(0.0, 1.0);
}

double _grassY(Rect grass, double ny) {
  return grass.top + grass.height * ny.clamp(0.0, 1.0);
}

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

  /// Clave guardada (`3-2-1`, …). Solo F7: activa posiciones del diagrama táctico.
  final String? formationLayoutKey;

  /// Resalta tarjetas con borde (amarilla / roja) alrededor de cada ficha en campo.
  final MatchPlayerDisciplineHighlight Function(int playerId)? playerDiscipline;

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
    this.formationLayoutKey,
    this.playerDiscipline,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final brightness = Theme.of(context).brightness;
        final l10n = AppLocalizations.of(context)!;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        // Ancho máximo del tablero; nunca supera esto, pero si el padre es más
        // estrecho o bajo, se encoge para seguir viéndose entero.
        const maxBoardW = 440.0;
        var boardW = maxW < maxBoardW ? maxW : maxBoardW;
        // Alto = solo proporción del PNG respecto a [boardW]. No aumenta con la
        // altura disponible del padre (evita huecos al maximizar la ventana).
        var boardH = boardW * _kCampoPngHeight / _kCampoPngWidth;
        if (boardH > maxH && maxH.isFinite) {
          boardH = maxH;
          boardW = boardH * _kCampoPngWidth / _kCampoPngHeight;
          if (boardW > maxBoardW) {
            boardW = maxBoardW;
            boardH = boardW * _kCampoPngHeight / _kCampoPngWidth;
          }
          if (boardW > maxW) {
            boardW = maxW;
            boardH = boardW * _kCampoPngHeight / _kCampoPngWidth;
          }
        }
        // Mismo rectángulo que el PNG con BoxFit.contain sobre el tablero real.
        final fieldPaint = _campoContainRect(boardW, boardH);
        final grass = _grassRectFromFieldPaint(fieldPaint);
        final rows = formationLines.length;
        final totalSlots = formationLines.fold<int>(0, (a, b) => a + b);
        final List<Offset>? tacticalCenters =
            MatchFormationUtils.tacticalSlotCentersOrNull(
              formationLayoutKey,
              totalSlots,
            );

        final List<Widget> children = [
          Positioned.fill(
            child: Image.asset(
              'media/campo.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
        ];

        int positionNumber = 1;
        for (int row = 0; row < rows; row++) {
          // Invertimos las filas para que el portero (primera línea) quede abajo
          final displayRow = rows - 1 - row;
          final countInRow = formationLines[row];
          final fracY = (displayRow + 1) / (rows + 1);
          final gridRowTop = _grassY(grass, fracY);

          for (int col = 0; col < countInRow; col++) {
            final index = positionNumber - 1;
            final double left;
            final double top;
            if (tacticalCenters != null && index < tacticalCenters.length) {
              final o = tacticalCenters[index];
              left = _grassX(grass, o.dx);
              top = _grassY(grass, o.dy);
            } else {
              left = _grassX(grass, (col + 1) / (countInRow + 1));
              top = gridRowTop;
            }
            final assignedPlayer = index < positionPlayers.length
                ? positionPlayers[index]
                : null;
            final displayNumber = assignedPlayer?.number?.toString() ?? '';

            const nameBlockWidth = 92.0;
            final hasName = assignedPlayer != null;
            final discipline =
                assignedPlayer != null && playerDiscipline != null
                ? playerDiscipline!(assignedPlayer.id)
                : MatchPlayerDisciplineHighlight.none;

            children.add(
              Positioned(
                left: hasName ? left - nameBlockWidth / 2 : left - 16,
                top: top - 16,
                width: hasName ? nameBlockWidth : 32,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
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

                    final newPositions = List<Player?>.from(positionPlayers);

                    // Intercambio de posiciones entre dos jugadores en campo
                    // (muy usado al colocar el 11 antes de empezar: hay que
                    // registrarlo como evento; antes solo se hacía onPositionsChanged).
                    if (existingIndex != -1 && assignedPlayer != null) {
                      newPositions[existingIndex] = assignedPlayer;
                      newPositions[index] = selectedPlayer;
                      onPositionsChanged(newPositions);
                      onSubstitutionRequested(
                        selectedPlayer!,
                        assignedPlayer,
                      );
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
                    onSubstitutionRequested(selectedPlayer!, assignedPlayer);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: _fieldAvatarBackground(
                            hasPlayer: assignedPlayer != null,
                            discipline: discipline,
                            scheme: scheme,
                            brightness: brightness,
                          ),
                          child: Text(
                            displayNumber,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _fieldAvatarForeground(
                                hasPlayer: assignedPlayer != null,
                                discipline: discipline,
                                scheme: scheme,
                                brightness: brightness,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (assignedPlayer != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          _fieldDisplayFirstName(assignedPlayer),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            positionNumber++;
          }
        }

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// Fondo del dorsal en campo: gris neutro (sin color de equipo); amarillo/rojo solo por tarjeta.
Color _fieldAvatarBackground({
  required bool hasPlayer,
  required MatchPlayerDisciplineHighlight discipline,
  required ColorScheme scheme,
  required Brightness brightness,
}) {
  if (!hasPlayer) {
    return scheme.surfaceContainerHighest.withValues(alpha: 0.92);
  }
  switch (discipline) {
    case MatchPlayerDisciplineHighlight.yellow:
      return brightness == Brightness.dark
          ? const Color(0xFFFF8F00).withValues(alpha: 0.88)
          : const Color(0xFFFFD54F);
    case MatchPlayerDisciplineHighlight.red:
      return intenseDisciplineRed(scheme);
    case MatchPlayerDisciplineHighlight.none:
      return Color.alphaBlend(
        scheme.onSurface.withValues(
          alpha: brightness == Brightness.dark ? 0.2 : 0.11,
        ),
        scheme.surfaceContainerHigh,
      );
  }
}

Color _fieldAvatarForeground({
  required bool hasPlayer,
  required MatchPlayerDisciplineHighlight discipline,
  required ColorScheme scheme,
  required Brightness brightness,
}) {
  if (!hasPlayer) {
    return scheme.onSurfaceVariant;
  }
  switch (discipline) {
    case MatchPlayerDisciplineHighlight.yellow:
      return brightness == Brightness.dark
          ? const Color(0xFF1A0D00)
          : const Color(0xFF3E2723);
    case MatchPlayerDisciplineHighlight.red:
      return const Color(0xFF1A0404);
    case MatchPlayerDisciplineHighlight.none:
      return scheme.onSurface.withValues(alpha: 0.92);
  }
}

String _fieldDisplayFirstName(Player player) {
  final g = playerNamePartsMatchShort(player).given.trim();
  if (g.isNotEmpty) {
    return g;
  }
  final fn = player.firstName.trim();
  final fnTok = fn.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (fnTok.isNotEmpty) {
    return fnTok.first;
  }
  final full = player.fullName.trim();
  final fullTok = full
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (fullTok.isEmpty) {
    return '—';
  }
  return fullTok.first;
}
