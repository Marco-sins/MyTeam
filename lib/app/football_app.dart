import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_manager/core/auth/supabase_auth_session_bridge.dart';
import 'package:football_manager/core/constants/app_branding.dart';
import 'package:football_manager/core/navigation/app_navigator_key.dart';
import 'package:football_manager/core/notifications/match_event_app_notification_coordinator.dart';
import 'package:football_manager/core/notifications/match_notif_app_lifecycle.dart';
import 'package:football_manager/core/push/push_notification_service.dart';
import 'package:football_manager/core/di/injection_container.dart';
import 'package:football_manager/core/locale/locale_cubit.dart';
import 'package:football_manager/core/theme/app_responsive.dart';
import 'package:football_manager/core/theme/app_theme.dart';
import 'package:football_manager/domain/repositories/i_match_spectator_realtime.dart';
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
import 'package:football_manager/domain/usecase/match/persist_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/start_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/delete_match_event_use_case.dart';
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
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/auth/pages/login_page.dart';
import 'package:football_manager/presentation/create_team/cubit/create_team_cubit.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';
import 'package:football_manager/presentation/home/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raíz de la UI: localización, inyección de casos de uso vía [RepositoryProvider]
/// (resuelto con [sl]) y BLoC globales.
class FootballApp extends StatelessWidget {
  const FootballApp({super.key, required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocaleCubit(sharedPreferences),
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider.value(value: sl<AddNewPlayerUseCase>()),
              RepositoryProvider.value(
                value: sl<ImportPlayerFromOtherTeamUseCase>(),
              ),
              RepositoryProvider.value(value: sl<DeletePlayerUseCase>()),
              RepositoryProvider.value(value: sl<UpdatePlayerUseCase>()),
              RepositoryProvider.value(value: sl<GetPlayersByTeamUseCase>()),
              RepositoryProvider.value(value: sl<UploadPlayerPhotoUseCase>()),
              RepositoryProvider.value(
                value: sl<DeleteStoredPlayerPhotoUseCase>(),
              ),
              RepositoryProvider.value(value: sl<DeleteTeamUseCase>()),
              RepositoryProvider.value(value: sl<LeaveTeamAsExternalUseCase>()),
              RepositoryProvider.value(value: sl<UploadTeamLogoUseCase>()),
              RepositoryProvider.value(value: sl<UpdateTeamUseCase>()),
              RepositoryProvider.value(value: sl<GetTeamByIdUseCase>()),
              RepositoryProvider.value(value: sl<GetTeamsUseCase>()),
              RepositoryProvider.value(value: sl<CreateAttendanceUseCase>()),
              RepositoryProvider.value(value: sl<UpdateAttendanceUseCase>()),
              RepositoryProvider.value(value: sl<DeleteAttendanceUseCase>()),
              RepositoryProvider.value(value: sl<GetAttendanceByDateUseCase>()),
              RepositoryProvider.value(
                value: sl<GetAttendanceDaysByTeamUseCase>(),
              ),
              RepositoryProvider.value(value: sl<GetAttendancesUseCase>()),
              RepositoryProvider.value(value: sl<DeleteAttendanceDayUseCase>()),
              RepositoryProvider.value(value: sl<CreateMatchUseCase>()),
              RepositoryProvider.value(value: sl<GetMatchesByTeamUseCase>()),
              RepositoryProvider.value(value: sl<DeleteMatchUseCase>()),
              RepositoryProvider.value(value: sl<StartMatchUseCase>()),
              RepositoryProvider.value(value: sl<FinishMatchUseCase>()),
              RepositoryProvider.value(value: sl<SaveMatchEventUseCase>()),
              RepositoryProvider.value(value: sl<DeleteMatchEventUseCase>()),
              RepositoryProvider.value(
                value: sl<GetMatchEventsByMatchUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetLatestFormationNoteByMatchUseCase>(),
              ),
              RepositoryProvider.value(value: sl<GetMatchByIdUseCase>()),
              RepositoryProvider.value(
                value: sl<GetMatchEventAggregatesFromEventsUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetMatchLiveTimelineMapsUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetMatchSentOffPlayerIdsUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetPlayerRatingEventRowsUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetPlayerCardSummaryForMatchPlayerUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetLatestMatchEventByDbTypeUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<FetchRemoteMatchStatusUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<ApplyMatchHalfTimeStatusUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<ApplyMatchSecondHalfStartedUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<PersistMatchLineupPositionsUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<ApplyMatchLineupStartersUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<FetchConvokedPlayerIdsForMatchUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<FetchMatchLineupPositionsUseCase>(),
              ),
              RepositoryProvider.value(
                value: sl<GetMatchLineupsByMatchUseCase>(),
              ),
              RepositoryProvider<IMatchSpectatorRealtime>.value(
                value: sl<IMatchSpectatorRealtime>(),
              ),
              RepositoryProvider.value(value: sl<GetProfilesByIdsUseCase>()),
              RepositoryProvider.value(value: sl<CreateInvitationUseCase>()),
              RepositoryProvider.value(
                value: sl<GetInvitationsByEmailUseCase>(),
              ),
              RepositoryProvider.value(value: sl<AcceptInvitationUseCase>()),
              RepositoryProvider.value(value: sl<RejectInvitationUseCase>()),
              RepositoryProvider<ITeamRepository>.value(
                value: sl<ITeamRepository>(),
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => AuthCubit(
                    signInUseCase: sl<SignInUseCase>(),
                    signUpUseCase: sl<SignUpUseCase>(),
                    signOutUseCase: sl<SignOutUseCase>(),
                    getUserSessionUseCase: sl<GetUserSessionUseCase>(),
                  )..checkUserSession(),
                ),
                BlocProvider(create: (_) => HomeCubit(sl<GetTeamsUseCase>())),
                BlocProvider(
                  create: (_) => CreateTeamCubit(
                    sl<CreateTeamUseCase>(),
                    sl<UploadTeamLogoUseCase>(),
                  ),
                ),
              ],
              child: SupabaseAuthSessionBridge(
                child: BlocListener<AuthCubit, AuthState>(
                  listenWhen: (previous, current) {
                    if (current is Authenticated) return true;
                    if (previous is Authenticated && current is AuthLoading) {
                      return true;
                    }
                    return false;
                  },
                  listener: (context, state) {
                    if (state is Authenticated) {
                      unawaited(
                        MatchEventAppNotificationCoordinator.instance.start(),
                      );
                      unawaited(
                        PushNotificationService.instance
                            .registerTokenForCurrentUser(),
                      );
                    } else {
                      unawaited(
                        MatchEventAppNotificationCoordinator.instance.stop(),
                      );
                      unawaited(
                        PushNotificationService.instance
                            .deleteTokenForCurrentUser(),
                      );
                    }
                  },
                  child: MaterialApp(
                    navigatorKey: appNavigatorKey,
                    title: AppBranding.displayName,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light(),
                    builder: (context, child) {
                      return MatchNotifAppLifecycle(
                        child: AppResponsive.materialAppBuilder(context, child),
                      );
                    },
                    locale: locale,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (state is Authenticated) {
                          return const HomePage();
                        }
                        return const LoginPage();
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pantalla mínima si falta configuración de Supabase en `.env`.
class SupabaseConfigErrorApp extends StatelessWidget {
  const SupabaseConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: AppResponsive.materialAppBuilder,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_suggest_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Configuración de Supabase',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Revisa el archivo .env: SUPABASE_URL y SUPABASE_ANON_KEY deben ser válidos. Luego reinicia la app.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
