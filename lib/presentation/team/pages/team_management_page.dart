import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/data/datasource/player_remote_datasource.dart';
import 'package:tfg1/data/repositories/player_repository.dart';
import 'package:tfg1/data/datasource/team_remote_datasource.dart';
import 'package:tfg1/data/repositories/team_repository.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/player/add_new_player_use_case.dart';
import 'package:tfg1/domain/usecase/team/delete_team_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/player/pages/add_player_page.dart';
import 'package:tfg1/presentation/home/bloc/home_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';

class TeamManagementPage extends StatefulWidget {
  final Team team;

  const TeamManagementPage({super.key, required this.team});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    // Reutilizamos el cubit para asegurar que la plantilla está cargada
    context.read<TeamDetailCubit>().loadTeam(widget.team.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de equipo'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Escudo actual (si existe) con opción a cambiarlo en el futuro
                InkWell(
                  onTap: () {
                    // TODO: Implementar cambio de escudo
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.team.logoUrl != null
                        ? NetworkImage(widget.team.logoUrl!)
                        : null,
                    child: widget.team.logoUrl == null
                        ? const Icon(Icons.shield_outlined)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del equipo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // TODO: Botón para guardar cambios de nombre/escudo cuando conectes el use case de updateTeam
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Conectar con UpdateTeamUseCase
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plantilla',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
                builder: (context, state) {
                  if (state is TeamDetailLoading ||
                      state is TeamDetailInitial) {
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
                      itemCount: state.players.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = state.players[index];
                        return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  // TODO: Navegar a pantalla de edición de jugador
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  // TODO: Confirmar y borrar jugador
                                },
                              ),
                            ],
                          ),
                          title: Text(player.fullName),
                          subtitle: Text(
                            'Dorsal: ${player.number?.toString() ?? '-'}  ·  Tel: ${player.phone ?? '-'}',
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! Authenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes iniciar sesión para añadir jugadores',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final supabase = Supabase.instance.client;
                  final playerRepository = PlayerRepository(
                    PlayerRemoteDatasource(supabase),
                  );
                  final addNewPlayerUseCase = AddNewPlayerUseCase(
                    playerRepository,
                  );

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPlayerPage(
                        team: widget.team,
                        currentUser: authState.user,
                        addNewPlayerUseCase: addNewPlayerUseCase,
                      ),
                    ),
                  );

                  // Al volver de crear un jugador, recargamos la plantilla
                  if (!mounted) return;
                  context.read<TeamDetailCubit>().loadTeam(widget.team.id);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Añadir jugador'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! Authenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes iniciar sesión para borrar el equipo',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Borrar equipo'),
                      content: const Text(
                        '¿Seguro que quieres borrar este equipo? Esta acción no se puede deshacer.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Borrar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  final supabase = Supabase.instance.client;
                  final teamRepository = TeamRepository(
                    TeamRemoteDatasource(supabase),
                  );
                  final deleteTeamUseCase = DeleteTeamUseCase(teamRepository);

                  final result = await deleteTeamUseCase(
                    widget.team,
                    authState.user,
                  );

                  result.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    (_) {
                      // Refrescamos la lista de equipos en Home antes de volver
                      context.read<HomeCubit>().fetchTeams();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Equipo borrado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  );
                },
                icon: const Icon(Icons.delete),
                label: const Text('Borrar equipo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
