import 'package:flutter/material.dart';
import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';

enum PlayerNameTextMode {
  /// Nombre y apellidos completos (campos `firstname` / `lastname`).
  general,

  /// Primer nombre y primer apellido, en una línea (listas, partido, convocatoria).
  matchShort,
}

/// Nombre del jugador: **nombre** en negrita, apellidos en peso normal.
class PlayerNameText extends StatelessWidget {
  const PlayerNameText({
    super.key,
    required this.player,
    this.style,
    this.mode = PlayerNameTextMode.matchShort,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  final Player player;
  final TextStyle? style;
  final PlayerNameTextMode mode;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  PlayerNameParts get _parts => mode == PlayerNameTextMode.general
      ? playerNamePartsGeneral(player)
      : playerNamePartsMatchShort(player);

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final parts = _parts;
    final given = parts.given.isEmpty ? 'Jugador' : parts.given;

    if (parts.family.isEmpty) {
      return Text(
        given,
        style: base.copyWith(fontWeight: FontWeight.w700),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: true,
      );
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: given,
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ${parts.family}',
            style: base.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: true,
    );
  }
}

/// Dorsal + nombre con el mismo criterio tipográfico que [PlayerNameText] en modo partido.
class PlayerDorsalNameText extends StatelessWidget {
  const PlayerDorsalNameText({
    super.key,
    required this.player,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  final Player player;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final parts = playerNamePartsMatchShort(player);
    final dorsal = player.number?.toString() ?? '-';
    final given = parts.given.isEmpty ? 'Jugador' : parts.given;

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: '$dorsal  ',
            style: base.copyWith(fontWeight: FontWeight.w600),
          ),
          if (parts.family.isEmpty)
            TextSpan(
              text: given,
              style: base.copyWith(fontWeight: FontWeight.w700),
            )
          else ...[
            TextSpan(
              text: given,
              style: base.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' ${parts.family}',
              style: base.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: true,
    );
  }
}

/// Spans reutilizables (SnackBar, `Text.rich`, eventos).
List<InlineSpan> playerNameSpanList(
  Player player,
  TextStyle base, {
  PlayerNameTextMode mode = PlayerNameTextMode.matchShort,
}) {
  final parts = mode == PlayerNameTextMode.general
      ? playerNamePartsGeneral(player)
      : playerNamePartsMatchShort(player);
  final given = parts.given.isEmpty ? 'Jugador' : parts.given;
  if (parts.family.isEmpty) {
    return [
      TextSpan(text: given, style: base.copyWith(fontWeight: FontWeight.w700)),
    ];
  }
  return [
    TextSpan(text: given, style: base.copyWith(fontWeight: FontWeight.w700)),
    TextSpan(
      text: ' ${parts.family}',
      style: base.copyWith(fontWeight: FontWeight.w400),
    ),
  ];
}

List<InlineSpan> playerDorsalNameSpanList(Player player, TextStyle base) {
  final dorsal = player.number?.toString() ?? '-';
  final parts = playerNamePartsMatchShort(player);
  final given = parts.given.isEmpty ? 'Jugador' : parts.given;
  return [
    TextSpan(
      text: '$dorsal  ',
      style: base.copyWith(fontWeight: FontWeight.w600),
    ),
    if (parts.family.isEmpty)
      TextSpan(text: given, style: base.copyWith(fontWeight: FontWeight.w700))
    else ...[
      TextSpan(text: given, style: base.copyWith(fontWeight: FontWeight.w700)),
      TextSpan(
        text: ' ${parts.family}',
        style: base.copyWith(fontWeight: FontWeight.w400),
      ),
    ],
  ];
}
