import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';

import 'convocation_image_body.dart';
import 'convocation_image_header.dart';

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
  try {
    final size = 1080;

    final sortedPlayers = List<Player>.from(selectedPlayers)
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

    final baseHeight = 820;
    final playersHeight = sortedPlayers.length * 40;
    final totalHeight = baseHeight + playersHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), totalHeight.toDouble()),
    );

    final rect = Rect.fromLTWH(0, 0, size.toDouble(), totalHeight.toDouble());
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final overlayPaint = Paint()..color = Colors.white.withOpacity(0.92);
    const overlayMargin = 40.0;
    final overlayRect = Rect.fromLTWH(
      overlayMargin,
      overlayMargin,
      size - overlayMargin * 2,
      totalHeight - overlayMargin * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      overlayRect,
      const Radius.circular(32),
    );
    canvas.drawRRect(rrect, overlayPaint);

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
      notes: notes,
      players: sortedPlayers,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, totalHeight);
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
  }
}
