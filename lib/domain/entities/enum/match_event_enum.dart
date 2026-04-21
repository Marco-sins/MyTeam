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
}
