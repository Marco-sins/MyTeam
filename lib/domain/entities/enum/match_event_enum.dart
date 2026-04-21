enum MatchEventEnum {
  scoreGoal,
  concedeGoal,
  yellowCard,
  redCard,
  penalty,
  ownGoal,
  assist,
  injury,
  keyPass,
  goodPass,
  badPass,
  goodPlay,
  badPlay,
  ballRecovery,
  goodSave,
  substitution,
  formation,
  statusChange,
  /// Tiro a puerta registrado desde un jugador en campo.
  shot,
  /// Tiro a puerta del rival (solo contador manual +/−).
  rivalShot,
  /// Falta cometida por un jugador propio (nota negativa en valoración).
  foul,
  /// Córner a favor (contador manual).
  corner,
  /// Córner del rival (contador manual).
  rivalCorner,
  /// Falta del rival (contador manual).
  rivalFoul,
  /// Fallo grave del portero (cantada).
  cantada,
}
