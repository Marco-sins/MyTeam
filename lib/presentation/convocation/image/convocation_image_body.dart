import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';

import 'convocation_image_theme.dart';

/// Textos del PNG exportado; vienen de [AppLocalizations] al guardar.
class ConvocationImageCopy {
  const ConvocationImageCopy({
    required this.sectionMatchDetails,
    required this.sectionMatchDetailsSubtitle,
    required this.labelDate,
    required this.labelMatchKickoff,
    required this.labelCallArrival,
    required this.callTimeReminder,
    required this.labelVenue,
    required this.mapLinkIntro,
    required this.placeHomeHeadline,
    required this.placeHomeDetail,
    required this.placeAwayHeadline,
    required this.placeAwayNoAddressDetail,
    required this.sectionSquadTitle,
    required this.observationsTitle,
    required this.playerFallbackName,
  });

  final String sectionMatchDetails;
  final String sectionMatchDetailsSubtitle;
  final String labelDate;
  final String labelMatchKickoff;
  final String labelCallArrival;
  final String callTimeReminder;
  final String labelVenue;
  final String mapLinkIntro;
  final String placeHomeHeadline;
  final String placeHomeDetail;
  final String placeAwayHeadline;
  final String placeAwayNoAddressDetail;
  final String sectionSquadTitle;
  final String observationsTitle;
  final String playerFallbackName;
}

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

const double _sideInset = 28;
const double _blockPadH = 22;
const double _blockPadV = 20;
const double _betweenBlocks = 14;

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
  return measurePara.build()
    ..layout(ui.ParagraphConstraints(width: width));
}

({String headline, String detail, String? mapNote}) convocationPlaceCopy({
  required ConvocationImageCopy copy,
  required bool isHome,
  required String? awayLocation,
  required String? mapUrl,
}) {
  if (isHome) {
    return (
      headline: copy.placeHomeHeadline,
      detail: copy.placeHomeDetail,
      mapNote: null,
    );
  }
  final addr = awayLocation?.trim() ?? '';
  if (addr.isEmpty) {
    return (
      headline: copy.placeAwayHeadline,
      detail: copy.placeAwayNoAddressDetail,
      mapNote: null,
    );
  }
  return (
    headline: copy.placeAwayHeadline,
    detail: addr,
    mapNote: mapUrl != null ? copy.mapLinkIntro : null,
  );
}

double _measureBlockHeightSimple({
  required String label,
  required String value,
  required double valueFontSize,
  required double contentWidth,
  String? extraBelow,
}) {
  final labelPara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      maxLines: 3,
      height: 1.15,
    ),
  )
    ..pushStyle(ui.TextStyle(color: const Color(0xFF3D5246)))
    ..addText(label);
  final lp = labelPara.build()
    ..layout(ui.ParagraphConstraints(width: contentWidth));

  final valuePara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: valueFontSize,
      fontWeight: FontWeight.w900,
      maxLines: 12,
      height: 1.18,
    ),
  )
    ..pushStyle(ui.TextStyle(color: const Color(0xFF0D1F14)))
    ..addText(value);
  final vp = valuePara.build()
    ..layout(ui.ParagraphConstraints(width: contentWidth));

  var h = _blockPadV + lp.height + 12 + vp.height + _blockPadV;
  if (extraBelow != null && extraBelow.isNotEmpty) {
    final ep = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        maxLines: 14,
        height: 1.4,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFF0F5C4A)))
      ..addText(extraBelow);
    final e = ep.build()
      ..layout(ui.ParagraphConstraints(width: contentWidth));
    h += 12 + e.height;
  }
  return h;
}

double _prominentSectionTitleHeight(double textWidth, ConvocationImageCopy copy) {
  final p1 = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      height: 1.2,
      maxLines: 3,
    ),
  )
    ..pushStyle(ui.TextStyle(color: const Color(0xFF0D1F14)))
    ..addText(copy.sectionMatchDetails);
  final h1 = p1.build()
    ..layout(ui.ParagraphConstraints(width: textWidth));

  final p2 = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      maxLines: 3,
      height: 1.25,
    ),
  )
    ..pushStyle(ui.TextStyle(color: const Color(0xFF3D5246)))
    ..addText(copy.sectionMatchDetailsSubtitle);
  final h2 = p2.build()
    ..layout(ui.ParagraphConstraints(width: textWidth));

  return h1.height + 8 + h2.height + 12;
}

