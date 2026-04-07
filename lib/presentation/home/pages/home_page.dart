import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/presentation/home/widgets/add_team.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/pages/login_page.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_empty.dart';
import '../widgets/team_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Siempre que se construye HomePage, cargamos los equipos
    context.read<HomeCubit>().fetchTeams();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: const HomeAppBar(),
        floatingActionButton: const AddTeam(),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading || state is HomeInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (state is HomeLoaded) {
              if (state.teams.isEmpty) {
                return const HomeEmpty();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.teams.length,
                itemBuilder: (context, index) =>
                    TeamCard(team: state.teams[index]),
              );
            }

            if (state is HomeError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
