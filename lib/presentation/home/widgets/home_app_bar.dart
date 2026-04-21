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
      title: LayoutBuilder(
        builder: (context, constraints) {
          final titleText = Text(
            l10n.appTitle,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          );
          // Con centerTitle + acciones anchas el hueco del título puede ser < 40 px;
          // icono + separador ya no caben sin desbordar.
          if (constraints.maxWidth < 48) {
            return titleText;
          }
          return Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer_rounded,
                size: 22,
                color: scheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Flexible(child: titleText),
            ],
          );
        },
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
