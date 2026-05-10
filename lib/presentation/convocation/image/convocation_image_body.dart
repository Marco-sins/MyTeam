import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/core/utils/player_name_parts.dart';
import 'package:football_manager/domain/entities/player.dart';

import 'convocation_image_theme.dart';

/// Textos del PNG exportado; vienen de [AppLocalizations] al guardar.
class ConvocationImageCopy {
  const ConvocationImageCopy({
    required this.sectionMatchDetails,
    required this.labelTeam,
    required this.labelFixture,
    required this.labelCallDateTime,
    required this.labelMatchKickoff,
    required this.labelMeetingVenue,
    required this.labelMatchVenue,
    required this.venueHomeInstallations,
    required this.callTimeReminder,
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
  final String labelTeam;
  final String labelFixture;
  final String labelCallDateTime;
  final String labelMatchKickoff;
  final String labelMeetingVenue;
  final String labelMatchVenue;
  final String venueHomeInstallations;
  final String callTimeReminder;
  final String mapLinkIntro;
  final String placeHomeHeadline;
  final String placeHomeDetail;
  final String placeAwayHeadline;
  final String placeAwayNoAddressDetail;
  final String sectionSquadTitle;
  final String observationsTitle;
  final String playerFallbackName;
}

const double _kObsTitleFontSize = 22;
const double _kObsTitleBarW = 4;
const double _kObsTitleBarH = 28;
const double _kObsTitleBlockHeight = 48;
const double _kObsGapBeforeBox = 12;
const double _kObsBoxPadH = 22;
const double _kObsBoxPadV = 22;
const double _kObsBoxRadius = 14;
const double _kObsNotesFontSize = 20;
const double _kObsNotesLineHeight = 1.45;
const int _kObsNotesMaxLines = 64;
const double _kObsBottomMargin = 36;

const double _sideInset = 20;
// Narrower label column for a more minimal, compact match-details block.
const double _kLabelColW = 180;
const double _kRowPadV = 12;
const double _kAfterSectionTitle = 18;
const double _kBetweenBlocks = 14;

({String meeting, String matchVenue, String? mapExtra})
convocationVenueStrings({
  required ConvocationImageCopy copy,
  required bool isHome,
  required String? awayLocation,
  required String? mapUrl,
}) {
  // Show exactly what is provided in the location field, no defaults.
  if (isHome) {
    // For home: empty unless explicitly provided by the user elsewhere.
    return (meeting: '', matchVenue: '', mapExtra: null);
  }
  final addr = awayLocation?.trim() ?? '';
  // For away: show the address as-is, no extra headers or footers.
  return (meeting: addr, matchVenue: addr, mapExtra: null);
}

void _drawObservationsSectionHeader(
  Canvas canvas,
  Rect overlayRect,
  double y,
  ConvocationImagePalette palette,
  String observationsTitle,
) {
  final barRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, y + 4, _kObsTitleBarW, _kObsTitleBarH),
    const Radius.circular(2),
  );
  canvas.drawRRect(barRect, Paint()..color = palette.goldDeep);

  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: _kObsTitleFontSize,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        )
        ..pushStyle(ui.TextStyle(color: palette.onSurface))
        ..addText(observationsTitle);

  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.width - 88));

  canvas.drawParagraph(
    paragraph,
    Offset(overlayRect.left + 28 + _kObsTitleBarW + 12, y),
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
        ..pushStyle(ui.TextStyle(color: palette.onSurfaceVariant))
        ..addText(text);
  return measurePara.build()..layout(ui.ParagraphConstraints(width: width));
}

ui.Paragraph _layoutLabelPara(String label, double w, Color color) {
  // Use same font/size as values to satisfy "misma letra" requirement.
  final p =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            maxLines: 6,
            height: 1.15,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(label);
  return p.build()..layout(ui.ParagraphConstraints(width: w));
}

ui.Paragraph _layoutValuePara(String value, double w, Color color) {
  // Match label font to value font: same size and weight for a uniform look.
  final p =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            maxLines: 16,
            height: 1.18,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(value);
  return p.build()..layout(ui.ParagraphConstraints(width: w));
}

ui.Paragraph? _layoutFootnotePara(String? text, double w, Color color) {
  if (text == null || text.isEmpty) return null;
  final p =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            maxLines: 8,
            height: 1.35,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);
  return p.build()..layout(ui.ParagraphConstraints(width: w));
}

