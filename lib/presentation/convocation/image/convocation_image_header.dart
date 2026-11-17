import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/team.dart';

import 'convocation_image_theme.dart';

double drawConvocationHeader({
  required Canvas canvas,
  required Rect overlayRect,
  required ConvocationImagePalette palette,
  required Team team,
  required bool isHome,
  required String rivalName,
}) {
  final headerHeight = ConvocationImageTheme.headerHeight;
  final headerRRect = RRect.fromRectAndCorners(
    Rect.fromLTWH(
      overlayRect.left,
      overlayRect.top,
      overlayRect.width,
      headerHeight,
    ),
    topLeft: Radius.circular(ConvocationImageTheme.cardCornerRadius),
    topRight: Radius.circular(ConvocationImageTheme.cardCornerRadius),
  );

  final headerPaint = Paint()
    ..shader = LinearGradient(
      colors: [
        // Más oscuro arriba, más claro abajo (vertical)
        palette.pitch,
        palette.pitchBright,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(headerRRect.outerRect);
  canvas.drawRRect(headerRRect, headerPaint);

  canvas.drawRRect(
    headerRRect,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  final goldStripe = RRect.fromRectAndCorners(
    Rect.fromLTWH(
      overlayRect.left,
      overlayRect.top + headerHeight - 4,
      overlayRect.width,
      4,
    ),
    bottomLeft: const Radius.circular(0),
    bottomRight: const Radius.circular(0),
  );
  canvas.drawRRect(
    goldStripe,
    Paint()..color = palette.gold.withValues(alpha: 0.85),
  );

  double y = overlayRect.top + 20;
  final homeTeamName = isHome ? team.name : rivalName;
  final awayTeamName = isHome ? rivalName : team.name;

  // Draw "CONVOCATORIA" in the top-left corner, single line, no wrapping.
  final convocBuilder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            maxLines: 1,
            height: 1.0,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            letterSpacing: 2.4,
          ),
        )
        ..addText('CONVOCATORIA');
  final convocPara = convocBuilder.build()
    ..layout(const ui.ParagraphConstraints(width: 400));
  canvas.drawParagraph(
    convocPara,
    Offset(overlayRect.left + 28, overlayRect.top + 12),
  );

  // Skip the "Partido entre" label: we only show the centered teams below.
  y += 36;

  ui.Paragraph buildParagraph(
    String text,
    double fontSize,
    Color color,
    FontWeight w,
  ) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.left,
              fontSize: fontSize,
              fontWeight: w,
              maxLines: 2,
              height: 1.08,
            ),
          )
          ..pushStyle(ui.TextStyle(color: color))
          ..addText(text);

    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 460));
    return paragraph;
  }

  const versusText = 'vs';
  const teamFontSize = 38.0;
  const versusFontSize = 30.0;
  const spacing = 14.0;

  final homeParagraph = buildParagraph(
    homeTeamName,
    teamFontSize,
    Colors.white,
    FontWeight.w900,
  );
  final versusParagraph = buildParagraph(
    versusText,
    versusFontSize,
    palette.gold,
    FontWeight.w900,
  );
  final awayParagraph = buildParagraph(
    awayTeamName,
    teamFontSize,
    Colors.white,
    FontWeight.w900,
  );

  final lineY = y;
  final rowH = [
    homeParagraph.height,
    versusParagraph.height,
    awayParagraph.height,
  ].reduce((a, b) => a > b ? a : b);

  final centerX = overlayRect.center.dx;
  final versusWidth = versusParagraph.maxIntrinsicWidth;
  final homeWidth = homeParagraph.maxIntrinsicWidth;
  final versusDx = centerX - (versusWidth / 2);
  final homeDx = versusDx - spacing - homeWidth;
  final awayDx = versusDx + versusWidth + spacing;
  final textDy = lineY + (rowH - homeParagraph.height) / 2;

  canvas.drawParagraph(homeParagraph, Offset(homeDx, textDy));
  canvas.drawParagraph(
    versusParagraph,
    Offset(versusDx, lineY + (rowH - versusParagraph.height) / 2 + 1),
  );
  canvas.drawParagraph(awayParagraph, Offset(awayDx, textDy));

  const chipHeight = 40.0;
  const chipWidth = 128.0;
  final chipTop = headerRRect.outerRect.bottom - chipHeight - 14;

  final localChipRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, chipTop, chipWidth, chipHeight),
    const Radius.circular(10),
  );
  final awayChipRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      overlayRect.right - chipWidth - 28,
      chipTop,
      chipWidth,
      chipHeight,
    ),
    const Radius.circular(10),
  );

  void paintChip(RRect r) {
    canvas.drawRRect(r, Paint()..color = Colors.black.withValues(alpha: 0.12));
    canvas.drawRRect(
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  paintChip(localChipRect);
  paintChip(awayChipRect);

  void drawChipLabel(String text, RRect rect) {
    final inner = rect.outerRect;
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              maxLines: 2,
              height: 1.05,
            ),
          )
          ..pushStyle(ui.TextStyle(color: Colors.white, letterSpacing: 0.9))
          ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: inner.width));

    final offset = Offset(
      inner.left,
      inner.top + (inner.height - paragraph.height) / 2,
    );
    canvas.drawParagraph(paragraph, offset);
  }

  if (isHome) {
    drawChipLabel('LOCAL', localChipRect);
    drawChipLabel('VISITANTE', awayChipRect);
  } else {
    drawChipLabel('LOCAL', awayChipRect);
    drawChipLabel('VISITANTE', localChipRect);
  }

  return headerRRect.outerRect.bottom + ConvocationImageTheme.headerBottomGap;
}
