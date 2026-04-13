import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';

void drawConvocationBody({
  required Canvas canvas,
  required Rect overlayRect,
  required double startY,
  required String dateStr,
  required String matchTimeStr,
  required String callTimeStr,
  required String? mapUrl,
  required String? awayLocation,
  required bool isHome,
  required String? notes,
  required List<Player> players,
}) {
  double y = startY;

  final separatorPaint = Paint()..color = Colors.grey.shade300;
  canvas.drawRect(
    Rect.fromLTWH(overlayRect.left + 20, y, overlayRect.width - 40, 2),
    separatorPaint,
  );

  y += 26;

  const sectionTagHeight = 32.0;
  final detailsTagRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 24, y, 280, sectionTagHeight),
    const Radius.circular(16),
  );
  final detailsTagPaint = Paint()..color = const Color(0xFF1B5E20);
  canvas.drawRRect(detailsTagRect, detailsTagPaint);
  _drawSectionLabel(canvas, 'Detalles del partido ⚽', detailsTagRect);

  y += sectionTagHeight + 28;

  _drawText(canvas, overlayRect, 'Fecha:  $dateStr', y, fontSize: 20);
  y += 32;
  _drawText(
    canvas,
    overlayRect,
    'Hora partido:       $matchTimeStr',
    y,
    fontSize: 20,
  );
  y += 30;
  _drawText(
    canvas,
    overlayRect,
    'Hora convocatoria:  $callTimeStr',
    y,
    fontSize: 20,
  );
  y += 34;

  if (isHome && awayLocation != null && awayLocation.isNotEmpty) {
    // Dibuja la línea 'Lugar: <nombre del campo>' solo si es local
    final lugarText = 'Lugar: $awayLocation';
    final maxWidth = overlayRect.width - 40;
    final dx = overlayRect.left + 20;
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.left,
              fontSize: 20,
              fontWeight: FontWeight.normal,
              maxLines: 1,
            ),
          )
          ..pushStyle(ui.TextStyle(color: Colors.black87))
          ..addText(lugarText);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(dx, y));
    y += 38;
    y += 12;
  }

  canvas.drawRect(
    Rect.fromLTWH(overlayRect.left + 20, y, overlayRect.width - 40, 2),
    separatorPaint,
  );

  y += 26;

  final playersTagRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      overlayRect.left + 24,
      y,
      overlayRect.width - 48,
      sectionTagHeight,
    ),
    const Radius.circular(16),
  );
  final playersTagPaint = Paint()..color = const Color(0xFF0D47A1);
  canvas.drawRRect(playersTagRect, playersTagPaint);
  _drawSectionLabel(
    canvas,
    'Jugadores convocados (${players.length}) ⭐',
    playersTagRect,
  );

  y += sectionTagHeight + 24;

  final playersBgPaint = Paint()
    ..color = const Color(0xFF4CAF50).withAlpha((0.08 * 255).round());
  canvas.drawCircle(Offset(overlayRect.center.dx, y + 80), 140, playersBgPaint);

  for (final p in players) {
    final dorsal = (p.number?.toString() ?? '-').padLeft(2, ' ');
    final line = '•  $dorsal   ${p.fullName}';
    _drawText(canvas, overlayRect, line, y, fontSize: 20);
    y += 30;
  }

  y += 32;
  final trimmedNotes = notes?.trim() ?? '';
  if (trimmedNotes.isNotEmpty) {
    canvas.drawRect(
      Rect.fromLTWH(overlayRect.left + 20, y, overlayRect.width - 40, 2),
      separatorPaint,
    );

    y += 26;

    final notesTagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(overlayRect.left + 24, y, 220, sectionTagHeight),
      const Radius.circular(16),
    );
    final notesTagPaint = Paint()..color = const Color(0xFFFF8F00);
    canvas.drawRRect(notesTagRect, notesTagPaint);
    _drawSectionLabel(canvas, 'Observaciones 📝', notesTagRect);

    y += sectionTagHeight + 26;

    _drawText(
      canvas,
      overlayRect,
      trimmedNotes,
      y,
      fontSize: 19,
      color: Colors.black87,
    );
  }
}

void _drawText(
  Canvas canvas,
  Rect overlayRect,
  String text,
  double dy, {
  double? fontSize,
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black87,
}) {
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: fontSize ?? 32,
            fontWeight: fontWeight,
            maxLines: 4,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);

  final paragraph = builder.build();
  final maxWidth = overlayRect.width - 40;
  paragraph.layout(ui.ParagraphConstraints(width: maxWidth));

  final dx = overlayRect.left + 20;
  canvas.drawParagraph(paragraph, Offset(dx, dy));
}

void _drawSectionLabel(Canvas canvas, String text, RRect rect) {
  final width = rect.width;
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(text);

  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: width - 16));

  final offset = Offset(
    rect.left + 12,
    rect.top + (rect.height - paragraph.height) / 2,
  );
  canvas.drawParagraph(paragraph, offset);
}
