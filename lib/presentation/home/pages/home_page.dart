import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/presentation/create_team/pages/add_team_page.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/pages/login_page.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
        backgroundColor: const Color(0xFFF5F5F5), // Gris muy claro de fondo
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
          title: const Text(
            "Mis Equipos",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),

        // BOTÓN PARA AÑADIR EQUIPOS
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTeamPage()),
            );
          },
          backgroundColor: const Color(0xFF2E7D32),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Nuevo Equipo",
            style: TextStyle(color: Colors.white),
          ),
        ),

        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (state is HomeLoaded) {
              if (state.teams.isEmpty) {
                return _buildEmptyState();
              }
              return _buildTeamList(state.teams);
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

  // Widget cuando NO hay equipos
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Todavía no se han creado equipos",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text("¡Pulsa el botón + para empezar!"),
        ],
      ),
    );
  }

  // Widget con la lista de equipos
  Widget _buildTeamList(List<dynamic> teams) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.group, color: Colors.green),
            ),
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${team.playersCount} Jugadores",
            ), // team.playersCount
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar al detalle del equipo
            },
          ),
        );
      },
    );
  }
}
