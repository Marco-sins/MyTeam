import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_cubit.dart';

class ConvocationPlayersSection extends StatelessWidget {
  final List<Player> players;

  const ConvocationPlayersSection({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConvocationCubit, ConvocationState>(
      builder: (context, state) {
        if (players.isEmpty) {
          return const Center(child: Text('No hay jugadores en la plantilla'));
        }

        final sortedPlayers = List<Player>.from(players)
          ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

        final calledCount = context.read<ConvocationCubit>().calledCountFor(
          sortedPlayers.map((p) => p.id),
        );

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedPlayers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                final isCalled = state.calledUp[player.id] ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          player.number?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.fullName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context
                            .read<ConvocationCubit>()
                            .toggleCalledUp(player.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCalled ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isCalled ? 'Sí' : 'No',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jugadores convocados: $calledCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
