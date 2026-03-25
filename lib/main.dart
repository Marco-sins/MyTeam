import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tfg1/data/datasource/auth_remote_datasource.dart';
import 'package:tfg1/data/repositories/auth_repository.dart';
import 'package:tfg1/domain/usecase/auth/sign_in_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_up_use_case.dart';
import 'package:tfg1/presentation/home/bloc/home_cubit.dart';

// --- IMPORTA TUS CAPAS ---
// Ajusta estas rutas a las carpetas de tu proyecto
import 'presentation/auth/bloc/auth_cubit.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'presentation/auth/pages/login_page.dart';

void main() async {
  // 1. Inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Supabase
  await Supabase.initialize(
    url: 'https://vdwiwfzgyjaxolbllhms.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkd2l3ZnpneWpheG9sYmxsaG1zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMjUzNzQsImV4cCI6MjA4ODgwMTM3NH0.F0E4CiFrPsqw7HTV9GL33x07X59rrA9boV8IvaUnVwI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Creamos el cliente de Supabase una sola vez
    final supabaseClient = Supabase.instance.client;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(
            // AQUÍ MONTAMOS LA ESTRUCTURA MANUALMENTE (Inyección manual)
            signInUseCase: SignInUseCase(
              AuthRepository(AuthRemoteDatasource(supabaseClient)),
            ),
            signUpUseCase: SignUpUseCase(
              AuthRepository(AuthRemoteDatasource(supabaseClient)),
            ),
          ),
        ),
        BlocProvider(
          create: (context) =>
              HomeCubit()..fetchTeams(), // Carga equipos al iniciar
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

// Pantalla de prueba rápida para que no te dé error
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App de Fútbol")),
      body: const Center(child: Text("¡Has entrado correctamente!")),
    );
  }
}
