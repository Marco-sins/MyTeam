import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/team_session_navigation.dart';

/// Icono de menú en la [AppBar] (junto al título de la app / pantalla).
class TeamQuickNavAppBarButton extends StatelessWidget {
  const TeamQuickNavAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menú del equipo',
      onPressed: () => openTeamQuickNavPanel(context),
    );
  }
}

/// Panel lateral derecho a altura completa, fondo blanco.
void openTeamQuickNavPanel(BuildContext hostContext) {
  final team = hostContext.read<TeamContextCubit>().state;
  final authState = hostContext.read<AuthCubit>().state;
  var isExternal = false;
  if (authState is Authenticated) {
    isExternal = TeamSessionNavigation.isExternalMember(hostContext, team.id);
  }

  final screenWidth = MediaQuery.sizeOf(hostContext).width;
  final panelWidth = math.min(320.0, screenWidth * 0.9);

  showGeneralDialog<void>(
    context: hostContext,
    barrierDismissible: true,
    barrierLabel:
        MaterialLocalizations.of(hostContext).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final padding = MediaQuery.paddingOf(dialogContext);
      const textPrimary = Color(0xFF1C1B1F);
      const textSecondary = Color(0xFF49454F);

      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(dialogContext),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: panelWidth,
            child: Material(
              color: Colors.white,
              elevation: 16,
              shadowColor: Colors.black26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: padding.top),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: textPrimary,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: padding.bottom + 24),
                      children: [
                        _PanelTile(
                          icon: Icons.home_outlined,
                          title: 'Mis equipos',
                          onTap: () {
                            Navigator.pop(dialogContext);
                            TeamSessionNavigation.popToAppHome(hostContext);
                          },
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        _PanelTile(
                          icon: Icons.groups_2_outlined,
                          title: team.name,
                          subtitle: 'Inicio del equipo',
                          onTap: () {
                            Navigator.pop(dialogContext);
                            TeamSessionNavigation.goToTeamHome(hostContext);
                          },
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const Divider(height: 1),
                        if (!isExternal) ...[
                          _PanelTile(
                            icon: Icons.check_circle_outline,
                            title: 'Asistencia',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              TeamSessionNavigation.openAttendance(hostContext);
                            },
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _PanelTile(
                            icon: Icons.list_alt,
                            title: 'Convocatoria',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              TeamSessionNavigation.openConvocation(hostContext);
                            },
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        _PanelTile(
                          icon: Icons.sports_soccer,
                          title: 'Partido',
                          onTap: () {
                            Navigator.pop(dialogContext);
                            TeamSessionNavigation.openMatchList(hostContext);
                          },
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        if (!isExternal)
                          _PanelTile(
                            icon: Icons.settings_outlined,
                            title: 'Gestión',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              TeamSessionNavigation.openManagement(hostContext);
                            },
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PanelTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textSecondary;

  const _PanelTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 24, color: textPrimary),
          ],
        ),
      ),
    );
  }
}