/// Altura total del PNG (coincide con el flujo de [drawConvocationBody]).
double estimateConvocationCanvasHeight({
  required ConvocationImageCopy copy,
  required int playerCount,
  required String? notes,
  required String dateLongStr,
  required String matchTimeStr,
  required String callTimeStr,
  required String placeValue,
  required String? mapExtra,
}) {
  final m = ConvocationImageTheme.overlayMargin;
  final startY =
      m +
      ConvocationImageTheme.headerHeight +
      ConvocationImageTheme.headerBottomGap;

  final innerW = ConvocationImageTheme.exportWidth - 2 * m;
  final contentW = innerW - 2 * _sideInset - 2 * _blockPadH;

  var y = startY;
  y += 24 + 28;
  y += _prominentSectionTitleHeight(innerW - 100, copy);

  y += _measureBlockHeightSimple(
    label: copy.labelDate,
    value: dateLongStr,
    valueFontSize: 30,
    contentWidth: contentW,
  );
  y += _betweenBlocks;

  y += _measureBlockHeightSimple(
    label: copy.labelMatchKickoff,
    value: matchTimeStr,
    valueFontSize: 40,
    contentWidth: contentW,
  );
  y += _betweenBlocks;

  y += _measureBlockHeightSimple(
    label: copy.labelCallArrival,
    value: callTimeStr,
    valueFontSize: 40,
    contentWidth: contentW,
    extraBelow: copy.callTimeReminder,
  );
  y += _betweenBlocks;

  y += _measureBlockHeightSimple(
    label: copy.labelVenue,
    value: placeValue,
    valueFontSize: 28,
    contentWidth: contentW,
    extraBelow: mapExtra,
  );

  y += 22;
  y += 28;
  y += 44;
  y += playerCount * 60.0;

  final t = notes?.trim() ?? '';
  if (t.isNotEmpty) {
    final overlayContentW = innerW - 56;
    final notesLayoutW = overlayContentW - 2 * _kObsBoxPadH;
    final p = _layoutObservationsParagraph(
      t,
      notesLayoutW,
      ConvocationImagePalette.classic,
    );
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

double _drawDetailBlock(
  Canvas canvas,
  Rect overlayRect,
  ConvocationImagePalette palette,
  double y,
  String label,
  String value, {
  double valueFontSize = 32,
  Color? valueColor,
  String? extraBelow,
  Color? extraColor,
}) {
  final contentW = overlayRect.width - 2 * _sideInset - 2 * _blockPadH;

  final valuePara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: valueFontSize,
      fontWeight: FontWeight.w900,
      maxLines: 12,
      height: 1.18,
    ),
  )
    ..pushStyle(
      ui.TextStyle(color: valueColor ?? palette.onSurface),
    )
    ..addText(value);
  final vp = valuePara.build()
    ..layout(ui.ParagraphConstraints(width: contentW));

  final labelPara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      maxLines: 4,
      height: 1.15,
    ),
  )
    ..pushStyle(ui.TextStyle(color: palette.onSurfaceVariant))
    ..addText(label);
  final lp = labelPara.build()
    ..layout(ui.ParagraphConstraints(width: contentW));

  ui.Paragraph? extraPara;
  if (extraBelow != null && extraBelow.isNotEmpty) {
    final extraBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        maxLines: 14,
        height: 1.4,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: extraColor ?? palette.tertiary,
        ),
      )
      ..addText(extraBelow);
    extraPara = extraBuilder.build()
      ..layout(ui.ParagraphConstraints(width: contentW));
  }

  final blockH =
      _blockPadV +
      lp.height +
      12 +
      vp.height +
      _blockPadV +
      (extraPara != null ? 12 + extraPara.height : 0);

  final blockRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      overlayRect.left + _sideInset,
      y,
      overlayRect.width - 2 * _sideInset,
      blockH,
    ),
    const Radius.circular(18),
  );

  canvas.drawRRect(
    blockRect,
    Paint()..color = palette.surfaceLow,
  );
  canvas.drawRRect(
    blockRect,
    Paint()
      ..color = palette.goldDeep.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final textLeft = overlayRect.left + _sideInset + _blockPadH;
  var ty = y + _blockPadV;
  canvas.drawParagraph(lp, Offset(textLeft, ty));
  ty += lp.height + 12;
  canvas.drawParagraph(vp, Offset(textLeft, ty));
  if (extraPara != null) {
    ty += vp.height + 12;
    canvas.drawParagraph(extraPara, Offset(textLeft, ty));
  }

  return y + blockH + _betweenBlocks;
}

