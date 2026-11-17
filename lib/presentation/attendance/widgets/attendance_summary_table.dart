import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendances_use_case.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/common/widgets/player_stats_dialog_widgets.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';
import 'package:football_manager/core/utils/attendance_date_format.dart';
import 'package:football_manager/l10n/app_localizations.dart';

class AttendanceSummaryTable extends StatefulWidget {
  final Team team;
  final List<Player> players;

  /// Si es true (p. ej. admin del equipo), se muestra columna de foto a la izquierda.
  final bool showPlayerPhotos;

  const AttendanceSummaryTable({
    super.key,
    required this.team,
    required this.players,
    this.showPlayerPhotos = false,
  });

  @override
  State<AttendanceSummaryTable> createState() => _AttendanceSummaryTableState();
}

class _AttendanceSummaryTableState extends State<AttendanceSummaryTable> {
  /// Un solo Future por montaje / equipo; si se recrea en cada [build], el
  /// [FutureBuilder] vuelve a [waiting] en cada scroll/rebuild.
  Future<_AttendanceMatrix>? _matrixFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _matrixFuture ??= _loadMatrix(context.read<GetAttendancesUseCase>());
  }

  @override
  void didUpdateWidget(AttendanceSummaryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team.id != widget.team.id) {
      _matrixFuture = _loadMatrix(context.read<GetAttendancesUseCase>());
    }
  }

  Future<_AttendanceMatrix> _loadMatrix(
    GetAttendancesUseCase getAttendances,
  ) async {
    final result = await getAttendances();
    return result.fold((failure) => const _AttendanceMatrix.empty(), (
      attendances,
    ) {
      // Filtramos por equipo
      final teamAttendances = attendances
          .where((a) => a.teamId == widget.team.id)
          .toList();

      if (teamAttendances.isEmpty) {
        return const _AttendanceMatrix.empty();
      }

      // Obtenemos los últimos 6 días registrados (distintos)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final datesSet = teamAttendances
          .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
          .toSet()
          .toList();

      // Ordenamos por cercanía al día de hoy (diferencia en días),
      // de modo que el día más cercano quede más "centrado" visualmente,
      // y los días más lejanos se vayan sumando hacia la derecha.
      datesSet.sort((a, b) {
        final da = (today.difference(a).inDays).abs();
        final db = (today.difference(b).inDays).abs();
        if (da != db) return da.compareTo(db);
        // A igualdad de distancia, más reciente primero
        return b.compareTo(a);
      });

      final recentDates = datesSet.take(6).toList();

      // Construimos matriz playerId -> date -> attendance
      final Map<int, Map<DateTime, Attendance>> matrix = {};
      for (final att in teamAttendances) {
        final keyDate = DateTime(att.date.year, att.date.month, att.date.day);
        if (!recentDates.contains(keyDate)) continue;
        matrix.putIfAbsent(att.playerId, () => {});
        matrix[att.playerId]![keyDate] = att;
      }

      return _AttendanceMatrix(dates: recentDates, data: matrix);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fut = _matrixFuture;
    if (fut == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<_AttendanceMatrix>(
      future: fut,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Aunque no haya asistencias, siempre mostramos la plantilla.
        final matrix = snapshot.data ?? const _AttendanceMatrix.empty();
        // Ordenamos jugadores por dorsal para las filas
        final sortedPlayers = List<Player>.from(widget.players)
          ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

        return LayoutBuilder(
          builder: (context, constraints) {
            final l10n = AppLocalizations.of(context)!;
            // Ancho mínimo de la tabla adaptable al tamaño de pantalla
            // (más estrecha en móviles, más ancha en pantallas grandes).
            final double tableMinWidth = constraints.maxWidth.clamp(0.0, 700.0);

            return _AttendancePlantillaHorizontalScroll(
              constraints: constraints,
              tableMinWidth: tableMinWidth,
              matrix: matrix,
              sortedPlayers: sortedPlayers,
              l10n: l10n,
              showPlayerPhotos: widget.showPlayerPhotos,
              buildCell: _buildCell,
              onPlayerTap: (player) =>
                  _showPlayerStatsDialog(context, player, matrix),
            );
          },
        );
      },
    );
  }

  Widget _buildCell(
    BuildContext context,
    _AttendanceMatrix matrix,
    int playerId,
    DateTime date,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final attForPlayer = matrix.data[playerId];
    if (attForPlayer == null || !attForPlayer.containsKey(date)) {
      return Icon(
        Icons.remove_circle_outline_rounded,
        size: 20,
        color: scheme.error.withValues(alpha: 0.85),
      );
    }
    final attendance = attForPlayer[date]!;
    return Icon(
      attendance.attended ? Icons.check_circle_rounded : Icons.cancel_rounded,
      size: 20,
      color: attendance.attended
          ? scheme.primary
          : scheme.error.withValues(alpha: 0.85),
    );
  }

  void _showPlayerStatsDialog(
    BuildContext context,
    Player player,
    _AttendanceMatrix matrix,
  ) {
    final dates = matrix.dates;
    int attendedCount = 0;
    int totalCount = dates.length;

    if (totalCount > 0) {
      for (final date in dates) {
        final attForPlayer = matrix.data[player.id];
        final att = attForPlayer != null ? attForPlayer[date] : null;
        if (att != null && att.attended) {
          attendedCount++;
        }
      }
    }

    final attendancePercent = totalCount > 0
        ? ((attendedCount / totalCount) * 100).toStringAsFixed(1)
        : '0.0';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;
        final l10n = AppLocalizations.of(ctx)!;
        final matchAvg = player.stats?.averageMatchRating;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 340,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            scheme.primaryContainer,
                            scheme.surface,
                            0.35,
                          )!.withValues(alpha: 0.95),
                          scheme.surface,
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.shadow.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                  spreadRadius: -2,
                                ),
                              ],
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: PlayerPhotoRect(
                              player: player,
                              width: 90,
                              height: 120,
                              borderRadius: 15,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PlayerNameText(
                                  player: player,
                                  mode: PlayerNameTextMode.general,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleLarge?.copyWith(
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (matchAvg != null) ...[
                                  const SizedBox(height: 8),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.tertiaryContainer
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: scheme.tertiary.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.grade_rounded,
                                            size: 16,
                                            color: scheme.onTertiaryContainer,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              l10n.attendancePlayerDialogAverageMatchRating(
                                                matchAvg.toStringAsFixed(1),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                              style: textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: scheme
                                                        .onTertiaryContainer,
                                                    letterSpacing: 0.1,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: scheme.secondaryContainer
                                            .withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: scheme.onSecondaryContainer
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.tag_rounded,
                                              size: 16,
                                              color:
                                                  scheme.onSecondaryContainer,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Dorsal ${player.number?.toString() ?? '—'}',
                                              style: textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: scheme
                                                        .onSecondaryContainer,
                                                    letterSpacing: 0.1,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              player.getAnioNacimiento.isNotEmpty
                                                  ? '\tAño (${player.getAnioNacimiento})'
                                                  : '',
                                              style: textTheme.labelLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: scheme.onSecondaryContainer
                                                    .withValues(alpha: 0.75),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (player.positions != null &&
                            player.positions!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sports_soccer_outlined,
                                  size: 20,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    player.positions!
                                        .map((p) => p.name)
                                        .join(', '),
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      const PlayerStatsDialogSectionTitle(
                        'Entrenamientos (fechas de la tabla)',
                      ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                            child: PlayerStatsDialogStatCell(
                              label: 'Entrenos',
                              value: '$attendedCount/$totalCount',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PlayerStatsDialogStatCell(
                              label: '% Asistencia',
                              value: '$attendancePercent%',
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(height: 22),
                      const PlayerStatsDialogSectionTitle(
                        'Partidos (datos guardados)',
                      ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (_) {
                            final s = player.stats ?? const PlayerStats();
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                    child: PlayerStatsDialogStatCell(
                                      label: 'Partidos jugados',
                                      value: s.matchesPlayed.toString(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PlayerStatsDialogStatCell(
                                      label: 'Como titular',
                                      value: s.timesStarted.toString(),
                                    ),
                                  ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                    child: PlayerStatsDialogStatCell(
                                      label: 'Goles',
                                      value: s.goals.toString(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PlayerStatsDialogStatCell(
                                      label: 'Asistencias',
                                      value: s.assists.toString(),
                                    ),
                                  ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                    child: PlayerStatsDialogStatCell(
                                      label: 'Minutos',
                                      value: s.minutesPlayed.toString(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PlayerStatsDialogStatCell(
                                      label: 'Tarjetas (A/R)',
                                      value: '${s.yellowCards}/${s.redCards}',
                                    ),
                                  ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.dialogClose),
            ),
          ],
        );
      },
    );
  }
}

/// Tabla de plantilla: scroll horizontal con carril fijo bajo las filas (la barra
/// no se dibuja encima de la tabla). El vertical lo aporta el padre (card).
class _AttendancePlantillaHorizontalScroll extends StatefulWidget {
  final BoxConstraints constraints;
  final double tableMinWidth;
  final _AttendanceMatrix matrix;
  final List<Player> sortedPlayers;
  final AppLocalizations l10n;
  final bool showPlayerPhotos;
  final Widget Function(
    BuildContext context,
    _AttendanceMatrix matrix,
    int playerId,
    DateTime date,
  )
  buildCell;
  final void Function(Player player) onPlayerTap;

  const _AttendancePlantillaHorizontalScroll({
    required this.constraints,
    required this.tableMinWidth,
    required this.matrix,
    required this.sortedPlayers,
    required this.l10n,
    required this.showPlayerPhotos,
    required this.buildCell,
    required this.onPlayerTap,
  });

  @override
  State<_AttendancePlantillaHorizontalScroll> createState() =>
      _AttendancePlantillaHorizontalScrollState();
}

/// Altura del carril horizontal (línea + pista fina; no solapa filas).
const double _kHorizontalScrollLaneHeight = 24;

class _AttendancePlantillaHorizontalScrollState
    extends State<_AttendancePlantillaHorizontalScroll> {
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final outline = scheme.outline.withValues(alpha: 0.5);
    const photoColWidth = 56.0;
    const avatarRadius = 18.0;

    Widget tableContent() {
      return Theme(
        data: theme.copyWith(
          dataTableTheme: DataTableThemeData(
            headingRowColor: WidgetStateProperty.all(
              scheme.surfaceContainerHigh.withValues(alpha: 0.55),
            ),
            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: scheme.onSurface,
            ),
            dataTextStyle: theme.textTheme.bodyMedium,
            dividerThickness: 0.5,
            horizontalMargin: 14,
            columnSpacing: 14,
            dataRowMinHeight: widget.showPlayerPhotos ? 54 : 44,
            dataRowMaxHeight: widget.showPlayerPhotos ? 68 : 52,
            headingRowHeight: 46,
          ),
        ),
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 14,
          headingRowHeight: 46,
          dataRowMinHeight: widget.showPlayerPhotos ? 54 : 44,
          dataRowMaxHeight: widget.showPlayerPhotos ? 68 : 52,
          horizontalMargin: 14,
          columns: [
            if (widget.showPlayerPhotos)
              DataColumn(
                label: SizedBox(
                  width: photoColWidth,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.portrait_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.l10n.tableColumnPhoto,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            DataColumn(
              label: SizedBox(
                width: 36,
                child: Text(
                  '#',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                widget.l10n.tableColumnPlayer,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final date in widget.matrix.dates)
              DataColumn(
                label: SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attendanceNarrowWeekdayLetter(context, date),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          rows: [
            for (var i = 0; i < widget.sortedPlayers.length; i++)
              DataRow(
                color: i.isOdd
                    ? WidgetStateProperty.all(
                        scheme.surfaceContainerLow.withValues(alpha: 0.65),
                      )
                    : null,
                selected: false,
                onSelectChanged: (_) =>
                    widget.onPlayerTap(widget.sortedPlayers[i]),
                cells: [
                  if (widget.showPlayerPhotos)
                    DataCell(
                      SizedBox(
                        width: photoColWidth,
                        child: Center(
                          child: PlayerAvatar(
                            player: widget.sortedPlayers[i],
                            radius: avatarRadius,
                          ),
                        ),
                      ),
                    ),
                  DataCell(
                    SizedBox(
                      width: 36,
                      child: Text(
                        widget.sortedPlayers[i].number?.toString() ?? '-',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PlayerNameText(
                        player: widget.sortedPlayers[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  for (final date in widget.matrix.dates)
                    DataCell(
                      SizedBox(
                        width: 76,
                        child: Center(
                          child: widget.buildCell(
                            context,
                            widget.matrix,
                            widget.sortedPlayers[i].id,
                            date,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    // Column: tabla + carril fino siempre visible (estilo nativo; sin overflow el
    // pulgar llena la pista, atenuado).
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
          child: ScrollConfiguration(
            behavior: const _PlantillaHorizontalScrollBehavior(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: widget.constraints.maxWidth,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: widget.tableMinWidth,
                          ),
                          child: tableContent(),
                        ),
                      ),
                    ),
                  ),
                ),
                _MinimalHorizontalScrollTrack(
                  controller: _horizontalScroll,
                  scheme: scheme,
                  outline: outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carril horizontal tipo barra de sistema: pista fina neutra, siempre visible.
class _MinimalHorizontalScrollTrack extends StatefulWidget {
  final ScrollController controller;
  final ColorScheme scheme;
  final Color outline;

  const _MinimalHorizontalScrollTrack({
    required this.controller,
    required this.scheme,
    required this.outline,
  });

  @override
  State<_MinimalHorizontalScrollTrack> createState() =>
      _MinimalHorizontalScrollTrackState();
}

class _MinimalHorizontalScrollTrackState
    extends State<_MinimalHorizontalScrollTrack> {
  static const _padH = 12.0;
  static const _trackH = 4.0;
  static const _thumbMinW = 32.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _MinimalHorizontalScrollTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final innerW = (constraints.maxWidth - 2 * _padH).clamp(
          0.0,
          double.infinity,
        );

        double thumbW;
        double thumbLeft;
        var hasScroll = false;

        if (!widget.controller.hasClients || innerW <= 0) {
          thumbW = innerW;
          thumbLeft = 0;
        } else {
          final pos = widget.controller.position;
          final extent = pos.maxScrollExtent - pos.minScrollExtent;
          final vp = pos.viewportDimension;
          hasScroll = extent > 1e-6;
          if (!hasScroll) {
            thumbW = innerW;
            thumbLeft = 0;
          } else {
            thumbW = (vp / (extent + vp) * innerW).clamp(_thumbMinW, innerW);
            final maxLeft = innerW - thumbW;
            thumbLeft = (pos.pixels - pos.minScrollExtent) / extent * maxLeft;
          }
        }

        void scrollByPixels(double deltaScroll) {
          if (!widget.controller.hasClients) return;
          final pos = widget.controller.position;
          final min = pos.minScrollExtent;
          final max = pos.maxScrollExtent;
          pos.jumpTo((pos.pixels + deltaScroll).clamp(min, max));
        }

        void jumpToLocalX(double localDx) {
          if (!widget.controller.hasClients) return;
          final pos = widget.controller.position;
          final extent = pos.maxScrollExtent - pos.minScrollExtent;
          if (extent <= 1e-6) return;
          final t = (localDx / innerW).clamp(0.0, 1.0);
          pos.jumpTo(pos.minScrollExtent + t * extent);
        }

        final scheme = widget.scheme;
        final trackColor = scheme.outlineVariant.withValues(alpha: 0.42);
        final thumbActive = scheme.onSurface.withValues(alpha: 0.38);
        final thumbIdle = scheme.onSurface.withValues(alpha: 0.14);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: widget.outline.withValues(alpha: 0.2),
            ),
            SizedBox(
              height: _kHorizontalScrollLaneHeight - 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _padH),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => jumpToLocalX(d.localPosition.dx),
                    onHorizontalDragUpdate: (d) {
                      if (!widget.controller.hasClients) return;
                      final pos = widget.controller.position;
                      final extent = pos.maxScrollExtent - pos.minScrollExtent;
                      if (extent <= 1e-6) return;
                      scrollByPixels(d.delta.dx * extent / innerW);
                    },
                    child: Center(
                      child: SizedBox(
                        height: _trackH,
                        width: double.infinity,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: trackColor,
                                  borderRadius: BorderRadius.circular(
                                    _trackH / 2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: thumbLeft,
                              top: 0,
                              bottom: 0,
                              width: thumbW,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: hasScroll ? thumbActive : thumbIdle,
                                  borderRadius: BorderRadius.circular(
                                    _trackH / 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Física y dispositivos para el scroll horizontal de la plantilla (dedo, ratón, trackpad).
class _PlantillaHorizontalScrollBehavior extends MaterialScrollBehavior {
  const _PlantillaHorizontalScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class _AttendanceMatrix {
  final List<DateTime> dates;
  final Map<int, Map<DateTime, Attendance>> data;

  const _AttendanceMatrix({required this.dates, required this.data});

  const _AttendanceMatrix.empty() : dates = const [], data = const {};
}

