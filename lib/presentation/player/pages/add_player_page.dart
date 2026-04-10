import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/presentation/player/pages/player_form_page.dart';

class AddPlayerPage extends StatelessWidget {
  final Team team;
  final AuthUser currentUser;
  final AddNewPlayerUseCase addNewPlayerUseCase;

  const AddPlayerPage({
    super.key,
    required this.team,
    required this.currentUser,
    required this.addNewPlayerUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerFormPage(
      team: team,
      currentUser: currentUser,
      addNewPlayerUseCase: addNewPlayerUseCase,
    );
  }
}
