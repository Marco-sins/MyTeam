import 'dart:io';

import 'package:football_manager/domain/repositories/i_team_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:football_manager/core/utils/local_image_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/team/delete_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/update_team_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/match/pages/match_delete_page.dart';
import 'package:football_manager/presentation/attendance/pages/attendance_delete_page.dart';
import 'package:football_manager/presentation/team/pages/team_roster_page.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/core/theme/team_screen_tint.dart';
import 'package:football_manager/presentation/team/widgets/team_area_background.dart';
import 'package:football_manager/presentation/team/widgets/team_management_header_row.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_access_page.dart';
import 'package:football_manager/presentation/team/team_session_navigation.dart';

class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  late final TextEditingController _nameController;
  String? _selectedLogoPath;
  late String? _colorHex;

  @override
  void initState() {
    super.initState();
    final t = context.read<TeamContextCubit>().state;
    _nameController = TextEditingController(text: t.name);
    final raw = t.color?.trim();
    _colorHex = (raw == null || raw.isEmpty) ? null : raw;
    context.read<TeamDetailCubit>().loadTeam(t.id);
  }

  Team _previewTeamForBackground() {
    final base = context.read<TeamContextCubit>().state;
    final name = _nameController.text.trim();
    return Team(
      id: base.id,
      name: name.isEmpty ? base.name : name,
      category: base.category,
      logoUrl: _selectedLogoPath ?? base.logoUrl,
      color: _colorHex,
    );
  }

  Future<void> _openColorPalette() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.teamColorSheetTitle,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.teamColorSheetHint,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.restart_alt, color: scheme.primary),
                    title: Text(l10n.teamColorDefault),
                    onTap: () {
                      setState(() => _colorHex = null);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.15,
                        ),
                    itemCount: TeamScreenTint.palette.length,
                    itemBuilder: (context, i) {
                      final e = TeamScreenTint.palette[i];
                      final c = TeamScreenTint.accentColor(e.hex);
                      final selected =
                          _colorHex != null &&
                          _colorHex!.toUpperCase() == e.hex.toUpperCase();
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _colorHex = e.hex);
                            Navigator.of(ctx).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? scheme.onSurface
                                    : Colors.white.withValues(alpha: 0.35),
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  e.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        final safeName =
            'team_logo_${context.read<TeamContextCubit>().state.id}$ext';
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
    final effectiveIcon = iconColor ?? (danger ? scheme.error : scheme.primary);

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
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            )
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: scheme.outline),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    final authState = context.watch<AuthCubit>().state;
    final canDeleteTeam =
        authState is Authenticated &&
        authState.user.teamRoles[team.id] == UserRole.superAdmin;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final teamContext = context.read<TeamContextCubit>();
    final detailCubit = context.read<TeamDetailCubit>();

    return TeamBrandedScope(
      team: _previewTeamForBackground(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.screenTeamManagement),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [TeamQuickNavAppBarButton()],
        ),
        body: SafeArea(
          child: TeamAreaBackground(
            team: _previewTeamForBackground(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(context, l10n.teamMgmtSectionTeamData),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TeamManagementHeaderRow(
                            nameController: _nameController,
                            selectedLogoPath: _selectedLogoPath,
                            logoUrl: team.logoUrl,
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
                                team.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: scheme.secondaryContainer
                                  .withValues(alpha: 0.65),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                l10n.teamMgmtColorRowLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Tooltip(
                                message: l10n.teamMgmtColorPickTooltip,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _openColorPalette,
                                    borderRadius: BorderRadius.circular(9),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: TeamScreenTint.accentColor(
                                          _colorHex,
                                        ),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: scheme.outline.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.07,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final authState = context
                                    .read<AuthCubit>()
                                    .state;
                                if (authState is! Authenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.teamMustLoginSaveChanges,
                                      ),
                                      backgroundColor: scheme.error,
                                    ),
                                  );
                                  return;
                                }

                                String? newLogoUrl =
                                    _selectedLogoPath ?? team.logoUrl;
                                if (_selectedLogoPath != null &&
                                    !_selectedLogoPath!.startsWith('http')) {
                                  final repo = context.read<ITeamRepository>();
                                  final file = File(_selectedLogoPath!);
                                  final bytes = await file.readAsBytes();
                                  final fileName =
                                      'team_logo_${team.id}${p.extension(_selectedLogoPath!)}';
                                  final result = await repo.uploadLogo(
                                    bytes,
                                    fileName,
                                  );
                                  result.fold(
                                    (failure) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.teamMgmtLogoUploadError(
                                              failure.message,
                                            ),
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
                                  id: team.id,
                                  name: newName,
                                  category: team.category,
                                  logoUrl: newLogoUrl,
                                  color: _colorHex,
                                );

                                final updateTeamUseCase = context
                                    .read<UpdateTeamUseCase>();
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
                                    teamContext.setTeam(updatedTeam);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.teamMgmtSaveSuccess),
                                        backgroundColor: scheme.primary,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: Text(l10n.teamSaveDataButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _sectionTitle(context, l10n.teamMgmtSectionRosterAccess),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _navTile(
                          context: context,
                          icon: Icons.groups_2_outlined,
                          title: l10n.teamMgmtEditRosterTitle,
                          subtitle: l10n.teamMgmtEditRosterSubtitle,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: teamContext),
                                    BlocProvider.value(value: detailCubit),
                                  ],
                                  child: TeamRosterPage(team: team),
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        _navTile(
                          context: context,
                          icon: Icons.lock_open_rounded,
                          title: l10n.teamMgmtAccessTitle,
                          subtitle: l10n.teamMgmtAccessSubtitle,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: teamContext,
                                  child: TeamAccessPage(team: team),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _sectionTitle(context, l10n.teamMgmtSectionMaintenance),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _navTile(
                          context: context,
                          icon: Icons.tune_outlined,
                          title: 'Puntuacion de eventos',
                          subtitle:
                              'Crear, modificar y eliminar la puntuacion de eventos de jugador.',
                          onTap: () =>
                              TeamSessionNavigation.openPlayerEventScoring(
                                context,
                              ),
                        ),
                        Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        _navTile(
                          context: context,
                          icon: Icons.sports_soccer_outlined,
                          title: l10n.teamMgmtDeleteMatchesTitle,
                          subtitle: l10n.teamMgmtDeleteMatchesSubtitle,
                          danger: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: teamContext),
                                    BlocProvider.value(value: detailCubit),
                                  ],
                                  child: MatchDeletePage(team: team),
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        _navTile(
                          context: context,
                          icon: Icons.event_busy_outlined,
                          title: l10n.teamMgmtDeleteAttendanceTitle,
                          subtitle: l10n.teamMgmtDeleteAttendanceSubtitle,
                          danger: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: teamContext),
                                    BlocProvider.value(value: detailCubit),
                                  ],
                                  child: AttendanceDeletePage(team: team),
                                ),
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
                  if (canDeleteTeam) ...[
                    _sectionTitle(context, l10n.teamMgmtSectionCritical),
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
                          title: AppLocalizations.of(
                            context,
                          )!.teamDeleteNavTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.teamDeleteNavSubtitle,
                          danger: true,
                          onTap: () async {
                            final authForDelete = context
                                .read<AuthCubit>()
                                .state;
                            if (authForDelete is! Authenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.teamDeleteNeedLogin,
                                  ),
                                  backgroundColor: scheme.error,
                                ),
                              );
                              return;
                            }

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                final dlgL10n = AppLocalizations.of(ctx)!;
                                return AlertDialog(
                                  title: Text(dlgL10n.dialogDeleteTeamTitle),
                                  content: Text(dlgL10n.teamDeleteConfirmBody),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(dlgL10n.actionCancel),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: scheme.error,
                                        foregroundColor: scheme.onError,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(dlgL10n.actionDelete),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm != true || !mounted) return;
                            final deleteTeamUseCase = context
                                .read<DeleteTeamUseCase>();
                            final result = await deleteTeamUseCase(
                              team,
                              authForDelete.user,
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
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.teamDeletedSnackbar,
                                    ),
                                    backgroundColor: scheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
