import 'package:flutter/foundation.dart';

/// Misma estructura de UI para todos los roles; [canModifyMatch] restringe
/// acciones a admin y super admin del equipo. [isExternal] solo afecta
/// textos de modo espectador frente a entrenador/jugador.
@immutable
class MatchManagerUiPolicy {
  const MatchManagerUiPolicy({
    required this.isExternal,
    required this.canModifyMatch,
  });
  final bool isExternal;
  final bool canModifyMatch;

  bool get readOnlyMatchActions => !canModifyMatch;

  VoidCallback? coachAction(VoidCallback action) =>
      canModifyMatch ? action : null;
}