void drawConvocationBody({
  required Canvas canvas,
  required Rect overlayRect,
  required ConvocationImagePalette palette,
  required double startY,
  required ConvocationImageCopy copy,
  required String dateLongStr,
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
      ..color = palette.outlineVariant.withValues(alpha: 0.75)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(overlayRect.left + 32, dy),
      Offset(overlayRect.right - 32, dy),
      p,
    );
  }

  drawHairline(y);
  y += 28;

  _drawProminentSectionTitle(canvas, overlayRect, palette, y, copy);
  y += _prominentSectionTitleHeight(overlayRect.width - 100, copy);

  y = _drawDetailBlock(
    canvas,
    overlayRect,
    palette,
    y,
    copy.labelDate,
    dateLongStr,
    valueFontSize: 30,
  );

  y = _drawDetailBlock(
    canvas,
    overlayRect,
    palette,
    y,
    copy.labelMatchKickoff,
    matchTimeStr,
    valueFontSize: 40,
    valueColor: palette.onSurface,
  );

  y = _drawDetailBlock(
    canvas,
    overlayRect,
    palette,
    y,
    copy.labelCallArrival,
    callTimeStr,
    valueFontSize: 40,
    valueColor: palette.tertiary,
    extraBelow: copy.callTimeReminder,
    extraColor: palette.onSurfaceVariant,
  );

  final place = convocationPlaceCopy(
    copy: copy,
    isHome: isHome,
    awayLocation: awayLocation,
    mapUrl: mapUrl,
  );
  final placeValue = '${place.headline}\n${place.detail}';
  final String? mapExtra = place.mapNote != null && mapUrl != null
      ? '${place.mapNote}\n$mapUrl'
      : null;

  y = _drawDetailBlock(
    canvas,
    overlayRect,
    palette,
    y,
    copy.labelVenue,
    placeValue,
    valueFontSize: 28,
    extraBelow: mapExtra,
    extraColor: palette.onSurfaceVariant,
  );

  y += 8;
  drawHairline(y);
  y += 28;

  _drawSectionTitle(
    canvas,
    overlayRect,
    palette,
    y,
    copy.sectionSquadTitle,
    subtitle: '${players.length}',
  );
  y += 44;

  for (var i = 0; i < players.length; i++) {
    final p = players[i];
    y = _drawPlayerRow(canvas, overlayRect, palette, y, p, i.isEven, copy);
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

void _drawProminentSectionTitle(
  Canvas canvas,
  Rect overlayRect,
  ConvocationImagePalette palette,
  double y,
  ConvocationImageCopy copy,
) {
  final barW = 8.0;
  final textW = overlayRect.width - 100;

  final measureTitle = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      height: 1.2,
      maxLines: 3,
    ),
  )
    ..pushStyle(ui.TextStyle(color: palette.onSurface))
    ..addText(copy.sectionMatchDetails);
  final mh1 = measureTitle.build()
    ..layout(ui.ParagraphConstraints(width: textW));

  final measureSub = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      maxLines: 3,
      height: 1.25,
    ),
  )
    ..pushStyle(ui.TextStyle(color: palette.onSurfaceVariant))
    ..addText(copy.sectionMatchDetailsSubtitle);
  final mh2 = measureSub.build()
    ..layout(ui.ParagraphConstraints(width: textW));
  final barH = (mh1.height + 8 + mh2.height).clamp(40.0, 80.0);

  final barRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 32, y + 4, barW, barH),
    const Radius.circular(4),
  );
  canvas.drawRRect(barRect, Paint()..color = palette.goldDeep);

  final p1 = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: 26,
      fontWeight: FontWeight.w900,
      height: 1.2,
      maxLines: 3,
    ),
  )
    ..pushStyle(
      ui.TextStyle(
        color: palette.onSurface,
        letterSpacing: -0.2,
      ),
    )
    ..addText(copy.sectionMatchDetails);
  final titlePara = p1.build()
    ..layout(ui.ParagraphConstraints(width: textW));
  canvas.drawParagraph(
    titlePara,
    Offset(overlayRect.left + 32 + barW + 14, y),
  );

  final p2 = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      maxLines: 3,
      height: 1.25,
    ),
  )
    ..pushStyle(ui.TextStyle(color: palette.onSurfaceVariant))
    ..addText(copy.sectionMatchDetailsSubtitle);
  final subPara = p2.build()
    ..layout(ui.ParagraphConstraints(width: textW));
  canvas.drawParagraph(
    subPara,
    Offset(overlayRect.left + 32 + barW + 14, y + titlePara.height + 8),
  );
}

void _drawSectionTitle(
  Canvas canvas,
  Rect overlayRect,
  ConvocationImagePalette palette,
  double y,
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

  canvas.drawParagraph(
    paragraph,
    Offset(overlayRect.left + 32 + barW + 14, y),
  );
}

double _drawPlayerRow(
  Canvas canvas,
  Rect overlayRect,
  ConvocationImagePalette palette,
  double y,
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
