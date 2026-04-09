import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/usecase/match/create_match_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/common/loading_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_state.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';

class ConvocationPage extends StatefulWidget {
  final Team team;

  const ConvocationPage({super.key, required this.team});

  @override
  State<ConvocationPage> createState() => _ConvocationPageState();
}

class _ConvocationPageState extends State<ConvocationPage> {
  final TextEditingController _rivalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Map<int, bool> _calledUp = {}; // playerId -> convocado (true/false)

  bool _isHome = true;
  String? _awayLocation;

  TimeOfDay _callTime = TimeOfDay.now();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _rivalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _calledUpCount(List<Player> players) {
    int count = 0;
    for (final p in players) {
      if (_calledUp[p.id] == true) count++;
    }
    return count;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickCallTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _callTime,
    );
    if (picked != null) {
      setState(() {
        _callTime = picked;
      });
    }
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formattedTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _toggleCalledUp(int playerId) {
    setState(() {
      final current = _calledUp[playerId] ?? false;
      _calledUp[playerId] = !current;
    });
  }

  Future<void> _pickAwayLocation() async {
    final controller = TextEditingController(text: _awayLocation ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Lugar del partido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre, dirección o lugar',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _awayLocation = text;
                  });

                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(text)}',
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Abrir en Maps'),
            ),
          ],
        );
      },
    );
  }

  Future<File?> _generateConvocationImage({
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

      // Cabecera decorada dentro de la tarjeta
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

      final homeTeamName = _isHome
          ? widget.team.name
          : _rivalController.text.trim();
      final awayTeamName = _isHome
          ? _rivalController.text.trim()
          : widget.team.name;

      final dateStr = _formattedDate(_selectedDate);
      final matchTimeStr = _formattedTime(_selectedTime);
      final callTimeStr = _formattedTime(_callTime);

      String? mapUrl;
      if (!_isHome && _awayLocation != null && _awayLocation!.isNotEmpty) {
        mapUrl =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_awayLocation!)}';
      }

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
        final maxWidth = overlayRect.width - 40;
        paragraph.layout(ui.ParagraphConstraints(width: maxWidth));

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
          paragraph.layout(
            const ui.ParagraphConstraints(width: double.infinity),
          );
          return paragraph;
        }

        final homeParagraph = buildParagraph(homeTeamName, teamFontSize);
        final versusParagraph = buildParagraph(versusText, versusFontSize);
        final awayParagraph = buildParagraph(awayTeamName, teamFontSize);

        final centerX = size.toDouble() / 2;
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

      // Título principal (alineado a la izquierda)
      drawText(
        'Convocatoria',
        y,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        align: TextAlign.left,
      );

      // Enfrentamiento con la palabra "VS" exactamente en el centro
      final matchTitleY = y + 44;
      drawMatchupLine(matchTitleY);

      // Chips de local/visitante
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

      final isHomeLocalLeft = _isHome;

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
          ..layout(ui.ParagraphConstraints(width: chipWidth));

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

      // Etiquetas de sección reutilizables
      void drawSectionLabel(String text, RRect rect) {
        final width = rect.width;
        final builder =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.left,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..pushStyle(ui.TextStyle(color: Colors.white))
              ..addText(text);

        final paragraph = builder.build()
          ..layout(ui.ParagraphConstraints(width: width - 16));

        final offset = Offset(
          rect.left + 12,
          rect.top + (rect.height - paragraph.height) / 2,
        );
        canvas.drawParagraph(paragraph, offset);
      }

      // Pequeños adornos circulares (confeti) en la cabecera
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

      // Continuamos el contenido por debajo de la cabecera
      y = headerRRect.outerRect.bottom + 40;

      // Línea separadora suave para separar cabecera de contenido
      final separatorPaint = Paint()..color = Colors.grey.shade300;
      canvas.drawRect(
        Rect.fromLTWH(overlayRect.left + 20, y, overlayRect.width - 40, 2),
        separatorPaint,
      );

      y += 26;

      // Etiqueta "Detalles del partido" con fondo de color
      const sectionTagHeight = 32.0;
      final detailsTagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(overlayRect.left + 24, y, 280, sectionTagHeight),
        const Radius.circular(16),
      );
      final detailsTagPaint = Paint()..color = const Color(0xFF1B5E20);
      canvas.drawRRect(detailsTagRect, detailsTagPaint);
      drawSectionLabel('Detalles del partido ⚽', detailsTagRect);

      y += sectionTagHeight + 28;

      // Bloque de información general
      drawText('Fecha:  $dateStr', y, fontSize: 20);
      y += 32;
      drawText('Hora partido:       $matchTimeStr', y, fontSize: 20);
      y += 30;
      drawText('Hora convocatoria:  $callTimeStr', y, fontSize: 20);
      y += 34;

      if (mapUrl != null) {
        drawText('Lugar: $_awayLocation', y, fontSize: 20);
        y += 30;
        drawText('Mapa: $mapUrl', y, fontSize: 18, color: Colors.blue);
        y += 38;
      } else {
        y += 12;
      }

      // Segundo separador
      canvas.drawRect(
        Rect.fromLTWH(overlayRect.left + 20, y, overlayRect.width - 40, 2),
        separatorPaint,
      );

      y += 26;

      // Etiqueta "Jugadores convocados" con fondo azul
      final playersTagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          overlayRect.left + 24,
          y,
          overlayRect.width - 48,
          sectionTagHeight,
        ),
        const Radius.circular(16),
      );
      final playersTagPaint = Paint()..color = const Color(0xFF0D47A1);
      canvas.drawRRect(playersTagRect, playersTagPaint);
      drawSectionLabel(
        'Jugadores convocados (${sortedPlayers.length}) ⭐',
        playersTagRect,
      );

      y += sectionTagHeight + 24;

      // Fondo suave circular detrás de la lista de jugadores
      final playersBgPaint = Paint()
        ..color = const Color(0xFF4CAF50).withOpacity(0.08);
      canvas.drawCircle(
        Offset(overlayRect.center.dx, y + 80),
        140,
        playersBgPaint,
      );

      for (final p in sortedPlayers) {
        final dorsal = (p.number?.toString() ?? '-').padLeft(2, ' ');
        final line = '•  $dorsal   ${p.fullName}';
        drawText(line, y, fontSize: 20);
        y += 30;
      }

      y += 32;
      if (_notesController.text.trim().isNotEmpty) {
        // Tercer separador para observaciones
        canvas.drawRect(
          Rect.fromLTWH(overlayRect.left + 20, y, overlayRect.width - 40, 2),
          separatorPaint,
        );

        y += 26;

        // Etiqueta "Observaciones" con fondo naranja
        final notesTagRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(overlayRect.left + 24, y, 220, sectionTagHeight),
          const Radius.circular(16),
        );
        final notesTagPaint = Paint()..color = const Color(0xFFFF8F00);
        canvas.drawRRect(notesTagRect, notesTagPaint);
        drawSectionLabel('Observaciones 📝', notesTagRect);

        y += sectionTagHeight + 26;

        drawText(
          _notesController.text.trim(),
          y,
          fontSize: 19,
          color: Colors.black87,
        );
      }

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

  Future<void> _onSavePressed() async {
    final loadingCubit = context.read<LoadingCubit>();
    if (loadingCubit.state) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para guardar la convocatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final teamState = context.read<TeamDetailCubit>().state;
    if (teamState is! TeamDetailLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido cargar la plantilla del equipo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rival = _rivalController.text.trim();
    if (rival.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes indicar un rival para la convocatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final players = teamState.players;
    final selectedPlayers = players
        .where((p) => _calledUp[p.id] == true)
        .toList();

    if (selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un jugador para convocar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final matchDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Generamos un id temporal dentro del rango de integer
    // de Postgres usando segundos desde epoch.
    final int tempMatchId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final lineups = selectedPlayers
        .map(
          (player) => MatchLineup(
            id: 0,
            playerId: player.id,
            matchId: tempMatchId,
            // En la convocatoria solo marcamos quién está citado;
            // los titulares reales se marcarán al empezar el partido.
            isStarting: false,
          ),
        )
        .toList();

    final match = Match(
      id: tempMatchId,
      teamId: widget.team.id,
      opponent: rival,
      goalsScored: 0,
      goalsConceded: 0,
      date: matchDateTime,
      hour: _formattedTime(_selectedTime),
      status: MatchStatus.notStarted,
      lineups: lineups,
      isHome: _isHome,
    );

    final createMatchUseCase = context.read<CreateMatchUseCase>();
    loadingCubit.start();
    final result = await createMatchUseCase(match, authState.user);
    if (!mounted) return;
    loadingCubit.stop();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) async {
        // Generamos la imagen de convocatoria para mostrarla y poder compartirla
        final file = await _generateConvocationImage(
          selectedPlayers: selectedPlayers,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Convocatoria guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        if (file != null) {
          // Navegamos a una pantalla que muestra la imagen y permite compartirla
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  ConvocationImagePage(team: widget.team, imageFile: file),
            ),
          );
        } else {
          // Si algo falla al generar la imagen, volvemos al equipo como antes
          final getPlayersByTeamUseCase = context
              .read<GetPlayersByTeamUseCase>();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) =>
                    TeamDetailCubit(getPlayersByTeamUseCase)
                      ..loadTeam(widget.team.id),
                child: TeamDetailPage(team: widget.team),
              ),
            ),
            (route) => route.isFirst,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _formattedDate(_selectedDate);
    final String formattedMatchTime = _formattedTime(_selectedTime);
    final String formattedCallTime = _formattedTime(_callTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convocatoria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final getPlayersByTeamUseCase = context
                .read<GetPlayersByTeamUseCase>();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      TeamDetailCubit(getPlayersByTeamUseCase)
                        ..loadTeam(widget.team.id),
                  child: TeamDetailPage(team: widget.team),
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rivalController,
                        decoration: const InputDecoration(
                          labelText: 'Rival',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isHome = !_isHome;
                        });
                      },
                      icon: Icon(_isHome ? Icons.home : Icons.flight_takeoff),
                      color: _isHome ? Colors.green : Colors.blue,
                      tooltip: _isHome
                          ? 'Partido en casa'
                          : 'Partido fuera de casa',
                    ),
                  ],
                ),
              ),
              if (!_isHome) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade50,
                          foregroundColor: Colors.blueGrey.shade900,
                        ),
                        onPressed: _pickAwayLocation,
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('Añadir ubicación (Maps)'),
                      ),
                      if (_awayLocation != null && _awayLocation!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _awayLocation!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_soccer, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          'Hora partido:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedMatchTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: _pickTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          'Hora convocatoria:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedCallTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.alarm),
                          onPressed: _pickCallTime,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              BlocBuilder<TeamDetailCubit, TeamDetailState>(
                builder: (context, state) {
                  if (state is TeamDetailLoading ||
                      state is TeamDetailInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TeamDetailError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is TeamDetailLoaded) {
                    final players = List<Player>.from(
                      state.players,
                    )..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

                    if (players.isEmpty) {
                      return const Center(
                        child: Text('No hay jugadores en la plantilla'),
                      );
                    }

                    final calledCount = _calledUpCount(players);

                    return Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: players.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final isCalled = _calledUp[player.id] ?? false;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      player.number?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      player.fullName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _toggleCalledUp(player.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCalled
                                            ? Colors.green
                                            : Colors.grey,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        isCalled ? 'Sí' : 'No',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Jugadores convocados: $calledCount',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<LoadingCubit, bool>(
                        builder: (context, isLoading) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: isLoading ? null : _onSavePressed,
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Guardar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TeamBottomBar(team: widget.team),
    );
  }
}

class ConvocationImagePage extends StatelessWidget {
  final Team team;
  final File imageFile;

  const ConvocationImagePage({
    super.key,
    required this.team,
    required this.imageFile,
  });

  void _goToTeamHome(BuildContext context) {
    final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              TeamDetailCubit(getPlayersByTeamUseCase)..loadTeam(team.id),
          child: TeamDetailPage(team: team),
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convocatoria generada'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goToTeamHome(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir imagen',
            onPressed: () async {
              await Share.shareXFiles([
                XFile(imageFile.path),
              ], text: 'Convocatoria de ${team.name}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(imageFile),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _goToTeamHome(context),
                child: const Text('Volver al equipo'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TeamBottomBar(team: team),
    );
  }
}
