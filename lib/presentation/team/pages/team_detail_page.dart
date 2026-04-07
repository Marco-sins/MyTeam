import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/team/pages/team_management_page.dart';

class TeamDetailPage extends StatelessWidget {
  final Team team;

  const TeamDetailPage({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(team.name),
        actions: [
          if (team.logoUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(backgroundImage: NetworkImage(team.logoUrl!)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
              builder: (context, state) {
                if (state is TeamDetailLoading || state is TeamDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TeamDetailError) {
                  return Center(child: Text(state.message));
                }
                if (state is TeamDetailLoaded) {
                  if (state.players.isEmpty) {
                    return const Center(
                      child: Text('No hay jugadores en la plantilla'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.players.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final player = state.players[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(player.number?.toString() ?? '-'),
                        ),
                        title: Text(player.fullName),
                        subtitle: Text('Tel: ${player.phone ?? '-'}'),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _BottomBarButton(
                label: 'Asistencia',
                icon: Icons.check_circle_outline,
              ),
              const _BottomBarButton(
                label: 'Convocatoria',
                icon: Icons.list_alt,
              ),
              const _BottomBarButton(
                label: 'Partido',
                icon: Icons.sports_soccer,
              ),
              _BottomBarButton(
                label: 'Gestión',
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TeamDetailCubit>(),
                        child: TeamManagementPage(team: team),
                      ),
                    ),
                  );
                },
              ),
              const _BottomBarButton(
                label: 'Ver partido',
                icon: Icons.visibility,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _BottomBarButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
