import 'package:football_manager/domain/entities/player.dart';

final _spaces = RegExp(r'\s+');

/// Fragmentos de nombre para tipografía: [given] en negrita, [family] en peso normal.
class PlayerNameParts {
  const PlayerNameParts({required this.given, required this.family});

  final String given;
  final String family;
}

/// Nombre y apellidos completos: `firstname` en negrita, `lastname` en normal.
PlayerNameParts playerNamePartsGeneral(Player player) {
  final fn = player.firstName.trim();
  final ln = (player.lastName ?? '').trim();
  if (fn.isNotEmpty || ln.isNotEmpty) {
    return PlayerNameParts(given: fn, family: ln);
  }
  final full = player.fullName.trim();
  if (full.isEmpty) {
    return const PlayerNameParts(given: 'Jugador', family: '');
  }
  final toks = full.split(_spaces).where((s) => s.isNotEmpty).toList();
  if (toks.isEmpty) {
    return const PlayerNameParts(given: 'Jugador', family: '');
  }
  if (toks.length == 1) {
    return PlayerNameParts(given: toks.first, family: '');
  }
  return PlayerNameParts(given: toks.first, family: toks.sublist(1).join(' '));
}

/// Primer nombre y primer apellido (formato habitual en listas y UI compacta).
PlayerNameParts playerNamePartsMatchShort(Player player) {
  final rawFirst = player.firstName.trim();
  final first =
      rawFirst.isEmpty ? '' : rawFirst.split(_spaces).first.trim();
  final rawLast = (player.lastName ?? '').trim();
  final last = rawLast.isEmpty ? '' : rawLast.split(_spaces).first.trim();
  if (first.isEmpty && last.isEmpty) {
    final full = player.fullName.trim();
    if (full.isEmpty) {
      return const PlayerNameParts(given: 'Jugador', family: '');
    }
    final toks = full.split(_spaces).where((s) => s.isNotEmpty).toList();
    if (toks.length == 1) {
      return PlayerNameParts(given: toks.first, family: '');
    }
    return PlayerNameParts(
      given: toks.first,
      family: toks.sublist(1).join(' '),
    );
  }
  if (last.isEmpty) {
    return PlayerNameParts(given: first, family: '');
  }
  if (first.isEmpty) {
    return PlayerNameParts(given: last, family: '');
  }
  return PlayerNameParts(given: first, family: last);
}
