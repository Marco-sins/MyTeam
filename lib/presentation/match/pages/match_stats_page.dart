import 'package:flutter/material.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';

class MatchStatsPage extends StatelessWidget {
  final Match match;

  const MatchStatsPage({super.key, required this.match});

  String _statusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.notStarted:
        return 'Pendiente';
      case MatchStatus.inProgress:
        return 'En juego';
      case MatchStatus.paused:
        return 'Pausado';
      case MatchStatus.finished:
        return 'Finalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas del partido'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vs ${match.opponent}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateText,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText(match.status),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${match.goalsScored}  -  ${match.goalsConceded}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Marcador final',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
