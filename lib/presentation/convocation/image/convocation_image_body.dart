import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';

import 'convocation_image_theme.dart';

/// Textos del PNG exportado; deben venir de [AppLocalizations] en tiempo de guardado.
class ConvocationImageCopy {
  const ConvocationImageCopy({
    required this.sectionMatchDetails,
    required this.labelDate,
    required this.labelMatchTime,
    required this.labelCallTime,
    required this.labelVenue,
    required this.sectionSquadTitle,
    required this.observationsTitle,
    required this.playerFallbackName,
  });

  final String sectionMatchDetails;
  final String labelDate;
  final String labelMatchTime;
  final String labelCallTime;
  final String labelVenue;
  final String sectionSquadTitle;
  final String observationsTitle;
  final String playerFallbackName;
}

/// Tipografía y márgenes de la sección de observaciones (PNG convocatoria).
const double _kObsTitleFontSize = 23;
const double _kObsTitleBarW = 6;
const double _kObsTitleBarH = 34;
const double _kObsTitleBlockHeight = 54;
const double _kObsGapBeforeBox = 14;
const double _kObsBoxPadH = 26;
const double _kObsBoxPadV = 28;
const double _kObsBoxRadius = 16;
const double _kObsNotesFontSize = 24;
const double _kObsNotesLineHeight = 1.52;
const int _kObsNotesMaxLines = 64;
const double _kObsBottomMargin = 36;

void _drawObservationsSectionHeader(
  Canvas canvas,
  Rect overlayRect,
  double y,
  ConvocationImagePalette palette,
  String observationsTitle,
) {
  final barRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, y + 3, _kObsTitleBarW, _kObsTitleBarH),
    const Radius.circular(3),
  );
  canvas.drawRRect(barRect, Paint()..color = palette.goldDeep);

  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: _kObsTitleFontSize,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: palette.onSurface,
            letterSpacing: -0.35,
          ),
        )
        ..addText(observationsTitle);

  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.width - 88));

  canvas.drawParagraph(
    paragraph,
    Offset(overlayRect.left + 28 + _kObsTitleBarW + 14, y),
  );
}

ui.Paragraph _layoutObservationsParagraph(
  String text,
  double width,
  ConvocationImagePalette palette,
) {
  final measurePara =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: _kObsNotesFontSize,
            fontWeight: FontWeight.w600,
            maxLines: _kObsNotesMaxLines,
            height: _kObsNotesLineHeight,
          ),
        )
        ..pushStyle(
          ui.TextStyle(color: palette.onSecondaryContainer),
        )
        ..addText(text);
  final measured = measurePara.build()
    ..layout(ui.ParagraphConstraints(width: width));
  return measured;
}

/// Altura total del PNG (coincide con el flujo de [drawConvocationBody]).
double estimateConvocationCanvasHeight({
  required int playerCount,
  required String? awayLocation,
  required String? notes,
}) {
  final m = ConvocationImageTheme.overlayMargin;
  final startY =
      m +
      ConvocationImageTheme.headerHeight +
      ConvocationImageTheme.headerBottomGap;
  var detailRows = 3;
  if (awayLocation?.trim().isNotEmpty ?? false) {
    detailRows++;
  }
  var y = startY + 216 + detailRows * 38 + playerCount * 60.0;
  final t = notes?.trim() ?? '';
  if (t.isNotEmpty) {
    final innerW = ConvocationImageTheme.exportWidth - 2 * m;
    final overlayContentW = innerW - 56;
    final notesLayoutW = overlayContentW - 2 * _kObsBoxPadH;
    final p = _layoutObservationsParagraph(t, notesLayoutW, ConvocationImagePalette.classic);
    y +=
        28 +
        28 +
        _kObsTitleBlockHeight +
        _kObsGapBeforeBox +
        2 * _kObsBoxPadV +
        p.height +
        _kObsBottomMargin;
  }
  return (y + 56 + m).ceilToDouble();
}

void drawConvocationBody({
  required Canvas canvas,
  required Rect overlayRect,
  required ConvocationImagePalette palette,
  required double startY,
  required ConvocationImageCopy copy,
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

  void drawHairline(double dy) {
    final p = Paint()
      ..color = palette.outlineVariant.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(overlayRect.left + 32, dy),
      Offset(overlayRect.right - 32, dy),
      p,
    );
  }

  drawHairline(y);
  y += 28;

  _drawSectionTitle(canvas, overlayRect, y, palette, copy.sectionMatchDetails);
  y += 40;

  y = _drawDetailRow(canvas, overlayRect, y, palette, copy.labelDate, dateStr);
  y = _drawDetailRow(
    canvas,
    overlayRect,
    y,
    palette,
    copy.labelMatchTime,
    matchTimeStr,
  );
  y = _drawDetailRow(
    canvas,
    overlayRect,
    y,
    palette,
    copy.labelCallTime,
    callTimeStr,
  );

  if (awayLocation != null && awayLocation.trim().isNotEmpty) {
    y = _drawDetailRow(
      canvas,
      overlayRect,
      y,
      palette,
      copy.labelVenue,
      awayLocation.trim(),
    );
  }

  y += 20;
  drawHairline(y);
  y += 28;

  // — Jugadores
  _drawSectionTitle(
    canvas,
    overlayRect,
    y,
    palette,
    copy.sectionSquadTitle,
    subtitle: '${players.length}',
  );
  y += 44;

  for (var i = 0; i < players.length; i++) {
    final p = players[i];
    y = _drawPlayerRow(canvas, overlayRect, y, palette, p, i.isEven, copy);
  }

  y += 28;
  final trimmedNotes = notes?.trim() ?? '';
  if (trimmedNotes.isNotEmpty) {
    drawHairline(y);
    y += 28;

    _drawObservationsSectionHeader(
      canvas,
      overlayRect,
      y,
      palette,
      copy.observationsTitle,
    );
    y += _kObsTitleBlockHeight + _kObsGapBeforeBox;

    final boxLeft = overlayRect.left + 28;
    final boxWidth = overlayRect.width - 56;
    final textWidth = boxWidth - 2 * _kObsBoxPadH;
    final measured =
        _layoutObservationsParagraph(trimmedNotes, textWidth, palette);
    final boxHeight = 2 * _kObsBoxPadV + measured.height;

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, y, boxWidth, boxHeight),
      const Radius.circular(_kObsBoxRadius),
    );
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = palette.secondaryContainer.withValues(
          alpha: 0.92,
        ),
    );
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = palette.goldDeep.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    canvas.drawParagraph(
      measured,
      Offset(boxLeft + _kObsBoxPadH, y + _kObsBoxPadV),
    );
  }
}

