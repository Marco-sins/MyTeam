import 'package:flutter/material.dart';
import '../../create_team/pages/add_team_page.dart';

class AddTeam extends StatelessWidget {
  const AddTeam({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      elevation: 1,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTeamPage()),
        );
      },
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nuevo equipo'),
    );
  }
}
