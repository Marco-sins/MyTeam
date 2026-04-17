import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/team_session_navigation.dart';

/// Requiere [TeamContextCubit] en el árbol.
class TeamBottomBar extends StatelessWidget {
  const TeamBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;

    final authState = context.watch<AuthCubit>().state;
    var isExternal = false;
    if (authState is Authenticated) {
      isExternal = authState.user.teamRoles[team.id] == UserRole.external;
    }

    final List<Widget> buttons = [];

    if (!isExternal) {
      buttons.addAll([
        _BottomBarButton(
          label: 'Asistencia',
          icon: Icons.check_circle_outline,
          onTap: () => TeamSessionNavigation.openAttendance(context),
        ),
        _BottomBarButton(
          label: 'Convocatoria',
          icon: Icons.list_alt,
          onTap: () => TeamSessionNavigation.openConvocation(context),
        ),
      ]);
    }

    buttons.add(
      _BottomBarButton(
        label: 'Partido',
        icon: Icons.sports_soccer,
        onTap: () => TeamSessionNavigation.openMatchList(context),
      ),
    );

    if (!isExternal) {
      buttons.add(
        _BottomBarButton(
          label: 'Gestión',
          icon: Icons.settings,
          onTap: () => TeamSessionNavigation.openManagement(context),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: BottomAppBar(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: buttons,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _BottomBarButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