void _drawSectionTitle(
  Canvas canvas,
  Rect overlayRect,
  double y,
  ConvocationImagePalette palette,
  String title, {
  String? subtitle,
}) {
  final barW = 5.0;
  final barH = 26.0;
  final barRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 32, y + 2, barW, barH),
    const Radius.circular(2),
  );
  canvas.drawRRect(barRect, Paint()..color = palette.goldDeep);

  final titleText = subtitle != null ? '$title · $subtitle' : title;
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: palette.onSurface,
            letterSpacing: -0.3,
          ),
        )
        ..addText(titleText);

  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.width - 80));

  canvas.drawParagraph(paragraph, Offset(overlayRect.left + 32 + barW + 14, y));
}

double _drawDetailRow(
  Canvas canvas,
  Rect overlayRect,
  double y,
  ConvocationImagePalette palette,
  String label,
  String value,
) {
  const labelW = 220.0;
  final lx = overlayRect.left + 32;
  final vx = overlayRect.left + 32 + labelW;

  final labelPara =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            maxLines: 2,
          ),
        )
        ..pushStyle(ui.TextStyle(color: palette.onSurfaceVariant))
        ..addText(label);
  final lp = labelPara.build()
    ..layout(ui.ParagraphConstraints(width: labelW - 8));
  canvas.drawParagraph(lp, Offset(lx, y));

  final valuePara =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            maxLines: 3,
          ),
        )
        ..pushStyle(ui.TextStyle(color: palette.onSurface))
        ..addText(value);
  final vp = valuePara.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.width - labelW - 64));
  canvas.drawParagraph(vp, Offset(vx, y));

  return y + 38;
}

double _drawPlayerRow(
  Canvas canvas,
  Rect overlayRect,
  double y,
  ConvocationImagePalette palette,
  Player p,
  bool alternate,
  ConvocationImageCopy copy,
) {
  const rowH = 52.0;
  final rowRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, y, overlayRect.width - 56, rowH),
    const Radius.circular(12),
  );

  if (alternate) {
    canvas.drawRRect(
      rowRect,
      Paint()
        ..color = palette.surfaceContainer.withValues(
          alpha: 0.55,
        ),
    );
  }

  canvas.drawRRect(
    rowRect,
    Paint()
      ..color = palette.outlineVariant.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  final dorsal = p.number?.toString() ?? '–';
  const badgeSize = 36.0;
  final badgeLeft = overlayRect.left + 40;
  final badgeTop = y + (rowH - badgeSize) / 2;
  final badge = RRect.fromRectAndRadius(
    Rect.fromLTWH(badgeLeft, badgeTop, badgeSize, badgeSize),
    const Radius.circular(8),
  );
  canvas.drawRRect(
    badge,
    Paint()..color = palette.primaryContainer,
  );

  final dPara =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
            height: 1.0,
            maxLines: 1,
          ),
        )
        ..pushStyle(
          ui.TextStyle(color: palette.onPrimaryContainer),
        )
        ..addText(dorsal);
  final dp = dPara.build()..layout(ui.ParagraphConstraints(width: badgeSize));
  canvas.drawParagraph(
    dp,
    Offset(badgeLeft, badgeTop + (badgeSize - dp.height) / 2),
  );

  final nameX = badgeLeft + badgeSize + 12;
  final nameParts = playerNamePartsMatchShort(p);
  final givenName =
      nameParts.given.isEmpty ? copy.playerFallbackName : nameParts.given;
  final namePara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 18,
      maxLines: 1,
    ),
  );
  namePara.pushStyle(
    ui.TextStyle(
      color: palette.onSurface,
      fontWeight: FontWeight.w700,
    ),
  );
  namePara.addText(givenName);
  namePara.pop();
  if (nameParts.family.isNotEmpty) {
    namePara.pushStyle(
      ui.TextStyle(
        color: palette.onSurface,
        fontWeight: FontWeight.w400,
      ),
    );
    namePara.addText(' ${nameParts.family}');
    namePara.pop();
  }
  final np = namePara.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.right - 32 - nameX));
  canvas.drawParagraph(np, Offset(nameX, y + 14));

  return y + rowH + 8;
}
