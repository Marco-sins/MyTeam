import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tfg1/data/datasource/auth_remote_datasource.dart';
import 'package:tfg1/data/repositories/auth_repository.dart';
import 'package:tfg1/domain/usecase/auth/get_user_session_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_in_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_up_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_out_use_case.dart';
import 'package:tfg1/presentation/home/bloc/home_cubit.dart';
import 'package:tfg1/data/datasource/team_remote_datasource.dart';
import 'package:tfg1/data/repositories/team_repository.dart';
import 'package:tfg1/domain/usecase/team/create_team_use_case.dart';
import 'package:tfg1/domain/usecase/team/get_teams_use_case.dart';
import 'package:tfg1/presentation/create_team/bloc/create_team_cubit.dart';
import 'package:tfg1/presentation/home/pages/home_page.dart';

// --- IMPORTA TUS CAPAS ---
// Ajusta estas rutas a las carpetas de tu proyecto
import 'presentation/auth/bloc/auth_cubit.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'presentation/auth/pages/login_page.dart';

void main() async {
  // 1. Inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: '.env');

  // 2. Inicialización de Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
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

    return MultiBlocProvider(
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
          create: (context) =>
              CreateTeamCubit(CreateTeamUseCase(teamRepository)),
        ),
      ],
      child: MaterialApp(
        title: 'Football TFG',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.green, // Color futbolero
        ),
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
    );
  }
}
