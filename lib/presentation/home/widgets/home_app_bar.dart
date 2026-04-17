import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/home/widgets/home_language_selector.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      leading: IconButton(
        tooltip: l10n.homeLogoutTooltip,
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
          Text(l10n.appTitle, style: titleStyle),
        ],
      ),
      centerTitle: true,
      actions: const [
        HomeLanguageSelector(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
