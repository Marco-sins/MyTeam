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
          _error = 'Debes estar autenticado para ver invitaciones';
          _loading = false;
        });
        return;
      }

      final user = authState.user;
      final getInvitationsByEmailUseCase = context
          .read<GetInvitationsByEmailUseCase>();
      final invitationsResult = await getInvitationsByEmailUseCase(user.email);

      if (!mounted) return;

      invitationsResult.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _loading = false;
          });
        },
        (invitations) async {
          _invitations = invitations;

          if (_invitations.isEmpty) {
            setState(() {
              _loading = false;
            });
            return;
          }

          // Cargar nombres de equipos
          final teamIds = _invitations.map((i) => i.teamId).toSet().toList();
          final getTeamByIdUseCase = context.read<GetTeamByIdUseCase>();
          for (final id in teamIds) {
            final teamResult = await getTeamByIdUseCase(id);
            teamResult.fold((_) {}, (team) => _teamsById[id] = team);
          }

          // Cargar perfiles de quien invita
          final inviterIds = _invitations
              .map((i) => i.invitedByUserId)
              .toSet()
              .toList();
          final getProfilesByIdsUseCase = context
              .read<GetProfilesByIdsUseCase>();
          final profilesResult = await getProfilesByIdsUseCase(inviterIds);
          profilesResult.fold((_) {}, (profiles) {
            for (final profile in profiles) {
              _profilesById[profile.id] = profile;
            }
          });

          if (!mounted) return;
          setState(() {
            _loading = false;
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  final result = await rejectInvitationUseCase(
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
                                          content: Text('Invitación rechazada'),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  final result = await acceptInvitationUseCase(
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
                                      // Refrescamos los equipos de la Home
                                      context.read<HomeCubit>().fetchTeams();

                                      // Mostramos feedback y volvemos a Home
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
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
    );
  }
}
