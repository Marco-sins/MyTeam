import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:football_manager/data/datasource/auth_remote_datasource.dart';
import 'package:football_manager/data/repositories/auth_repository.dart';
import 'package:football_manager/data/datasource/team_remote_datasource.dart';
import 'package:football_manager/data/repositories/team_repository.dart';
import 'package:football_manager/data/datasource/attendance_remote_datasource.dart';
import 'package:football_manager/data/repositories/attendance_repository.dart';
import 'package:football_manager/data/datasource/match_remote_datasource.dart';
import 'package:football_manager/data/repositories/match_repository.dart';
import 'package:football_manager/data/datasource/match_event_remote_datasource.dart';
import 'package:football_manager/data/repositories/match_event_repository.dart';
import 'package:football_manager/data/datasource/profile_remote_datasource.dart';
import 'package:football_manager/data/repositories/profile_repository.dart';
import 'package:football_manager/data/datasource/invitation_remote_datasource.dart';
import 'package:football_manager/data/repositories/invitation_repository.dart';
import 'package:football_manager/domain/usecase/auth/get_user_session_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_in_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_up_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_out_use_case.dart';
import 'package:football_manager/domain/usecase/team/create_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_teams_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_team_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/team/upload_team_logo_use_case.dart';
import 'package:football_manager/domain/usecase/team/update_team_use_case.dart';
import 'package:football_manager/data/datasource/player_remote_datasource.dart';
import 'package:football_manager/data/repositories/player_repository.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/delete_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/update_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/delete_team_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/delete_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_days_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/delete_attendance_day_use_case.dart';
import 'package:football_manager/domain/usecase/match/create_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match/delete_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/start_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/finish_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/save_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/delete_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/profile/get_profiles_by_ids_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/create_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/get_invitations_by_email_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/accept_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/reject_invitation_use_case.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';
import 'package:football_manager/presentation/create_team/cubit/create_team_cubit.dart';
import 'package:football_manager/presentation/home/pages/home_page.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

// --- IMPORTA TUS CAPAS ---
// Ajusta estas rutas a las carpetas de tu proyecto
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/auth/pages/login_page.dart';

