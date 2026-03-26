import 'package:flutter/material.dart';
import '../../create_team/pages/add_team_page.dart';

class AddTeam extends StatelessWidget {
  const AddTeam({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTeamPage()),
        );
      },
      backgroundColor: const Color(0xFF2E7D32),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text("Nuevo Equipo", style: TextStyle(color: Colors.white)),
    );
  }
}
