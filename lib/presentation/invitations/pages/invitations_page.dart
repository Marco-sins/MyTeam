import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/invitation/get_invitations_by_email_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/accept_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/reject_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_team_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/profile/get_profiles_by_ids_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  bool _loading = true;
  String? _error;
  List<Invitation> _invitations = [];
  final Map<int, Team> _teamsById = {};
  final Map<String, Profile> _profilesById = {};
  String? _loadedForEmail;
  RealtimeChannel? _invitationChannel;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeInvitationsRealtime();
    });
  }

  @override
  void dispose() {
    final ch = _invitationChannel;
    _invitationChannel = null;
    if (ch != null) {
      unawaited(Supabase.instance.client.removeChannel(ch));
    }
    super.dispose();
  }

  void _subscribeInvitationsRealtime() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final inboxEmail = authState.user.email.trim().toLowerCase();
    if (inboxEmail.isEmpty) return;

    _invitationChannel = Supabase.instance.client
        .channel(
          'inv_list_${inboxEmail.hashCode}_${authState.user.id.hashCode}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invitation',
          callback: (payload) {
            String? rowEmail;
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                rowEmail = payload.newRecord['email']?.toString();
                break;
              case PostgresChangeEvent.update:
                rowEmail =
                    payload.newRecord['email']?.toString() ??
                    payload.oldRecord['email']?.toString();
                break;
              case PostgresChangeEvent.delete:
                rowEmail = payload.oldRecord['email']?.toString();
                break;
              case PostgresChangeEvent.all:
                return;
            }
            if (rowEmail == null) return;
            if (rowEmail.trim().toLowerCase() != inboxEmail) return;
            if (!mounted) return;
            _loadInvitations(force: true);
          },
        )
        .subscribe();
  }

  Future<void> _loadInvitations({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final user = authState.user;
      final normalizedEmail = user.email.trim().toLowerCase();
      if (!force &&
          _loadedForEmail == normalizedEmail &&
          _invitations.isNotEmpty) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final getInvitationsByEmailUseCase = context
          .read<GetInvitationsByEmailUseCase>();
      final invitationsResult = await getInvitationsByEmailUseCase(
        normalizedEmail,
      );

      if (!mounted) return;

      invitationsResult.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _loading = false;
          });
        },
        (invitations) {
          _loadedForEmail = normalizedEmail;
          _invitations = invitations;
          _teamsById.clear();
          _profilesById.clear();

          setState(() {
            _loading = false;
          });

          if (_invitations.isEmpty) {
            return;
          }

          unawaited(_loadInvitationMetadata(invitations));
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se han podido cargar las invitaciones';
        _loading = false;
      });
    }
  }

  Future<void> _loadInvitationMetadata(List<Invitation> invitations) async {
    try {
      final teamIds = invitations.map((i) => i.teamId).toSet().toList();
      final inviterIds = invitations
          .map((i) => i.invitedByUserId)
          .toSet()
          .toList();

      final getTeamByIdUseCase = context.read<GetTeamByIdUseCase>();
      final teamResults = await Future.wait(
        teamIds.map((id) async => MapEntry(id, await getTeamByIdUseCase(id))),
      );

      for (final entry in teamResults) {
        entry.value.fold((_) {}, (team) => _teamsById[entry.key] = team);
      }

      if (inviterIds.isNotEmpty) {
        final getProfilesByIdsUseCase = context.read<GetProfilesByIdsUseCase>();
        final profilesResult = await getProfilesByIdsUseCase(inviterIds);
        profilesResult.fold((_) {}, (profiles) {
          for (final profile in profiles) {
            _profilesById[profile.id] = profile;
          }
        });
      }

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // Si fallan los datos auxiliares, seguimos mostrando la invitación.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is Authenticated,
      listener: (context, state) {
        _loadInvitations();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.homeInvitations),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => _loadInvitations(force: true),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.35,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    )
                  : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: scheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _invitations.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.35,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mark_email_read_outlined,
                                size: 56,
                                color: scheme.outline.withValues(alpha: 0.65),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay invitaciones pendientes',
                                style: textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cuando te inviten a un equipo, aparecerán aquí.',
                                style: textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _invitations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final invitation = _invitations[index];
                        final team = _teamsById[invitation.teamId];
                        final inviter =
                            _profilesById[invitation.invitedByUserId];

                        final teamName = team?.name ?? 'Equipo desconocido';
                        final inviterName = inviter?.username ?? 'Alguien';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invitación a $teamName',
                                  style: textTheme.titleSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'De: $inviterName',
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: scheme.error,
                                      ),
                                      tooltip: 'Rechazar invitación',
                                      onPressed: () async {
                                        final authState = context
                                            .read<AuthCubit>()
                                            .state;
                                        if (authState is! Authenticated) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Debes estar autenticado para rechazar invitaciones',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final rejectInvitationUseCase = context
                                            .read<RejectInvitationUseCase>();
                                        final result =
                                            await rejectInvitationUseCase(
                                              invitation,
                                              authState.user,
                                            );

                                        if (!mounted) return;
                                        result.fold(
                                          (failure) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(failure.message),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          },
                                          (_) {
                                            setState(() {
                                              _invitations.removeAt(index);
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invitación rechazada',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.check_rounded,
                                        color: scheme.primary,
                                      ),
                                      tooltip: 'Aceptar invitación',
                                      onPressed: () async {
                                        final authState = context
                                            .read<AuthCubit>()
                                            .state;
                                        if (authState is! Authenticated) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Debes estar autenticado para aceptar invitaciones',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final acceptInvitationUseCase = context
                                            .read<AcceptInvitationUseCase>();
                                        final result =
                                            await acceptInvitationUseCase(
                                              invitation,
                                              authState.user,
                                            );

                                        if (!mounted) return;
                                        await result.fold<Future<void>>(
                                          (failure) async {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(failure.message),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          },
                                          (_) async {
                                            // Recargar roles desde team_members para que la UI
                                            // (permisos, espectador, etc.) use el rol de la invitación al instante.
                                            await context
                                                .read<AuthCubit>()
                                                .refreshAuthenticatedUser();
                                            if (!mounted) return;
                                            context
                                                .read<HomeCubit>()
                                                .fetchTeams();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invitación aceptada. Ya puedes ver el equipo.',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 1),
                                              ),
                                            );

                                            Navigator.of(context).pop();
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
