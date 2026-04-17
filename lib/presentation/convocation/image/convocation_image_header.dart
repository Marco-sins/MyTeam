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
        palette.pitch,
        Color.lerp(palette.pitch, palette.pitchBright, 0.35)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
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

  void drawText(
    String text,
    double dy, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
    TextAlign align = TextAlign.left,
    double? letterSpacing,
    double? height,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: align,
              fontSize: fontSize,
              fontWeight: fontWeight,
              maxLines: 4,
              height: height,
            ),
          )
          ..pushStyle(
            ui.TextStyle(color: color, letterSpacing: letterSpacing),
          )
          ..addText(text);

    final paragraph = builder.build();
    const maxWidth = 980.0;
    paragraph.layout(const ui.ParagraphConstraints(width: maxWidth));

    double dx;
    if (align == TextAlign.center) {
      dx =
          overlayRect.left +
          (overlayRect.width - paragraph.maxIntrinsicWidth) / 2;
    } else if (align == TextAlign.right) {
      dx = overlayRect.right - paragraph.maxIntrinsicWidth - 32;
    } else {
      dx = overlayRect.left + 28;
    }

    canvas.drawParagraph(paragraph, Offset(dx, dy));
  }

  drawText(
    'CONVOCATORIA',
    y,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: Colors.white.withValues(alpha: 0.88),
    align: TextAlign.center,
    letterSpacing: 2.4,
    height: 1.0,
  );

  y += 22;

  drawText(
    'Partido entre',
    y,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.78),
    align: TextAlign.center,
    letterSpacing: 0.6,
    height: 1.2,
  );

  y += 18;

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
    canvas.drawRRect(
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
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
          ..pushStyle(
            ui.TextStyle(
              color: Colors.white,
              letterSpacing: 0.9,
            ),
          )
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
    drawChipLabel('VISITANTE', localChipRect);
    drawChipLabel('LOCAL', awayChipRect);
  }

  return headerRRect.outerRect.bottom + ConvocationImageTheme.headerBottomGap;
}