void main() async {
  // 1. Inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final hasValidSupabaseConfig =
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id') &&
      !supabaseAnonKey.contains('your-anon-key-here');

  if (!hasValidSupabaseConfig) {
    runApp(const SupabaseConfigErrorApp());
    return;
  }

  // 2. Inicialización de Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class SupabaseConfigErrorApp extends StatelessWidget {
  const SupabaseConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Creamos el cliente de Supabase una sola vez
    final supabaseClient = Supabase.instance.client;
    final authRepository = AuthRepository(AuthRemoteDatasource(supabaseClient));
    final teamRepository = TeamRepository(TeamRemoteDatasource(supabaseClient));
    final getTeamsUseCase = GetTeamsUseCase(teamRepository);
    final getTeamByIdUseCase = GetTeamByIdUseCase(teamRepository);
    final uploadTeamLogoUseCase = UploadTeamLogoUseCase(teamRepository);
    final updateTeamUseCase = UpdateTeamUseCase(teamRepository);
    final playerRepository = PlayerRepository(
      PlayerRemoteDatasource(supabaseClient),
    );
    final addNewPlayerUseCase = AddNewPlayerUseCase(playerRepository);
    final deletePlayerUseCase = DeletePlayerUseCase(playerRepository);
    final updatePlayerUseCase = UpdatePlayerUseCase(playerRepository);
    final getPlayersByTeamUseCase = GetPlayersByTeamUseCase(playerRepository);
    final deleteTeamUseCase = DeleteTeamUseCase(teamRepository);
    final attendanceRepository = AttendanceRepository(
      AttendanceRemoteDatasource(supabaseClient),
    );
    final createAttendanceUseCase = CreateAttendanceUseCase(
      attendanceRepository,
    );
    final updateAttendanceUseCase = UpdateAttendanceUseCase(
      attendanceRepository,
    );
    final deleteAttendanceUseCase = DeleteAttendanceUseCase(
      attendanceRepository,
    );
    final getAttendanceByDateUseCase = GetAttendanceByDateUseCase(
      attendanceRepository,
    );
    final getAttendanceDaysByTeamUseCase = GetAttendanceDaysByTeamUseCase(
      attendanceRepository,
    );
    final deleteAttendanceDayUseCase = DeleteAttendanceDayUseCase(
      attendanceRepository,
    );
    final matchRepository = MatchRepository(
      MatchRemoteDatasource(supabaseClient),
    );
    final matchEventRepository = MatchEventRepository(
      MatchEventRemoteDatasource(supabaseClient),
    );
    final profileRepository = ProfileRepository(
      ProfileRemoteDatasource(supabaseClient),
    );
    final invitationRepository = InvitationRepository(
      InvitationRemoteDatasource(supabaseClient),
    );
    final createMatchUseCase = CreateMatchUseCase(matchRepository);
    final getMatchesByTeamUseCase = GetMatchesByTeamUseCase(matchRepository);
    final deleteMatchUseCase = DeleteMatchUseCase(matchRepository);
    final startMatchUseCase = StartMatchUseCase(matchRepository);
    final finishMatchUseCase = FinishMatchUseCase(
      matchRepository,
      matchEventRepository,
      playerRepository,
    );

    final saveMatchEventUseCase = SaveMatchEventUseCase(matchEventRepository);
    final deleteMatchEventUseCase = DeleteMatchEventUseCase(
      matchEventRepository,
    );
    final getProfilesByIdsUseCase = GetProfilesByIdsUseCase(profileRepository);
    final createInvitationUseCase = CreateInvitationUseCase(
      invitationRepository,
    );
    final getInvitationsByEmailUseCase = GetInvitationsByEmailUseCase(
      invitationRepository,
    );
    final acceptInvitationUseCase = AcceptInvitationUseCase(
      invitationRepository,
    );
    final rejectInvitationUseCase = RejectInvitationUseCase(
      invitationRepository,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: addNewPlayerUseCase),
        RepositoryProvider.value(value: deletePlayerUseCase),
        RepositoryProvider.value(value: updatePlayerUseCase),
        RepositoryProvider.value(value: getPlayersByTeamUseCase),
        RepositoryProvider.value(value: deleteTeamUseCase),
        RepositoryProvider.value(value: uploadTeamLogoUseCase),
        RepositoryProvider.value(value: updateTeamUseCase),
        RepositoryProvider.value(value: getTeamByIdUseCase),
        RepositoryProvider.value(value: createAttendanceUseCase),
        RepositoryProvider.value(value: updateAttendanceUseCase),
        RepositoryProvider.value(value: deleteAttendanceUseCase),
        RepositoryProvider.value(value: getAttendanceByDateUseCase),
        RepositoryProvider.value(value: getAttendanceDaysByTeamUseCase),
        RepositoryProvider.value(value: deleteAttendanceDayUseCase),
        RepositoryProvider.value(value: createMatchUseCase),
        RepositoryProvider.value(value: getMatchesByTeamUseCase),
        RepositoryProvider.value(value: deleteMatchUseCase),
        RepositoryProvider.value(value: startMatchUseCase),
        RepositoryProvider.value(value: finishMatchUseCase),
        RepositoryProvider.value(value: saveMatchEventUseCase),
        RepositoryProvider.value(value: deleteMatchEventUseCase),
        RepositoryProvider.value(value: getProfilesByIdsUseCase),
        RepositoryProvider.value(value: createInvitationUseCase),
        RepositoryProvider.value(value: getInvitationsByEmailUseCase),
        RepositoryProvider.value(value: acceptInvitationUseCase),
        RepositoryProvider.value(value: rejectInvitationUseCase),
        RepositoryProvider<ITeamRepository>.value(value: teamRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              // AQUÍ MONTAMOS LA ESTRUCTURA MANUALMENTE (Inyección manual)
              signInUseCase: SignInUseCase(authRepository),
              signUpUseCase: SignUpUseCase(authRepository),
              signOutUseCase: SignOutUseCase(authRepository),
              getUserSessionUseCase: GetUserSessionUseCase(authRepository),
            )..checkUserSession(),
          ),
          BlocProvider(create: (context) => HomeCubit(getTeamsUseCase)),
          BlocProvider(
            create: (context) => CreateTeamCubit(
              CreateTeamUseCase(teamRepository),
              uploadTeamLogoUseCase,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Football TFG',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          // 4. Decidimos qué pantalla mostrar según el estado del AuthCubit
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is Authenticated) {
                return const HomePage(); // Pantalla principal tras login
              } else {
                return const LoginPage(); // Si no está logueado o hay error, login
              }
            },
          ),
        ),
      ),
    );
  }
}
