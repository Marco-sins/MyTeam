import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

/// Requiere [TeamContextCubit] y normalmente [TeamDetailCubit] en el árbol.
class ConvocationImagePage extends StatelessWidget {
  final File imageFile;

  const ConvocationImagePage({
    super.key,
    required this.imageFile,
  });

  void _goToTeamHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      TeamSessionRoutes.detailHomeReplacingStack(context),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.screenConvocationGenerated),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goToTeamHome(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: l10n.shareImageTooltip,
              onPressed: () async {
                await Share.shareXFiles([
                  XFile(imageFile.path),
                ], text: l10n.convocationShareText(team.name));
              },
            ),
            const TeamQuickNavAppBarButton(),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.file(imageFile),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                    child: ElevatedButton(
                    onPressed: () => _goToTeamHome(context),
                    child: Text(l10n.backToTeam),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const TeamBottomBar(),
      ),
    );
  }
}
