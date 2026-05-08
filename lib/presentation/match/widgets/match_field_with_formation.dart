import 'package:flutter/material.dart';
import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/match/utils/match_formation_utils.dart';

/// Discipline highlight for match player (yellow card, red card, or none).
enum MatchPlayerDisciplineHighlight { yellow, red, none }

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

/// [logSubstitutionEvent]: si es true, el padre debe persistir y registrar
/// sustitución en [match_events] (entra [substitutionIn], sale [substitutionOut]).
typedef MatchFieldLineupCommit =
    void Function(
      List<Player?> newPositions, {
      required bool logSubstitutionEvent,
      Player? substitutionIn,
      Player? substitutionOut,
    });

void _placePlayerInFieldSlot({
  required int index,
  required Player playerIn,
  required Player? assignedAtIndex,
  required List<Player?> positionPlayers,
  required bool readOnly,
  required Set<int> sentOffPlayerIds,
  required int Function() currentPlayersOnField,
  required int Function() maxPlayersOnField,
  required void Function(String message, {bool error}) showSnack,
  required MatchFieldLineupCommit onLineupChanged,
  required AppLocalizations l10n,
}) {
  if (readOnly) {
    return;
  }
  if (sentOffPlayerIds.contains(playerIn.id)) {
    showSnack(l10n.matchPlayerSentOffCannotReturn, error: true);
    return;
  }
  final existingIndex = positionPlayers.indexWhere(
    (p) => p != null && p.id == playerIn.id,
  );
  if (existingIndex == index) {
    return;
  }
  final newPositions = List<Player?>.from(positionPlayers);
  if (existingIndex != -1 && assignedAtIndex != null) {
    newPositions[existingIndex] = assignedAtIndex;
    newPositions[index] = playerIn;
    onLineupChanged(
      newPositions,
      // Si el jugador ya estaba en campo, es ajuste posicional, no sustitución.
      logSubstitutionEvent: false,
      substitutionIn: playerIn,
      substitutionOut: assignedAtIndex,
    );
    return;
  }
  if (existingIndex == -1 &&
      assignedAtIndex == null &&
      currentPlayersOnField() >= maxPlayersOnField()) {
    showSnack(l10n.matchFieldMaxPlayersExpulsionRule, error: true);
    return;
  }
  if (existingIndex != -1) {
    newPositions[existingIndex] = null;
  }
  newPositions[index] = playerIn;
  onLineupChanged(
    newPositions,
    // Solo hay evento de sustitución si entra alguien que no estaba en campo.
    logSubstitutionEvent: existingIndex == -1,
    substitutionIn: playerIn,
    substitutionOut: assignedAtIndex,
  );
}

/// Ancho de la columna (avatar + nombre) en el campo: mismo valor en [Positioned] y en banquillo.
const double _kFieldNameBlockWidth = 92.0;