double _rowHeightForKeyValue({
  required String label,
  required String value,
  required String? footnote,
  required String? extraBelow,
  required double valueColumnW,
  required Color labelColor,
  required Color valueColor,
  required Color footColor,
}) {
  final lp = _layoutLabelPara(label, _kLabelColW, labelColor);
  final vp = _layoutValuePara(value, valueColumnW, valueColor);
  final fp = _layoutFootnotePara(footnote, valueColumnW, footColor);
  final ep = _layoutFootnotePara(extraBelow, valueColumnW, footColor);
  final valueColH =
      vp.height +
      (fp != null ? 6 + fp.height : 0) +
      (ep != null ? 10 + ep.height : 0);
  return _kRowPadV + math.max(lp.height, valueColH) + _kRowPadV;
}

double _measureMatchDetailsBlockHeight({
  required ConvocationImageCopy copy,
  required String teamName,
  required String fixtureLine,
  required String callDateTimeStr,
  required String matchTimeStr,
  required String meetingVenue,
  required String matchVenue,
  required String? mapExtra,
  required ConvocationImagePalette palette,
  required double valueColumnW,
}) {
  const dividerH = 1.0;
  var h = _kAfterSectionTitle;

  // Only show minimal match details: fecha, hora de partido, hora de convocatoria, lugar
  // callDateTimeStr comes in format 'dd/mm/yyyy - HH:MM' — extract date and time.
  final split = callDateTimeStr.split(' - ');
  final dateOnly = split.isNotEmpty ? split[0] : callDateTimeStr;
  final callTimeOnly = split.length > 1 ? split[1] : '';

  h +=
      _rowHeightForKeyValue(
        label: 'Fecha',
        value: dateOnly,
        footnote: null,
        extraBelow: null,
        valueColumnW: valueColumnW,
        labelColor: palette.onSurfaceVariant,
        valueColor: palette.onSurface,
        footColor: palette.onSurfaceVariant,
      ) +
      dividerH;

  h +=
      _rowHeightForKeyValue(
        label: copy.labelMatchKickoff,
        value: matchTimeStr,
        footnote: null,
        extraBelow: null,
        valueColumnW: valueColumnW,
        labelColor: palette.onSurfaceVariant,
        valueColor: palette.onSurface,
        footColor: palette.onSurfaceVariant,
      ) +
      dividerH;

  h +=
      _rowHeightForKeyValue(
        label: copy.labelCallDateTime,
        value: callTimeOnly,
        footnote: null,
        extraBelow: null,
        valueColumnW: valueColumnW,
        labelColor: palette.onSurfaceVariant,
        valueColor: palette.onSurface,
        footColor: palette.onSurfaceVariant,
      ) +
      dividerH;

  h +=
      _rowHeightForKeyValue(
        label: copy.labelMatchKickoff,
        value: matchTimeStr,
        footnote: null,
        extraBelow: null,
        valueColumnW: valueColumnW,
        labelColor: palette.onSurfaceVariant,
        valueColor: palette.onSurface,
        footColor: palette.onSurfaceVariant,
      ) +
      dividerH;

  h += _rowHeightForKeyValue(
    label: copy.labelMeetingVenue,
    value: meetingVenue,
    footnote: null,
    extraBelow: null,
    valueColumnW: valueColumnW,
    labelColor: palette.onSurfaceVariant,
    valueColor: palette.onSurface,
    footColor: palette.onSurfaceVariant,
  );

  return h;
}

double _sectionTitleHeight(double width, String title, Color color) {
  final p =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            maxLines: 2,
            height: 1.15,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(title);
  final para = p.build()..layout(ui.ParagraphConstraints(width: width));
  return para.height;
}

/// Altura total del PNG (coincide con el flujo de [drawConvocationBody]).
double estimateConvocationCanvasHeight({
  required ConvocationImageCopy copy,
  required int playerCount,
  required String? notes,
  required String teamName,
  required String fixtureLine,
  required String callDateTimeStr,
  required String matchTimeStr,
  required String meetingVenue,
  required String matchVenue,
  required String? mapExtra,
  required ConvocationImagePalette palette,
}) {
  final m = ConvocationImageTheme.overlayMargin;
  final startY =
      m +
      ConvocationImageTheme.headerHeight +
      ConvocationImageTheme.headerBottomGap;

  final innerW = ConvocationImageTheme.exportWidth - 2 * m;
  final valueColumnW = innerW - 2 * _sideInset - _kLabelColW - 16;

  var y = startY;
  y += 22;
  y +=
      _sectionTitleHeight(
        innerW - 56,
        copy.sectionMatchDetails,
        palette.onSurface,
      ) +
      8 +
      _kAfterSectionTitle;

  y += _measureMatchDetailsBlockHeight(
    copy: copy,
    teamName: teamName,
    fixtureLine: fixtureLine,
    callDateTimeStr: callDateTimeStr,
    matchTimeStr: matchTimeStr,
    meetingVenue: meetingVenue,
    matchVenue: matchVenue,
    mapExtra: mapExtra,
    palette: palette,
    valueColumnW: valueColumnW,
  );

  y += _kBetweenBlocks + 8;
  y += 26;
  y += 40;
  y += playerCount * 62.0;

  final t = notes?.trim() ?? '';
  if (t.isNotEmpty) {
    final overlayContentW = innerW - 56;
    final notesLayoutW = overlayContentW - 2 * _kObsBoxPadH;
    final p = _layoutObservationsParagraph(t, notesLayoutW, palette);
    y +=
        22 +
        26 +
        _kObsTitleBlockHeight +
        _kObsGapBeforeBox +
        2 * _kObsBoxPadV +
        p.height +
        _kObsBottomMargin;
  }

  return (y + 52 + m).ceilToDouble();
}

