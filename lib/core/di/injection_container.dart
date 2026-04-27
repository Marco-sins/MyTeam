import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:football_manager/data/datasource/attendance_remote_datasource.dart';
import 'package:football_manager/data/datasource/auth_remote_datasource.dart';
import 'package:football_manager/data/datasource/invitation_remote_datasource.dart';
import 'package:football_manager/data/datasource/match_event_remote_datasource.dart';
import 'package:football_manager/data/datasource/match_remote_datasource.dart';
import 'package:football_manager/data/datasource/player_remote_datasource.dart';
import 'package:football_manager/data/datasource/profile_remote_datasource.dart';
import 'package:football_manager/data/datasource/team_remote_datasource.dart';
import 'package:football_manager/data/repositories/attendance_repository.dart';
import 'package:football_manager/data/repositories/auth_repository.dart';
import 'package:football_manager/data/repositories/invitation_repository.dart';
import 'package:football_manager/data/repositories/match_event_repository.dart';
import 'package:football_manager/data/repositories/match_repository.dart';
import 'package:football_manager/data/repositories/player_repository.dart';
import 'package:football_manager/data/repositories/profile_repository.dart';
import 'package:football_manager/data/realtime/match_spectator_realtime_service.dart';
import 'package:football_manager/data/repositories/team_repository.dart';
import 'package:football_manager/domain/repositories/i_attendance_repository.dart';
import 'package:football_manager/domain/repositories/i_auth_repository.dart';
import 'package:football_manager/domain/repositories/i_invitation_repository.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';
import 'package:football_manager/domain/repositories/i_match_spectator_realtime.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';
import 'package:football_manager/domain/repositories/i_profile_repository.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';
import 'package:football_manager/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/delete_attendance_day_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/delete_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_days_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendances_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/auth/get_user_session_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_in_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_out_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_up_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/accept_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/create_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/get_invitations_by_email_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/reject_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_half_time_status_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_lineup_starters_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_second_half_started_use_case.dart';
import 'package:football_manager/domain/usecase/match/create_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/delete_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_convoked_player_ids_for_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_remote_match_status_use_case.dart';
import 'package:football_manager/domain/usecase/match/finish_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_match_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match/lock_initial_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/persist_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/start_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/delete_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_first_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_match_event_by_db_type_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_event_aggregates_from_events_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_live_timeline_maps_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_sent_off_player_ids_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_player_card_summary_for_match_player_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_player_rating_event_rows_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/save_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/import_player_from_other_team_use_case.dart';
import 'package:football_manager/domain/usecase/player/delete_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/delete_stored_player_photo_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/player/update_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/upload_player_photo_use_case.dart';
import 'package:football_manager/domain/usecase/profile/get_profiles_by_ids_use_case.dart';
import 'package:football_manager/domain/usecase/team/create_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/delete_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_team_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_teams_use_case.dart';
import 'package:football_manager/domain/usecase/team/leave_team_as_external_use_case.dart';
import 'package:football_manager/domain/usecase/team/update_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/upload_team_logo_use_case.dart';
import 'package:football_manager/data/team_scoring_config_storage.dart';

/// Localizador de dependencias (composition root). Llamar a [configureDependencies]
/// tras [Supabase.initialize].
final sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<IAuthRepository>()) {
    return;
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerLazySingleton(
    () => TeamScoringConfigStorage(sl<SharedPreferences>()),
  );

  final client = Supabase.instance.client;

  // —— Repositorios (data → contratos de dominio) ——
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(AuthRemoteDatasource(client)),
  );
  sl.registerLazySingleton<ITeamRepository>(
    () => TeamRepository(TeamRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IPlayerRepository>(
    () => PlayerRepository(PlayerRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IAttendanceRepository>(
    () => AttendanceRepository(AttendanceRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IMatchRepository>(
    () => MatchRepository(MatchRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IMatchEventRepository>(
    () => MatchEventRepository(MatchEventRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IProfileRepository>(
    () => ProfileRepository(ProfileRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IInvitationRepository>(
    () => InvitationRepository(InvitationRemoteDatasource(client)),
  );
  sl.registerLazySingleton<IMatchSpectatorRealtime>(
    () => MatchSpectatorRealtimeService(client),
  );

  // —— Casos de uso ——
  sl.registerLazySingleton(
    () => GetTeamsUseCase(sl<ITeamRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTeamByIdUseCase(sl<ITeamRepository>()),
  );
  sl.registerLazySingleton(
    () => UploadTeamLogoUseCase(sl<ITeamRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateTeamUseCase(sl<ITeamRepository>()),
  );
  sl.registerLazySingleton(
    () => AddNewPlayerUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => ImportPlayerFromOtherTeamUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => DeletePlayerUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdatePlayerUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPlayersByTeamUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => UploadPlayerPhotoUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteStoredPlayerPhotoUseCase(sl<IPlayerRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteTeamUseCase(sl<ITeamRepository>()),
  );
  sl.registerLazySingleton(
    () => LeaveTeamAsExternalUseCase(sl<ITeamRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateAttendanceUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateAttendanceUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteAttendanceUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAttendanceByDateUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAttendanceDaysByTeamUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => GetAttendancesUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteAttendanceDayUseCase(sl<IAttendanceRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateMatchUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMatchesByTeamUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteMatchUseCase(
      sl<IMatchRepository>(),
      sl<IPlayerRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => StartMatchUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => FinishMatchUseCase(
      sl<IMatchRepository>(),
      sl<IMatchEventRepository>(),
      sl<IPlayerRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => SaveMatchEventUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteMatchEventUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMatchEventsByMatchUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetLatestFormationNoteByMatchUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetFirstFormationNoteByMatchUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMatchByIdUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMatchEventAggregatesFromEventsUseCase(
      sl<IMatchEventRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetMatchLiveTimelineMapsUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMatchSentOffPlayerIdsUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPlayerRatingEventRowsUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => GetPlayerCardSummaryForMatchPlayerUseCase(
      sl<IMatchEventRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetLatestMatchEventByDbTypeUseCase(sl<IMatchEventRepository>()),
  );
  sl.registerLazySingleton(
    () => FetchRemoteMatchStatusUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => ApplyMatchHalfTimeStatusUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => ApplyMatchSecondHalfStartedUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => PersistMatchLineupPositionsUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => LockInitialLineupPositionsUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => ApplyMatchLineupStartersUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => FetchConvokedPlayerIdsForMatchUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => FetchMatchLineupPositionsUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMatchLineupsByMatchUseCase(sl<IMatchRepository>()),
  );
  sl.registerLazySingleton(
    () => GetProfilesByIdsUseCase(sl<IProfileRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateInvitationUseCase(sl<IInvitationRepository>()),
  );
  sl.registerLazySingleton(
    () => GetInvitationsByEmailUseCase(sl<IInvitationRepository>()),
  );
  sl.registerLazySingleton(
    () => AcceptInvitationUseCase(sl<IInvitationRepository>()),
  );
  sl.registerLazySingleton(
    () => RejectInvitationUseCase(sl<IInvitationRepository>()),
  );
  sl.registerLazySingleton(
    () => SignInUseCase(sl<IAuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SignUpUseCase(sl<IAuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SignOutUseCase(sl<IAuthRepository>()),
  );
  sl.registerLazySingleton(
    () => GetUserSessionUseCase(sl<IAuthRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateTeamUseCase(sl<ITeamRepository>()),
  );
}

/// Para pruebas o hot-reload controlado.
Future<void> resetDependencies() async {
  await sl.reset();
}
