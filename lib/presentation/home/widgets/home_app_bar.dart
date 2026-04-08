import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_cubit.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => context.read<AuthCubit>().logout(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.sports_soccer, size: 22),
          SizedBox(width: 8),
          Text("Team Manager", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
