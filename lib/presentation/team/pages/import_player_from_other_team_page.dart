import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/player/import_player_from_other_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_teams_use_case.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';

/// Importa un jugador desde otro equipo donde el usuario también es admin/superadmin.
class ImportPlayerFromOtherTeamPage extends StatefulWidget {
  final Team targetTeam;

  const ImportPlayerFromOtherTeamPage({super.key, required this.targetTeam});

  @override
  State<ImportPlayerFromOtherTeamPage> createState() =>
      _ImportPlayerFromOtherTeamPageState();
}

class _ImportPlayerFromOtherTeamPageState
    extends State<ImportPlayerFromOtherTeamPage> {
  Team? _sourceTeam;
  List<Team> _adminTeams = [];
  List<Player> _players = [];
  bool _loadingTeams = true;
  bool _loadingPlayers = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAdminTeams();
  }

  Future<void> _loadAdminTeams() async {
    setState(() {
      _loadingTeams = true;
      _loadError = null;
    });

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      setState(() {
        _loadingTeams = false;
      });
      return;
    }
    final user = authState.user;
    final adminIds = user.teamRoles.entries
        .where((e) => e.value.hasAdminPrivileges)
        .map((e) => e.key)
        .where((id) => id != widget.targetTeam.id)
        .toSet();

    final getTeams = context.read<GetTeamsUseCase>();
    final result = await getTeams();
    if (!mounted) return;

    result.fold(
      (f) {
        setState(() {
          _loadingTeams = false;
          _loadError = f.message;
        });
      },
      (teams) {
        final filtered =
            teams.where((t) => adminIds.contains(t.id)).toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        setState(() {
          _loadingTeams = false;
          _adminTeams = filtered;
          if (filtered.length == 1) {
            _sourceTeam = filtered.first;
            _loadPlayersFor(_sourceTeam!);
          }
        });
      },
    );
  }

  Future<void> _loadPlayersFor(Team team) async {
    setState(() {
      _loadingPlayers = true;
      _players = [];
    });
    final uc = context.read<GetPlayersByTeamUseCase>();
    final result = await uc(team.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() {
          _loadingPlayers = false;
          _loadError = f.message;
        });
      },
      (list) {
        final sorted = List<Player>.of(list)
          ..sort((a, b) => (a.number ?? 999).compareTo(b.number ?? 999));
        setState(() {
          _loadingPlayers = false;
          _players = sorted;
        });
      },
    );
  }

  Future<void> _confirmImport(Player source, AuthUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final sourceName = _sourceTeam?.name ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.teamImportPlayerConfirmTitle),
          content: Text(
            l10n.teamImportPlayerConfirmBody(source.fullName, sourceName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.teamImportPlayerConfirmAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    final importUc = context.read<ImportPlayerFromOtherTeamUseCase>();
    final result = await importUc(
      sourcePlayer: source,
      targetTeamId: widget.targetTeam.id,
      user: user,
    );
    if (!mounted) return;

    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) {
        // El mensaje de éxito se muestra en la pantalla anterior tras el pop
        // (si se muestra aquí, desaparece al descartar esta ruta).
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;

    return TeamBrandedScope(
      team: widget.targetTeam,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.teamImportPlayerTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.teamImportPlayerSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.teamImportPlayerStatsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                if (_loadingTeams)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (user == null)
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.teamMustLoginAddPlayers,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (_loadError != null && _adminTeams.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: scheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (_adminTeams.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.teamImportPlayerNoSourceTeams,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    l10n.teamImportPlayerSelectTeam,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Team>(
                        isExpanded: true,
                        value: _sourceTeam,
                        hint: Text(
                          l10n.teamImportPlayerSelectTeam,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        items: _adminTeams
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (t) {
                          setState(() => _sourceTeam = t);
                          if (t != null) {
                            _loadPlayersFor(t);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _sourceTeam == null
                        ? Center(
                            child: Text(
                              l10n.teamImportPlayerPickTeamFirst,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : _loadingPlayers
                            ? const Center(child: CircularProgressIndicator())
                            : _players.isEmpty
                                ? Center(
                                    child: Text(
                                      l10n.teamImportPlayerEmptyRoster,
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _players.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                      height: 1,
                                      color: scheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    itemBuilder: (context, index) {
                                      final p = _players[index];
                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        leading: PlayerAvatar(
                                          player: p,
                                          radius: 22,
                                        ),
                                        title: PlayerNameText(
                                          player: p,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '#${p.number ?? '—'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: scheme.outline,
                                        ),
                                        onTap: () => _confirmImport(p, user),
                                      );
                                    },
                                  ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
