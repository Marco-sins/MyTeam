import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';

import 'convocation_image_body.dart';
import 'convocation_image_header.dart';
import 'convocation_image_theme.dart';

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<ui.Image?> _decodeTeamLogo(Team team) async {
  final url = team.logoUrl?.trim();
  if (url == null || url.isEmpty) return null;

  try {
    late Uint8List bytes;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          return null;
        }
        bytes = await consolidateHttpClientResponseBytes(response);
      } finally {
        client.close(force: true);
      }
    } else if (url.startsWith('file://')) {
      final file = File.fromUri(Uri.parse(url));
      if (!await file.exists()) return null;
      bytes = await file.readAsBytes();
    } else {
      final file = File(url);
      if (!await file.exists()) return null;
      bytes = await file.readAsBytes();
    }

    if (bytes.isEmpty) return null;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// Marca de agua centrada detrás del texto (clip a la tarjeta).
void _drawTeamLogoWatermark(
  Canvas canvas,
  Rect overlayRect,
  RRect clipRrect,
  ui.Image logo,
) {
  canvas.save();
  canvas.clipRRect(clipRrect);

  final maxW = overlayRect.width * 0.52;
  final maxH = overlayRect.height * 0.40;
  final iw = logo.width.toDouble();
  final ih = logo.height.toDouble();
  final scale = (maxW / iw < maxH / ih) ? maxW / iw : maxH / ih;
  final destW = iw * scale;
  final destH = ih * scale;
  final dest = Rect.fromCenter(
    center: overlayRect.center,
    width: destW,
    height: destH,
  );
  final src = Rect.fromLTWH(0, 0, iw, ih);

  const watermarkAlpha = 0.14;
  final paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium
    ..colorFilter = const ColorFilter.matrix([
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, watermarkAlpha, 0,
    ]);

  canvas.drawImageRect(logo, src, dest, paint);
  canvas.restore();
}

Future<File?> generateConvocationImage({
  required Team team,
  required bool isHome,
  required DateTime matchDate,
  required TimeOfDay matchTime,
  required TimeOfDay callTime,
  required String rivalName,
  String? awayLocation,
  String? notes,
  required List<Player> selectedPlayers,
}) async {
  ui.Image? teamLogo;
  try {
    final size = ConvocationImageTheme.exportWidth.toInt();

    final sortedPlayers = List<Player>.from(selectedPlayers)
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

    final totalHeight = estimateConvocationCanvasHeight(
      playerCount: sortedPlayers.length,
      awayLocation: awayLocation,
      notes: notes,
    );
    final canvasH = totalHeight.roundToDouble();

    teamLogo = await _decodeTeamLogo(team);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), canvasH),
    );

    final rect = Rect.fromLTWH(0, 0, size.toDouble(), canvasH);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          ConvocationImageTheme.pitch,
          ConvocationImageTheme.pitchBright,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final overlayPaint = Paint()..color = ConvocationImageTheme.surface;
    final overlayMargin = ConvocationImageTheme.overlayMargin;
    final overlayRect = Rect.fromLTWH(
      overlayMargin,
      overlayMargin,
      size - overlayMargin * 2,
      canvasH - overlayMargin * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      overlayRect,
      Radius.circular(ConvocationImageTheme.cardCornerRadius),
    );
    canvas.drawRRect(rrect, overlayPaint);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = ConvocationImageTheme.outlineVariant.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (teamLogo != null) {
      _drawTeamLogoWatermark(canvas, overlayRect, rrect, teamLogo);
    }

    final headerBottomY = drawConvocationHeader(
      canvas: canvas,
      overlayRect: overlayRect,
      team: team,
      isHome: isHome,
      rivalName: rivalName,
    );

    final dateStr = _formatDate(matchDate);
    final matchTimeStr = _formatTimeOfDay(matchTime);
    final callTimeStr = _formatTimeOfDay(callTime);

    String? mapUrl;
    if (!isHome && awayLocation != null && awayLocation.isNotEmpty) {
      mapUrl =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(awayLocation)}';
    }

    drawConvocationBody(
      canvas: canvas,
      overlayRect: overlayRect,
      startY: headerBottomY,
      dateStr: dateStr,
      matchTimeStr: matchTimeStr,
      callTimeStr: callTimeStr,
      mapUrl: mapUrl,
      awayLocation: awayLocation,
      isHome: isHome,
      notes: notes,
      players: sortedPlayers,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, canvasH.round());
    teamLogo?.dispose();
    teamLogo = null;

    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final pngBytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/convocatoria_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  } catch (_) {
    return null;
  } finally {
    teamLogo?.dispose();
  }
}
