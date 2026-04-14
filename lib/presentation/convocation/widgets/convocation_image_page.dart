import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';

class ConvocationImagePage extends StatelessWidget {
  final Team team;
  final File imageFile;

  const ConvocationImagePage({
    super.key,
    required this.team,
    required this.imageFile,
  });

  void _goToTeamHome(BuildContext context) {
    final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              TeamDetailCubit(getPlayersByTeamUseCase)..loadTeam(team.id),
          child: TeamDetailPage(team: team),
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          TeamDetailCubit(ctx.read<GetPlayersByTeamUseCase>())
            ..loadTeam(team.id),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Convocatoria generada'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goToTeamHome(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartir imagen',
              onPressed: () async {
                await Share.shareXFiles([
                  XFile(imageFile.path),
                ], text: 'Convocatoria de ${team.name}');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(imageFile),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goToTeamHome(context),
                  child: const Text('Volver al equipo'),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: TeamBottomBar(team: team),
      ),
    );
  }
}