/// Misma ficha que en cada posición del [Stack] del campo: [CircleAvatar] 16 + nombre.
Widget _fieldSlotPlayerFicha({
  required Player player,
  required MatchPlayerDisciplineHighlight discipline,
  required ColorScheme scheme,
  required Brightness brightness,
}) {
  final displayNumber = player.number?.toString() ?? '';
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Center(
        child: CircleAvatar(
          radius: 16,
          backgroundColor: _fieldAvatarBackground(
            hasPlayer: true,
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
                hasPlayer: true,
                discipline: discipline,
                scheme: scheme,
                brightness: brightness,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        _fieldDisplayFirstName(player),
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
  );
}

/// Campo táctil: colocación **jugador seleccionado + toque**, **pulsación larga en campo**
/// para reordenar, o **reservas bajo el campo** arrastrables a una posición (sustitución).
class MatchFieldWithFormation extends StatelessWidget {
  final List<int> formationLines;
  final List<Player?> positionPlayers;
  final List<Player> benchPlayers;
  final Player? selectedPlayer;
  final Set<int> sentOffPlayerIds;
  final int Function() currentPlayersOnField;
  final int Function() maxPlayersOnField;
  final void Function(String message, {bool error}) showSnack;
  final MatchFieldLineupCommit onLineupChanged;
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
    this.benchPlayers = const [],
    required this.selectedPlayer,
    required this.sentOffPlayerIds,
    required this.currentPlayersOnField,
    required this.maxPlayersOnField,
    required this.showSnack,
    required this.onLineupChanged,
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

            const nameBlockWidth = _kFieldNameBlockWidth;
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
                child: DragTarget<Object>(
                  onWillAcceptWithDetails: (details) {
                    if (readOnly) {
                      return false;
                    }
                    final data = details.data;
                    if (data is int) {
                      final from = data;
                      if (from == index) {
                        return false;
                      }
                      if (from < 0 || from >= positionPlayers.length) {
                        return false;
                      }
                      return positionPlayers[from] != null;
                    }
                    if (data is Player) {
                      if (sentOffPlayerIds.contains(data.id)) {
                        return false;
                      }
                      if (positionPlayers.any(
                        (p) => p != null && p.id == data.id,
                      )) {
                        return false;
                      }
                      if (index < 0 || index >= positionPlayers.length) {
                        return false;
                      }
                      final atTarget = positionPlayers[index];
                      if (atTarget == null &&
                          currentPlayersOnField() >= maxPlayersOnField()) {
                        return false;
                      }
                      return true;
                    }
                    return false;
                  },
                  onAcceptWithDetails: (details) {
                    if (readOnly) {
                      return;
                    }
                    final data = details.data;
                    if (data is int) {
                      final from = data;
                      if (from == index) {
                        return;
                      }
                      if (from < 0 || from >= positionPlayers.length) {
                        return;
                      }
                      final moved = positionPlayers[from];
                      if (moved == null) {
                        return;
                      }
                      final newPositions = List<Player?>.from(positionPlayers);
                      final atTarget = newPositions[index];
                      if (atTarget == null) {
                        newPositions[index] = moved;
                        newPositions[from] = null;
                      } else {
                        newPositions[index] = moved;
                        newPositions[from] = atTarget;
                      }
                      onLineupChanged(
                        newPositions,
                        logSubstitutionEvent: false,
                      );
                      return;
                    }
                    if (data is Player) {
                      _placePlayerInFieldSlot(
                        index: index,
                        playerIn: data,
                        assignedAtIndex: assignedPlayer,
                        positionPlayers: positionPlayers,
                        readOnly: readOnly,
                        sentOffPlayerIds: sentOffPlayerIds,
                        currentPlayersOnField: currentPlayersOnField,
                        maxPlayersOnField: maxPlayersOnField,
                        showSnack: showSnack,
                        onLineupChanged: onLineupChanged,
                        l10n: l10n,
                      );
                    }
                  },
                  builder: (context, candidate, rejected) {
                    Widget buildCol() {
                      if (assignedPlayer == null) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: _fieldAvatarBackground(
                                  hasPlayer: false,
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
                                      hasPlayer: false,
                                      discipline: discipline,
                                      scheme: scheme,
                                      brightness: brightness,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _fieldSlotPlayerFicha(
                        player: assignedPlayer,
                        discipline: discipline,
                        scheme: scheme,
                        brightness: brightness,
                      );
                    }

                    final gesture = GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (readOnly) {
                          return;
                        }
                        if (selectedPlayer == null && assignedPlayer != null) {
                          onPlayerActionRequested(assignedPlayer);
                          return;
                        }

                        if (selectedPlayer == null && assignedPlayer == null) {
                          showSnack(
                            l10n.matchFieldSelectPlayerFirst,
                            error: true,
                          );
                          return;
                        }

                        _placePlayerInFieldSlot(
                          index: index,
                          playerIn: selectedPlayer!,
                          assignedAtIndex: assignedPlayer,
                          positionPlayers: positionPlayers,
                          readOnly: readOnly,
                          sentOffPlayerIds: sentOffPlayerIds,
                          currentPlayersOnField: currentPlayersOnField,
                          maxPlayersOnField: maxPlayersOnField,
                          showSnack: showSnack,
                          onLineupChanged: onLineupChanged,
                          l10n: l10n,
                        );
                      },
                      child: buildCol(),
                    );

                    final withDrag = readOnly || assignedPlayer == null
                        ? gesture
                        : LongPressDraggable<int>(
                            data: index,
                            hapticFeedbackOnStart: true,
                            maxSimultaneousDrags: 1,
                            feedback: buildCol(),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: buildCol(),
                            ),
                            child: gesture,
                          );

                    final highlight = candidate.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: highlight
                          ? BoxDecoration(
                              border: Border.all(
                                color: scheme.primary,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            )
                          : null,
                      child: withDrag,
                    );
                  },
                ),
              ),
            );

            positionNumber++;
          }
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: boardW,
                height: boardH,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: children,
                ),
              ),
              if (benchPlayers.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: boardW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Suplentes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!readOnly) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Arrastra desde aquí para sustituir',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 8),
                      ] else
                        const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final p in benchPlayers)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  bottom: 2,
                                ),
                                child: _buildBenchPlayerItem(
                                  player: p,
                                  readOnly: readOnly,
                                  sentOffPlayerIds: sentOffPlayerIds,
                                  scheme: scheme,
                                  brightness: brightness,
                                  playerDiscipline: playerDiscipline,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Banquillo: misma ficha que en el campo; [LongPressDraggable] si [readOnly] es falso
/// y el jugador no está expulsado.
Widget _buildBenchPlayerItem({
  required Player player,
  required bool readOnly,
  required Set<int> sentOffPlayerIds,
  required ColorScheme scheme,
  required Brightness brightness,
  required MatchPlayerDisciplineHighlight Function(int playerId)?
  playerDiscipline,
}) {
  final discipline = playerDiscipline == null
      ? MatchPlayerDisciplineHighlight.none
      : playerDiscipline(player.id);
  final isSentOff = sentOffPlayerIds.contains(player.id);
  Widget buildFicha() {
    return SizedBox(
      width: _kFieldNameBlockWidth,
      child: _fieldSlotPlayerFicha(
        player: player,
        discipline: discipline,
        scheme: scheme,
        brightness: brightness,
      ),
    );
  }

  if (readOnly || isSentOff) {
    return buildFicha();
  }
  return LongPressDraggable<Player>(
    data: player,
    hapticFeedbackOnStart: true,
    maxSimultaneousDrags: 1,
    feedback: buildFicha(),
    childWhenDragging: Opacity(opacity: 0.35, child: buildFicha()),
    child: buildFicha(),
  );
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
      return const Color(0xFFFFC107).withValues(alpha: 0.88);
    case MatchPlayerDisciplineHighlight.red:
      return scheme.error.withValues(alpha: 0.88);
    case MatchPlayerDisciplineHighlight.none:
      return scheme.surfaceContainerHighest.withValues(alpha: 0.92);
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
