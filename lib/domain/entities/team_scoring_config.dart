/// Identificadores fijos (peso por evento o nota, sincronizados con [player_rating_utils]).
abstract class TeamScoringBuiltinId {
  static const scoregoalScorer = 'scoregoal_scorer';
  static const scoregoalAssist = 'scoregoal_assist';
  static const owngoal = 'owngoal';
  static const concedegoal = 'concedegoal';
  static const shot = 'shot';
  static const goodpass = 'goodpass';
  static const badpass = 'badpass';
  static const goodplay = 'goodplay';
  static const badplay = 'badplay';
  static const ballrecovery = 'ballrecovery';
  static const goodsave = 'goodsave';
  static const goodsaveIncredible = 'goodsave_incredible';
  static const yellowcard = 'yellowcard';
  static const redcard = 'redcard';
  static const foul = 'foul';
  static const cantada = 'cantada';
  static const keypass = 'keypass';
  // Notas / alias legacy
  static const paseClave = 'pase_clave';
  static const jugadaClave = 'jugada_clave';
  static const tiroNote = 'tiro_note';
  static const tarjetaAmarilla = 'tarjeta_amarilla';
  static const tarjetaRoja = 'tarjeta_roja';
  static const cantadaNote = 'cantada_note';
  static const prefixCustom = 'custom_';
}

/// Puntuación (delta sobre la media) asociada a un evento fijo o personalizado.
class TeamScoringLine {
  const TeamScoringLine({
    required this.id,
    required this.points,
    this.name,
  });

  final String id;
  final String? name;
  final double points;

  bool get isCustom => id.startsWith(TeamScoringBuiltinId.prefixCustom);

  Map<String, dynamic> toJson() => {
    'id': id,
    'p': points,
    if (name != null) 'n': name,
  };

  static TeamScoringLine fromJson(Map<String, dynamic> m) {
    return TeamScoringLine(
      id: m['id'] as String,
      points: (m['p'] as num).toDouble(),
      name: m['n'] as String?,
    );
  }
}

/// Puntuaciones del equipo. Persistencia local ([TeamScoringConfigStorage]).
class TeamScoringConfig {
  const TeamScoringConfig({required this.lines});

  final List<TeamScoringLine> lines;

  static Map<String, double> get defaultWeightMap => _kDefault;

  static double defaultWeightFor(String id) => _kDefault[id] ?? 0.0;

  static const Map<String, double> _kDefault = {
    TeamScoringBuiltinId.scoregoalScorer: 1.0,
    TeamScoringBuiltinId.scoregoalAssist: 0.75,
    TeamScoringBuiltinId.owngoal: -1.0,
    TeamScoringBuiltinId.concedegoal: -0.4,
    TeamScoringBuiltinId.shot: 0.1,
    TeamScoringBuiltinId.goodpass: 0.12,
    TeamScoringBuiltinId.badpass: -0.12,
    TeamScoringBuiltinId.goodplay: 0.22,
    TeamScoringBuiltinId.badplay: -0.28,
    TeamScoringBuiltinId.ballrecovery: 0.28,
    TeamScoringBuiltinId.goodsave: 0.42,
    TeamScoringBuiltinId.goodsaveIncredible: 0.55,
    TeamScoringBuiltinId.yellowcard: -0.9,
    TeamScoringBuiltinId.redcard: -2.5,
    TeamScoringBuiltinId.foul: -0.32,
    TeamScoringBuiltinId.cantada: -1.25,
    TeamScoringBuiltinId.keypass: 0.25,
    TeamScoringBuiltinId.paseClave: 0.25,
    TeamScoringBuiltinId.jugadaClave: 0.35,
    TeamScoringBuiltinId.tiroNote: 0.1,
    TeamScoringBuiltinId.tarjetaAmarilla: -0.9,
    TeamScoringBuiltinId.tarjetaRoja: -2.5,
    TeamScoringBuiltinId.cantadaNote: -1.25,
  };

  /// Lista por defecto al crear o resetear valoración: mismos pesos que [_kDefault],
  /// sin duplicar variantes legacy (p. ej. nota "tiro" vs tipo tiro).
  static const List<String> kDefaultScoringBuiltinIdsOrder = [
    TeamScoringBuiltinId.scoregoalScorer, // Gol
    TeamScoringBuiltinId.scoregoalAssist, // Asistencia
    TeamScoringBuiltinId.shot, // Tiro
    TeamScoringBuiltinId.goodpass, // Buen pase
    TeamScoringBuiltinId.goodplay, // Buena jugada
    TeamScoringBuiltinId.goodsave, // Buena parada
    TeamScoringBuiltinId.ballrecovery, // Balón recuperado
    TeamScoringBuiltinId.yellowcard, // Tarjeta amarilla
    TeamScoringBuiltinId.redcard, // Tarjeta roja
    TeamScoringBuiltinId.badpass, // Mal pase
    TeamScoringBuiltinId.badplay, // Mala jugada
    TeamScoringBuiltinId.foul, // Falta
    TeamScoringBuiltinId.cantada, // Cantada
  ];

  static List<TeamScoringLine> defaultBuiltInLines() {
    return [
      for (final id in kDefaultScoringBuiltinIdsOrder)
        TeamScoringLine(
          id: id,
          points: _kDefault[id] ?? 0.0,
        ),
    ];
  }

  /// Peso almacenado para [id]: si el usuario eliminó la fila, no hay entrada → 0.
  double weightFor(String id) {
    for (final l in lines) {
      if (l.id == id) {
        return l.points;
      }
    }
    return 0.0;
  }

  static TeamScoringConfig fromDefaultAndCustoms(
    List<TeamScoringLine> custom,
  ) {
    return TeamScoringConfig(
      lines: <TeamScoringLine>[...defaultBuiltInLines(), ...custom],
    );
  }

  List<TeamScoringLine> get builtInLines =>
      lines.where((l) => !l.isCustom).toList();

  List<TeamScoringLine> get customLines =>
      lines.where((l) => l.isCustom).toList();

  Map<String, dynamic> toJson() => {
    'v': 1,
    'lines': lines.map((e) => e.toJson()).toList(),
  };

  static TeamScoringConfig? fromJsonMap(Map<String, dynamic> m) {
    final raw = m['lines'];
    if (raw is! List) {
      return null;
    }
    return TeamScoringConfig(
      lines: raw
          .map(
            (e) => TeamScoringLine.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

String newCustomScoringId() =>
    '${TeamScoringBuiltinId.prefixCustom}${DateTime.now().microsecondsSinceEpoch}';