void _drawSectionDivider(Canvas canvas, Rect overlayRect, double y) {
  final w = overlayRect.width - 56;
  final left = overlayRect.left + 28;
  canvas.drawLine(
    Offset(left, y),
    Offset(left + w, y),
    Paint()
      ..color = const Color(0xFFADCCB8).withValues(alpha: 0.4)
      ..strokeWidth = 1,
  );
}

double _drawKeyValueRow(
  Canvas canvas,
  Rect overlayRect,
  ConvocationImagePalette palette,
  double y,
  String label,
  String value, {
  String? footnote,
  String? extraBelow,
  bool drawDividerBelow = true,
}) {
  final contentLeft = overlayRect.left + _sideInset;
  final contentW = overlayRect.width - 2 * _sideInset;
  final valueColW = contentW - _kLabelColW - 16;

  final lp = _layoutLabelPara(label, _kLabelColW, palette.onSurfaceVariant);
  final vp = _layoutValuePara(value, valueColW, palette.onSurface);
  final fp = _layoutFootnotePara(footnote, valueColW, palette.onSurfaceVariant);
  final ep = _layoutFootnotePara(
    extraBelow,
    valueColW,
    palette.onSurfaceVariant,
  );

  final valueColH =
      vp.height +
      (fp != null ? 6 + fp.height : 0) +
      (ep != null ? 10 + ep.height : 0);
  final rowInnerH = math.max(lp.height, valueColH);
  final rowH = _kRowPadV + rowInnerH + _kRowPadV;

  final baseY = y + _kRowPadV;
  canvas.drawParagraph(lp, Offset(contentLeft, baseY));

  final vx = contentLeft + _kLabelColW + 16;
  canvas.drawParagraph(vp, Offset(vx, baseY));
  var vy = baseY + vp.height + 6;
  if (fp != null) {
    canvas.drawParagraph(fp, Offset(vx, vy));
    vy += fp.height + 8;
  }
  if (ep != null) {
    canvas.drawParagraph(ep, Offset(vx, vy));
  }

  var bottom = y + rowH;
  if (drawDividerBelow) {
    canvas.drawLine(
      Offset(contentLeft, bottom),
      Offset(contentLeft + contentW, bottom),
      Paint()
        ..color = palette.outlineVariant.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );
    bottom += 1;
  }

  return bottom;
}

