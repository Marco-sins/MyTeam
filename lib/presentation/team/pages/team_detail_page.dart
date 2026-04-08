import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/attendance/pages/attendance_page.dart';
import 'package:tfg1/presentation/convocation/pages/convocation_page.dart';
import 'package:tfg1/presentation/team/pages/team_management_page.dart';
import 'package:tfg1/presentation/team/widgets/team_detail_header.dart';
import 'package:tfg1/presentation/team/widgets/team_attendance_section.dart';
import 'package:tfg1/presentation/match/pages/match_list_page.dart';
import 'package:tfg1/presentation/team/widgets/team_bottom_bar.dart';

class TeamDetailPage extends StatefulWidget {
  final Team team;

  const TeamDetailPage({super.key, required this.team});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Nombre fijo de la aplicación en el menú de equipo
        title: const Text('Football TFG'),
        actions: [
          if (widget.team.logoUrl != null &&
              (widget.team.logoUrl!.startsWith('http://') ||
                  widget.team.logoUrl!.startsWith('https://')))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.team.logoUrl!),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          TeamDetailHeader(team: widget.team),
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
                  return TeamAttendanceSection(
                    team: widget.team,
                    players: state.players,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: TeamBottomBar(team: widget.team),
    );
  }
}
