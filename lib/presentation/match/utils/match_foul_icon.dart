import 'package:flutter/material.dart';

/// Claves de evento canónicas (tras [canonicalMatchEventTypeKey]) para faltas.
bool isMatchFoulCanonicalKey(String key) => key == 'foul' || key == 'rivalfoul';

/// Silbato de pictograma (cuerpo + boquilla); el agujero deja ver el fondo
/// del [CircleAvatar] u otra capa inferior.
class MatchWhistleIcon extends StatelessWidget {
  const MatchWhistleIcon({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhistleIconPainter(color: color),
    );
  }
}

class _WhistleIconPainter extends CustomPainter {
  _WhistleIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;

    canvas.saveLayer(Offset.zero & size, Paint());

    final mouth = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.38, w * 0.2, h * 0.24),
      Radius.circular(h * 0.06),
    );
    canvas.drawRRect(mouth, fill);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.28, w * 0.8, h * 0.44),
      Radius.circular(h * 0.2),
    );
    canvas.drawRRect(body, fill);

    canvas.drawCircle(
      Offset(w * 0.52, h * 0.5),
      w * 0.095,
      Paint()
        ..blendMode = BlendMode.clear
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhistleIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Fondo / tinte del icono en lista (acorde a tarjetas / disciplina).
const Color kMatchFoulListAvatarBackground = Color(0xFFFFF3E0);
const Color kMatchFoulListAvatarForeground = Color(0xFFBF360C);
