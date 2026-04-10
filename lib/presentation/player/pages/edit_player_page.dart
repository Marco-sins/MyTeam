import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/update_player_use_case.dart';
import 'package:football_manager/presentation/player/pages/player_form_page.dart';

class EditPlayerPage extends StatelessWidget {
  final Team team;
  final Player player;
  final AuthUser currentUser;
  final UpdatePlayerUseCase updatePlayerUseCase;

  const EditPlayerPage({
    super.key,
    required this.team,
    required this.player,
    required this.currentUser,
    required this.updatePlayerUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerFormPage(
      team: team,
      currentUser: currentUser,
      updatePlayerUseCase: updatePlayerUseCase,
      initialPlayer: player,
    );
  }
}
