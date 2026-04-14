import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';

import 'convocation_image_theme.dart';

/// Altura total del PNG (coincide con el flujo de [drawConvocationBody]).
double estimateConvocationCanvasHeight({
  required int playerCount,
  required String? awayLocation,
  required String? notes,
}) {
  final m = ConvocationImageTheme.overlayMargin;
  final startY =
      m + ConvocationImageTheme.headerHeight + ConvocationImageTheme.headerBottomGap;
  var detailRows = 3;
  if (awayLocation?.trim().isNotEmpty ?? false) {
    detailRows++;
  }
  var y = startY + 216 + detailRows * 38 + playerCount * 60.0;
  final t = notes?.trim() ?? '';
  if (t.isNotEmpty) {
    final innerW = ConvocationImageTheme.exportWidth - 2 * m;
    final notesLayoutW = innerW - 64;
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        maxLines: 24,
        height: 1.35,
      ),
    )
      ..pushStyle(ui.TextStyle(color: ConvocationImageTheme.onSurface))
      ..addText(t);
    final p = builder.build()
      ..layout(ui.ParagraphConstraints(width: notesLayoutW));
    y += 96 + p.height;
  }
  return (y + 56 + m).ceilToDouble();
}

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

  void drawHairline(double dy) {
    final p = Paint()
      ..color = ConvocationImageTheme.outlineVariant.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(overlayRect.left + 32, dy),
      Offset(overlayRect.right - 32, dy),
      p,
    );
  }

  drawHairline(y);
  y += 28;

  _drawSectionTitle(canvas, overlayRect, y, 'Detalles del partido');
  y += 40;

  y = _drawDetailRow(canvas, overlayRect, y, 'Fecha', dateStr);
  y = _drawDetailRow(canvas, overlayRect, y, 'Hora del partido', matchTimeStr);
  y = _drawDetailRow(canvas, overlayRect, y, 'Hora convocatoria', callTimeStr);

  if (awayLocation != null && awayLocation.trim().isNotEmpty) {
    y = _drawDetailRow(canvas, overlayRect, y, 'Lugar', awayLocation.trim());
  }

  y += 20;
  drawHairline(y);
  y += 28;

  // — Jugadores
  _drawSectionTitle(
    canvas,
    overlayRect,
    y,
    'Jugadores convocados',
    subtitle: '${players.length}',
  );
  y += 44;

  for (var i = 0; i < players.length; i++) {
    final p = players[i];
    y = _drawPlayerRow(canvas, overlayRect, y, p, i.isEven);
  }

  y += 28;
  final trimmedNotes = notes?.trim() ?? '';
  if (trimmedNotes.isNotEmpty) {
    drawHairline(y);
    y += 28;

    _drawSectionTitle(canvas, overlayRect, y, 'Observaciones');
    y += 40;

    final textWidth = overlayRect.width - 64;
    final measurePara = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        maxLines: 24,
        height: 1.35,
      ),
    )
      ..pushStyle(ui.TextStyle(color: ConvocationImageTheme.onSurface))
      ..addText(trimmedNotes);
    final measured = measurePara.build()
      ..layout(ui.ParagraphConstraints(width: textWidth));

    canvas.drawParagraph(
      measured,
      Offset(overlayRect.left + 32, y),
    );
  }
}

void _drawSectionTitle(
  Canvas canvas,
  Rect overlayRect,
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
  canvas.drawRRect(barRect, Paint()..color = ConvocationImageTheme.goldDeep);

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
            color: ConvocationImageTheme.onSurface,
            letterSpacing: -0.3,
          ),
        )
        ..addText(titleText);

  final paragraph = builder.build()
    ..layout(
      ui.ParagraphConstraints(width: overlayRect.width - 80),
    );

  canvas.drawParagraph(
    paragraph,
    Offset(overlayRect.left + 32 + barW + 14, y),
  );
}

double _drawDetailRow(
  Canvas canvas,
  Rect overlayRect,
  double y,
  String label,
  String value,
) {
  const labelW = 220.0;
  final lx = overlayRect.left + 32;
  final vx = overlayRect.left + 32 + labelW;

  final labelPara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      maxLines: 2,
    ),
  )
    ..pushStyle(ui.TextStyle(color: ConvocationImageTheme.onSurfaceVariant))
    ..addText(label);
  final lp = labelPara.build()
    ..layout(ui.ParagraphConstraints(width: labelW - 8));
  canvas.drawParagraph(lp, Offset(lx, y));

  final valuePara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      maxLines: 3,
    ),
  )
    ..pushStyle(ui.TextStyle(color: ConvocationImageTheme.onSurface))
    ..addText(value);
  final vp = valuePara.build()
    ..layout(
      ui.ParagraphConstraints(width: overlayRect.width - labelW - 64),
    );
  canvas.drawParagraph(vp, Offset(vx, y));

  return y + 38;
}

double _drawPlayerRow(
  Canvas canvas,
  Rect overlayRect,
  double y,
  Player p,
  bool alternate,
) {
  const rowH = 52.0;
  final rowRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      overlayRect.left + 28,
      y,
      overlayRect.width - 56,
      rowH,
    ),
    const Radius.circular(12),
  );

  if (alternate) {
    canvas.drawRRect(
      rowRect,
      Paint()
        ..color =
            ConvocationImageTheme.surfaceContainer.withValues(alpha: 0.55),
    );
  }

  canvas.drawRRect(
    rowRect,
    Paint()
      ..color = ConvocationImageTheme.outlineVariant.withValues(alpha: 0.4)
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
    Paint()..color = ConvocationImageTheme.primaryContainer,
  );

  final dPara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      textAlign: TextAlign.center,
      height: 1.0,
      maxLines: 1,
    ),
  )
    ..pushStyle(
      ui.TextStyle(color: ConvocationImageTheme.onPrimaryContainer),
    )
    ..addText(dorsal);
  final dp = dPara.build()
    ..layout(ui.ParagraphConstraints(width: badgeSize));
  canvas.drawParagraph(
    dp,
    Offset(
      badgeLeft,
      badgeTop + (badgeSize - dp.height) / 2,
    ),
  );

  final nameX = badgeLeft + badgeSize + 12;
  final namePara = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      maxLines: 1,
    ),
  )
    ..pushStyle(ui.TextStyle(color: ConvocationImageTheme.onSurface))
    ..addText(p.fullName);
  final np = namePara.build()
    ..layout(
      ui.ParagraphConstraints(width: overlayRect.right - 32 - nameX),
    );
  canvas.drawParagraph(np, Offset(nameX, y + 14));

  return y + rowH + 8;
}
