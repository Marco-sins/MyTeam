import 'dart:io';

import 'package:football_manager/domain/i_repositories/i_team_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:football_manager/core/utils/local_image_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/team/delete_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/update_team_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/match/pages/match_delete_page.dart';
import 'package:football_manager/presentation/attendance/pages/attendance_delete_page.dart';
import 'package:football_manager/presentation/team/pages/team_roster_page.dart';
import 'package:football_manager/presentation/team/widgets/team_management_header_row.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';
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
      if (file.bytes != null) {
        final ext = p.extension(file.name);
        final safeName = 'team_logo_${widget.team.id}$ext';
        final localPath = await LocalImageSaver.saveImageLocally(
          file.bytes!,
          safeName,
        );
        setState(() {
          _selectedLogoPath = localPath;
        });
      } else if (file.path != null) {
        setState(() {
          _selectedLogoPath = file.path;
        });
      }
    }
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
      ),
    );
  }

  Widget _navTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveIcon = iconColor ??
        (danger ? scheme.error : scheme.primary);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: danger
              ? scheme.errorContainer.withValues(alpha: 0.55)
              : scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: effectiveIcon, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: danger ? scheme.error : scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.outline,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(context, 'Datos del equipo'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TeamManagementHeaderRow(
                        nameController: _nameController,
                        selectedLogoPath: _selectedLogoPath,
                        logoUrl: widget.team.logoUrl,
                        onLogoTap: _onLogoTap,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Chip(
                          avatar: Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: scheme.onSecondaryContainer,
                          ),
                          label: Text(
                            widget.team.category,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: scheme.secondaryContainer
                              .withValues(alpha: 0.65),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final authState = context.read<AuthCubit>().state;
                            if (authState is! Authenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Debes iniciar sesión para guardar cambios',
                                  ),
                                  backgroundColor: scheme.error,
                                ),
                              );
                              return;
                            }

                            String? newLogoUrl =
                                _selectedLogoPath ?? widget.team.logoUrl;
                            if (_selectedLogoPath != null &&
                                !_selectedLogoPath!.startsWith('http')) {
                              final repo = context.read<ITeamRepository>();
                              final file = File(_selectedLogoPath!);
                              final bytes = await file.readAsBytes();
                              final fileName =
                                  'team_logo_${widget.team.id}${p.extension(_selectedLogoPath!)}';
                              final result =
                                  await repo.uploadLogo(bytes, fileName);
                              result.fold(
                                (failure) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error subiendo logo: ${failure.message}',
                                      ),
                                      backgroundColor: scheme.error,
                                    ),
                                  );
                                },
                                (url) {
                                  newLogoUrl = url;
                                },
                              );
                            }

                            final newName = _nameController.text.trim();
                            final updatedTeam = Team(
                              id: widget.team.id,
                              name: newName,
                              category: widget.team.category,
                              logoUrl: newLogoUrl,
                            );

                            final updateTeamUseCase =
                                context.read<UpdateTeamUseCase>();
                            final updateResult = await updateTeamUseCase(
                              updatedTeam,
                              authState.user,
                            );

                            if (!mounted) return;
                            updateResult.fold(
                              (failure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(failure.message),
                                    backgroundColor: scheme.error,
                                  ),
                                );
                              },
                              (_) {
                                context.read<HomeCubit>().fetchTeams();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Cambios guardados correctamente',
                                    ),
                                    backgroundColor: scheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar nombre y escudo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _sectionTitle(context, 'Plantilla y acceso'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _navTile(
                      context: context,
                      icon: Icons.groups_2_outlined,
                      title: 'Modificar plantilla',
                      subtitle: 'Altas, bajas y datos de jugadores',
                      onTap: () {
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
                    ),
                    Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    _navTile(
                      context: context,
                      icon: Icons.lock_open_rounded,
                      title: 'Administrar acceso',
                      subtitle: 'Invitar admins o espectadores al equipo',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamAccessPage(team: widget.team),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _sectionTitle(context, 'Mantenimiento de datos'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _navTile(
                      context: context,
                      icon: Icons.sports_soccer_outlined,
                      title: 'Eliminar partidos',
                      subtitle: 'Quita partidos concretos del calendario',
                      danger: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MatchDeletePage(team: widget.team),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    _navTile(
                      context: context,
                      icon: Icons.event_busy_outlined,
                      title: 'Eliminar asistencias',
                      subtitle: 'Borra días de control de asistencia',
                      danger: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AttendanceDeletePage(team: widget.team),
                          ),
                        ).then((result) {
                          if (result == true && mounted) {
                            Navigator.of(context).pop(true);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              _sectionTitle(context, 'Zona crítica'),
              Card(
                color: scheme.errorContainer.withValues(alpha: 0.22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: scheme.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _navTile(
                    context: context,
                    icon: Icons.delete_forever_outlined,
                    title: 'Borrar equipo',
                    subtitle: 'Elimina el club y deja de verlo en inicio',
                    danger: true,
                    onTap: () async {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is! Authenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Debes iniciar sesión para borrar el equipo',
                            ),
                            backgroundColor: scheme.error,
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
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.error,
                                foregroundColor: scheme.onError,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Borrar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true || !mounted) return;
                      final deleteTeamUseCase =
                          context.read<DeleteTeamUseCase>();
                      final result = await deleteTeamUseCase(
                        widget.team,
                        authState.user,
                      );

                      if (!mounted) return;
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(failure.message),
                              backgroundColor: scheme.error,
                            ),
                          );
                        },
                        (_) {
                          context.read<HomeCubit>().fetchTeams();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Equipo borrado correctamente'),
                              backgroundColor: scheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
