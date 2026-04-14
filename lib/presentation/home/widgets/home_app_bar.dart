import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/constants/app_branding.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle;

    return AppBar(
      leading: IconButton(
        tooltip: 'Cerrar sesión',
        icon: const Icon(Icons.logout_rounded),
        onPressed: () => context.read<AuthCubit>().logout(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer_rounded,
            size: 24,
            color: scheme.onPrimary,
          ),
          const SizedBox(width: 10),
          Text(AppBranding.mainTitleEs, style: titleStyle),
        ],
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
