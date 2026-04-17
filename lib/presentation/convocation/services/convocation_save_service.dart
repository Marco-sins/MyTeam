import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/usecase/match/create_match_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_cubit.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/convocation/image/convocation_image_body.dart';
import 'package:football_manager/presentation/convocation/image/convocation_image_generator.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_image_page.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';

class ConvocationSaveService {
  static Future<void> save({
    required BuildContext context,
    required TextEditingController rivalController,
    required TextEditingController notesController,
    required bool isHome,
    required String? awayLocation,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
    required TimeOfDay callTime,
    required ConvocationCubit convocationCubit,
  }) async {
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

    final team = context.read<TeamContextCubit>().state;

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

    final rival = rivalController.text.trim();
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
    final convState = convocationCubit.state;
    final selectedPlayers = players
        .where((p) => convState.calledUp[p.id] == true)
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
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final int tempMatchId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final lineups = selectedPlayers
        .map(
          (player) => MatchLineup(
            id: 0,
            playerId: player.id,
            matchId: tempMatchId,
            isStarting: false,
          ),
        )
        .toList();

    final formattedHour =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    final match = Match(
      id: tempMatchId,
      teamId: team.id,
      opponent: rival,
      goalsScored: 0,
      goalsConceded: 0,
      date: matchDateTime,
      hour: formattedHour,
      status: MatchStatus.notStarted,
      lineups: lineups,
      isHome: isHome,
    );

    final createMatchUseCase = context.read<CreateMatchUseCase>();
    loadingCubit.start();
    final result = await createMatchUseCase(match, authState.user);
    loadingCubit.stop();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) async {
        final l10n = AppLocalizations.of(context)!;
        final imageCopy = ConvocationImageCopy(
          sectionMatchDetails: l10n.convocationImageSectionMatchDetails,
          sectionMatchDetailsSubtitle:
              l10n.convocationImageSectionMatchDetailsSubtitle,
          labelDate: l10n.convocationImageLabelDate,
          labelMatchKickoff: l10n.convocationImageLabelMatchKickoff,
          labelCallArrival: l10n.convocationImageLabelCallArrival,
          callTimeReminder: l10n.convocationImageCallTimeReminder,
          labelVenue: l10n.convocationImageLabelVenue,
          mapLinkIntro: l10n.convocationImageMapLinkIntro,
          placeHomeHeadline: l10n.convocationImagePlaceHomeHeadline,
          placeHomeDetail: l10n.convocationImagePlaceHomeDetail,
          placeAwayHeadline: l10n.convocationImagePlaceAwayHeadline,
          placeAwayNoAddressDetail:
              l10n.convocationImagePlaceAwayNoAddressDetail,
          sectionSquadTitle: l10n.convocationImageSectionSquad,
          observationsTitle: l10n.convocationImageObservationsTitle,
          playerFallbackName: l10n.convocationImagePlayerFallback,
        );
        final file = await generateConvocationImage(
          team: team,
          isHome: isHome,
          matchDate: selectedDate,
          matchTime: selectedTime,
          callTime: callTime,
          rivalName: rival,
          awayLocation: awayLocation,
          notes: notesController.text,
          selectedPlayers: selectedPlayers,
          imageCopy: imageCopy,
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.convocationSavedSuccess),
            backgroundColor: Colors.green,
          ),
        );

        if (file != null) {
          final teamContext = context.read<TeamContextCubit>();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: teamContext),
                  BlocProvider(
                    create: (ctx) => TeamDetailCubit(
                      ctx.read<GetPlayersByTeamUseCase>(),
                    )..loadTeam(team.id),
                  ),
                ],
                child: ConvocationImagePage(imageFile: file),
              ),
            ),
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            TeamSessionRoutes.detailHomeReplacingStack(context),
            (route) => route.isFirst,
          );
        }
      },
    );
  }
}
