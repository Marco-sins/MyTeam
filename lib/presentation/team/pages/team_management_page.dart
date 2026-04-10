import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/team/delete_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/update_team_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/home/bloc/home_cubit.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/match/pages/match_delete_page.dart';
import 'package:football_manager/presentation/attendance/pages/attendance_delete_page.dart';
import 'package:football_manager/presentation/team/pages/team_roster_page.dart';
import 'package:football_manager/presentation/team/widgets/team_management_header_row.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';
import 'package:football_manager/presentation/team/pages/team_access_page.dart';

class TeamManagementPage extends StatefulWidget {
  final Team team;

  const TeamManagementPage({super.key, required this.team});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  late final TextEditingController _nameController;
  String? _selectedLogoPath;

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

  void _onLogoTap() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedLogoPath = file.path; // para previsualizar en el header
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de equipo'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final getPlayersByTeamUseCase = context
                .read<GetPlayersByTeamUseCase>();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      TeamDetailCubit(getPlayersByTeamUseCase)
                        ..loadTeam(widget.team.id),
                  child: TeamDetailPage(team: widget.team),
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TeamManagementHeaderRow(
              nameController: _nameController,
              selectedLogoPath: _selectedLogoPath,
              logoUrl: widget.team.logoUrl,
              onLogoTap: _onLogoTap,
            ),
            const SizedBox(height: 16),
            // TODO: Botón para guardar cambios de nombre/escudo cuando conectes el use case de updateTeam
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! Authenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes iniciar sesión para guardar cambios',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final updateTeamUseCase = context.read<UpdateTeamUseCase>();

                  // Por ahora no guardamos cambios de logo en base de datos,
                  // sólo permitimos seleccionar imagen para previsualizar.
                  final String? newLogoUrl = widget.team.logoUrl;

                  final newName = _nameController.text.trim();
                  final updatedTeam = Team(
                    id: widget.team.id,
                    name: newName,
                    category: widget.team.category,
                    logoUrl: newLogoUrl,
                  );

                  final updateResult = await updateTeamUseCase(
                    updatedTeam,
                    authState.user,
                  );

                  updateResult.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    (_) {
                      context.read<HomeCubit>().fetchTeams();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cambios guardados correctamente'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TeamDetailCubit>(),
                        child: TeamRosterPage(team: widget.team),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.groups),
                label: const Text('Modificar plantilla'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDeletePage(team: widget.team),
                    ),
                  );
                },
                icon: const Icon(Icons.sports_soccer, color: Colors.red),
                label: const Text('Eliminar partido'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceDeletePage(team: widget.team),
                    ),
                  ).then((result) {
                    if (result == true) {
                      Navigator.of(context).pop(true);
                    }
                  });
                },
                icon: const Icon(Icons.event_busy, color: Colors.red),
                label: const Text('Eliminar asistencia'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamAccessPage(team: widget.team),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Administrar acceso'),
              ),
            ),
            const SizedBox(height: 12),
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
                  final deleteTeamUseCase = context.read<DeleteTeamUseCase>();
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
                          duration: Duration(seconds: 1),
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
      bottomNavigationBar: TeamBottomBar(team: widget.team),
    );
  }
}
