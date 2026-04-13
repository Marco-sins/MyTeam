import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/invitation/get_invitations_by_email_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/accept_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/reject_invitation_use_case.dart';
import 'package:football_manager/domain/usecase/team/get_team_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/profile/get_profiles_by_ids_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/home/bloc/home_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
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
      if (_loadedForEmail == normalizedEmail && _invitations.isNotEmpty) {
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
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is Authenticated,
      listener: (context, state) {
        _loadInvitations();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Invitaciones')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _invitations.isEmpty
              ? const Center(child: Text('No tienes invitaciones pendientes.'))
              : ListView.separated(
                  itemCount: _invitations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final invitation = _invitations[index];
                    final team = _teamsById[invitation.teamId];
                    final inviter = _profilesById[invitation.invitedByUserId];

                    final teamName = team?.name ?? 'Equipo desconocido';
                    final inviterName = inviter?.username ?? 'Alguien';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Te han invitado al equipo $teamName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Por: $inviterName',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
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
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
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
                                        context.read<HomeCubit>().fetchTeams();
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
    );
  }
}
