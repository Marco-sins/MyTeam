import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/team.dart';

double drawConvocationHeader({
  required Canvas canvas,
  required Rect overlayRect,
  required Team team,
  required bool isHome,
  required String rivalName,
}) {
  const headerHeight = 190.0;
  final headerRRect = RRect.fromRectAndCorners(
    Rect.fromLTWH(
      overlayRect.left,
      overlayRect.top,
      overlayRect.width,
      headerHeight,
    ),
    topLeft: const Radius.circular(32),
    topRight: const Radius.circular(32),
  );

  final headerPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF0D47A1), Color(0xFF1B5E20)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(headerRRect.outerRect);
  canvas.drawRRect(headerRRect, headerPaint);

  double y = overlayRect.top + 28;

  final homeTeamName = isHome ? team.name : rivalName;
  final awayTeamName = isHome ? rivalName : team.name;

  void drawText(
    String text,
    double dy, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
    TextAlign align = TextAlign.left,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: align,
              fontSize: fontSize ?? 32,
              fontWeight: fontWeight,
              maxLines: 4,
            ),
          )
          ..pushStyle(ui.TextStyle(color: color))
          ..addText(text);

    final paragraph = builder.build();
    const maxWidth = 1000.0;
    paragraph.layout(const ui.ParagraphConstraints(width: maxWidth));

    double dx;
    if (align == TextAlign.center) {
      dx =
          overlayRect.left +
          (overlayRect.width - paragraph.maxIntrinsicWidth) / 2;
    } else if (align == TextAlign.right) {
      dx = overlayRect.right - paragraph.maxIntrinsicWidth - 20;
    } else {
      dx = overlayRect.left + 20;
    }

    canvas.drawParagraph(paragraph, Offset(dx, dy));
  }

  void drawMatchupLine(double dy) {
    const versusText = 'VS';
    const teamFontSize = 52.0;
    const versusFontSize = 54.0;
    const spacing = 24.0;

    ui.Paragraph buildParagraph(String text, double fontSize) {
      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.left,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                maxLines: 1,
              ),
            )
            ..pushStyle(ui.TextStyle(color: Colors.white))
            ..addText(text);

      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
      return paragraph;
    }

    final homeParagraph = buildParagraph(homeTeamName, teamFontSize);
    final versusParagraph = buildParagraph(versusText, versusFontSize);
    final awayParagraph = buildParagraph(awayTeamName, teamFontSize);

    final centerX = overlayRect.center.dx;
    final versusWidth = versusParagraph.maxIntrinsicWidth;
    final homeWidth = homeParagraph.maxIntrinsicWidth;

    final versusDx = centerX - (versusWidth / 2);
    final versusDy = dy;

    final homeDx = versusDx - spacing - homeWidth;
    final homeDy = dy;

    final awayDx = versusDx + versusWidth + spacing;
    final awayDy = dy;

    canvas.drawParagraph(homeParagraph, Offset(homeDx, homeDy));
    canvas.drawParagraph(versusParagraph, Offset(versusDx, versusDy));
    canvas.drawParagraph(awayParagraph, Offset(awayDx, awayDy));
  }

  drawText(
    'Convocatoria',
    y,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    align: TextAlign.left,
  );

  final matchTitleY = y + 44;
  drawMatchupLine(matchTitleY);

  const chipHeight = 26.0;
  const chipWidth = 90.0;
  final chipTop = headerRRect.outerRect.bottom - chipHeight - 16;

  final localChipRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, chipTop, chipWidth, chipHeight),
    const Radius.circular(20),
  );
  final awayChipRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      overlayRect.right - chipWidth - 28,
      chipTop,
      chipWidth,
      chipHeight,
    ),
    const Radius.circular(20),
  );

  final chipPaint = Paint()..color = Colors.white.withOpacity(0.15);
  final chipBorderPaint = Paint()
    ..color = Colors.white.withOpacity(0.7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3;

  canvas.drawRRect(localChipRect, chipPaint);
  canvas.drawRRect(localChipRect, chipBorderPaint);
  canvas.drawRRect(awayChipRect, chipPaint);
  canvas.drawRRect(awayChipRect, chipBorderPaint);

  final isHomeLocalLeft = isHome;

  void drawChipLabel(String text, RRect rect) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          )
          ..pushStyle(ui.TextStyle(color: Colors.white))
          ..addText(text);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: chipWidth));

    final offset = Offset(
      rect.left + (chipWidth - paragraph.maxIntrinsicWidth) / 2,
      rect.top + (chipHeight - paragraph.height) / 2,
    );
    canvas.drawParagraph(paragraph, offset);
  }

  if (isHomeLocalLeft) {
    drawChipLabel('LOCAL', localChipRect);
    drawChipLabel('VISITANTE', awayChipRect);
  } else {
    drawChipLabel('VISITANTE', localChipRect);
    drawChipLabel('LOCAL', awayChipRect);
  }

  final confettiPaint1 = Paint()..color = const Color(0xFFFFC107);
  final confettiPaint2 = Paint()..color = const Color(0xFFFF4081);
  final confettiPaint3 = Paint()..color = const Color(0xFF00E5FF);

  canvas.drawCircle(
    Offset(overlayRect.left + 24, overlayRect.top + 16),
    6,
    confettiPaint1,
  );
  canvas.drawCircle(
    Offset(overlayRect.right - 28, overlayRect.top + 22),
    7,
    confettiPaint2,
  );
  canvas.drawCircle(
    Offset(overlayRect.left + 80, overlayRect.top + 40),
    5,
    confettiPaint3,
  );
  canvas.drawCircle(
    Offset(overlayRect.right - 90, overlayRect.top + 48),
    5,
    confettiPaint1,
  );

  return headerRRect.outerRect.bottom + 40;
}
