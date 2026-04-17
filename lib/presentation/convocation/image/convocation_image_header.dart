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
        palette.pitchBright,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(headerRRect.outerRect);
  canvas.drawRRect(headerRRect, headerPaint);

  final goldStripe = RRect.fromRectAndCorners(
    Rect.fromLTWH(
      overlayRect.left,
      overlayRect.top + headerHeight - 5,
      overlayRect.width,
      5,
    ),
    bottomLeft: const Radius.circular(0),
    bottomRight: const Radius.circular(0),
  );
  canvas.drawRRect(
    goldStripe,
    Paint()..color = palette.gold,
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
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    align: TextAlign.left,
    letterSpacing: 3,
    height: 1.15,
  );

  y += 26;

  drawText(
    'Partido entre',
    y,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.92),
    align: TextAlign.center,
    letterSpacing: 0.3,
  );

  y += 22;

  void drawMatchupLine(double dy) {
    const versusText = 'vs';
    const teamFontSize = 46.0;
    const versusFontSize = 38.0;
    const spacing = 18.0;

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
                height: 1.05,
              ),
            )
            ..pushStyle(ui.TextStyle(color: color))
            ..addText(text);

      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));
      return paragraph;
    }

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

    final centerX = overlayRect.center.dx;
    final versusWidth = versusParagraph.maxIntrinsicWidth;
    final homeWidth = homeParagraph.maxIntrinsicWidth;

    final versusDx = centerX - (versusWidth / 2);
    final homeDx = versusDx - spacing - homeWidth;
    final awayDx = versusDx + versusWidth + spacing;

    canvas.drawParagraph(homeParagraph, Offset(homeDx, dy));
    canvas.drawParagraph(versusParagraph, Offset(versusDx, dy + 5));
    canvas.drawParagraph(awayParagraph, Offset(awayDx, dy));
  }

  drawMatchupLine(y);

  const chipHeight = 44.0;
  const chipWidth = 138.0;
  final chipTop = headerRRect.outerRect.bottom - chipHeight - 18;

  final localChipRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, chipTop, chipWidth, chipHeight),
    const Radius.circular(12),
  );
  final awayChipRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      overlayRect.right - chipWidth - 28,
      chipTop,
      chipWidth,
      chipHeight,
    ),
    const Radius.circular(12),
  );

  final chipFill = Paint()..color = palette.goldDeep;
  final chipBorder = Paint()
    ..color = Colors.white.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  canvas.drawRRect(localChipRect, chipFill);
  canvas.drawRRect(localChipRect, chipBorder);
  canvas.drawRRect(awayChipRect, chipFill);
  canvas.drawRRect(awayChipRect, chipBorder);

  void drawChipLabel(String text, RRect rect) {
    final inner = rect.outerRect;
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              maxLines: 2,
              height: 1.05,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: Colors.white,
              letterSpacing: 1.2,
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