void drawConvocationBody({
  required Canvas canvas,
  required Rect overlayRect,
  required ConvocationImagePalette palette,
  required double startY,
  required ConvocationImageCopy copy,
  required String teamName,
  required String fixtureLine,
  required String callDateTimeStr,
  required String matchTimeStr,
  required String? mapUrl,
  required String? awayLocation,
  required bool isHome,
  required String? notes,
  required List<Player> players,
}) {
  double y = startY;

  _drawSectionDivider(canvas, overlayRect, y);
  y += 22;

  final titleW = overlayRect.width - 56;
  final titlePara =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            maxLines: 2,
            height: 1.15,
          ),
        )
        ..pushStyle(ui.TextStyle(color: palette.onSurface))
        ..addText(copy.sectionMatchDetails);
  final tp = titlePara.build()..layout(ui.ParagraphConstraints(width: titleW));
  canvas.drawParagraph(tp, Offset(overlayRect.left + 28, y));
  y += tp.height + 8 + _kAfterSectionTitle;

  final venues = convocationVenueStrings(
    copy: copy,
    isHome: isHome,
    awayLocation: awayLocation,
    mapUrl: mapUrl,
  );

  // Only show minimal details: fecha, hora de partido, hora de convocatoria, lugar
  final split = callDateTimeStr.split(' - ');
  final dateOnly = split.isNotEmpty ? split[0] : callDateTimeStr;
  final callTimeOnly = split.length > 1 ? split[1] : '';

  // Helper: format text to "minúscula con primera mayúscula"
  String fmt(String s) {
    final t = (s.trim());
    if (t.isEmpty) return '';
    final lower = t.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  y = _drawKeyValueRow(
    canvas,
    overlayRect,
    palette,
    y,
    'Fecha',
    fmt(dateOnly),
    drawDividerBelow: true,
  );

  y = _drawKeyValueRow(
    canvas,
    overlayRect,
    palette,
    y,
    fmt(copy.labelMatchKickoff),
    fmt(matchTimeStr),
    drawDividerBelow: true,
  );

  y = _drawKeyValueRow(
    canvas,
    overlayRect,
    palette,
    y,
    fmt(copy.labelCallDateTime),
    fmt(callTimeOnly),
    drawDividerBelow: true,
  );

  y = _drawKeyValueRow(
    canvas,
    overlayRect,
    palette,
    y,
    fmt(copy.labelMeetingVenue),
    fmt(venues.meeting),
    drawDividerBelow: false,
  );

  y += _kBetweenBlocks + 8;
  _drawSectionDivider(canvas, overlayRect, y);
  y += 26;

  _drawSectionTitle(
    canvas,
    overlayRect,
    palette,
    y,
    copy.sectionSquadTitle,
    subtitle: '${players.length}',
  );
  y += 40;

  for (var i = 0; i < players.length; i++) {
    final p = players[i];
    y = _drawPlayerRow(canvas, overlayRect, palette, y, p, i.isEven, copy);
  }

  y += 24;
  final trimmedNotes = notes?.trim() ?? '';
  if (trimmedNotes.isNotEmpty) {
    _drawSectionDivider(canvas, overlayRect, y);
    y += 22;

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
    final measured = _layoutObservationsParagraph(
      trimmedNotes,
      textWidth,
      palette,
    );
    final boxHeight = 2 * _kObsBoxPadV + measured.height;

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, y, boxWidth, boxHeight),
      const Radius.circular(_kObsBoxRadius),
    );
    // Highlight observations using the team's secondary container color
    // for stronger emphasis and better contrast with the body.
    canvas.drawRRect(
      boxRect,
      Paint()..color = palette.secondaryContainer.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = palette.outlineVariant.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
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
  ConvocationImagePalette palette,
  double y,
  String title, {
  String? subtitle,
}) {
  final barW = 4.0;
  final barH = 24.0;
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
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        )
        ..pushStyle(ui.TextStyle(color: palette.onSurface))
        ..addText(titleText);

  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.width - 84));

  canvas.drawParagraph(paragraph, Offset(overlayRect.left + 32 + barW + 12, y));
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
  const rowH = 54.0;
  final rowRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(overlayRect.left + 28, y, overlayRect.width - 56, rowH),
    const Radius.circular(12),
  );

  if (alternate) {
    canvas.drawRRect(
      rowRect,
      Paint()..color = palette.surfaceContainer.withValues(alpha: 0.35),
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
    const Radius.circular(9),
  );
  canvas.drawRRect(
    badge,
    Paint()..color = palette.primaryContainer.withValues(alpha: 0.9),
  );
  canvas.drawRRect(
    badge,
    Paint()
      ..color = palette.outlineVariant.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  final dPara =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            textAlign: TextAlign.center,
            height: 1.0,
            maxLines: 1,
          ),
        )
        ..pushStyle(ui.TextStyle(color: palette.onPrimaryContainer))
        ..addText(dorsal);
  final dp = dPara.build()..layout(ui.ParagraphConstraints(width: badgeSize));
  canvas.drawParagraph(
    dp,
    Offset(badgeLeft, badgeTop + (badgeSize - dp.height) / 2),
  );

  final nameX = badgeLeft + badgeSize + 14;
  final nameParts = playerNamePartsMatchShort(p);
  final givenName = nameParts.given.isEmpty
      ? copy.playerFallbackName
      : nameParts.given;
  final namePara = ui.ParagraphBuilder(
    ui.ParagraphStyle(fontSize: 17, maxLines: 1),
  );
  namePara.pushStyle(
    ui.TextStyle(color: palette.onSurface, fontWeight: FontWeight.w800),
  );
  namePara.addText(givenName);
  namePara.pop();
  if (nameParts.family.isNotEmpty) {
    namePara.pushStyle(
      ui.TextStyle(
        color: palette.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
    namePara.addText(' ${nameParts.family}');
    namePara.pop();
  }
  final np = namePara.build()
    ..layout(ui.ParagraphConstraints(width: overlayRect.right - 32 - nameX));
  canvas.drawParagraph(np, Offset(nameX, y + 16));

  return y + rowH + 8;
}
