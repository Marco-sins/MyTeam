import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';

/// Primer nombre y primer apellido para listas de partido, eventos y plantilla.
///
/// Ej.: "Juan Carlos" + "García López" → "Juan García".
String matchPlayerDisplayName(Player player) {
  final p = playerNamePartsMatchShort(player);
  if (p.family.isEmpty) return p.given;
  return '${p.given} ${p.family}';
}

/// Dorsal y nombre corto (mismo formato que en convocatoria / eventos).
String matchPlayerDorsalAndName(Player player) {
  final dorsal = player.number?.toString() ?? '-';
  return '$dorsal  ${matchPlayerDisplayName(player)}';
}
