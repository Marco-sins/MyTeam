import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/profile/get_profiles_by_ids_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/create_invitation_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';

class TeamAccessPage extends StatefulWidget {
  const TeamAccessPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamAccessPage> createState() => _TeamAccessPageState();
}

class _TeamAccessPageState extends State<TeamAccessPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  String? _currentUserId;
  List<_TeamMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final rows = await _supabase
          .from('team_members')
          .select('id_user, role')
          .eq('id_team', widget.team.id);

      final userIds = <String>{};
      for (final row in rows) {
        final idUser = row['id_user'] as String?;
        if (idUser != null) {
          userIds.add(idUser);
        }
      }

      final profilesById = <String, Profile>{};
      if (userIds.isNotEmpty && mounted) {
        final getProfilesByIdsUseCase = context.read<GetProfilesByIdsUseCase>();
        final result = await getProfilesByIdsUseCase(userIds.toList());
        result.fold((_) {}, (profiles) {
          for (final profile in profiles) {
            profilesById[profile.id] = profile;
          }
        });
      }

      final members = <_TeamMember>[];
      for (final row in rows) {
        final idUser = row['id_user'] as String?;
        final role = row['role'] as String? ?? 'external';
        if (idUser != null) {
          final profile = profilesById[idUser];
          members.add(
            _TeamMember(
              idUser: idUser,
              role: role,
              name: profile?.username ?? 'Usuario',
              email: profile?.email ?? '',
            ),
          );
        }
      }

      setState(() {
        _currentUserId = currentUserId;
        _members = members;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se han podido cargar los miembros del equipo';
        _loading = false;
      });
    }
  }

  Future<void> _removeMember(_TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar acceso'),
        content: const Text(
          '¿Seguro que quieres quitar el acceso a este usuario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase
          .from('team_members')
          .delete()
          .eq('id_team', widget.team.id)
          .eq('id_user', member.idUser);

      setState(() {
        _members.removeWhere((m) => m.idUser == member.idUser);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso eliminado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido quitar el acceso'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    String selectedRole = 'external'; // espectador por defecto

    final result = await showDialog<_InviteData>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Invitar usuario'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rol',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => selectedRole = 'external');
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedRole == 'external'
                                ? Colors.green.shade50
                                : null,
                          ),
                          child: const Text('Espectador'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => selectedRole = 'admin');
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedRole == 'admin'
                                ? Colors.green.shade50
                                : null,
                          ),
                          child: const Text('Admin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      return;
                    }
                    Navigator.of(
                      ctx,
                    ).pop(_InviteData(email: email, role: selectedRole));
                  },
                  child: const Text('Invitar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes estar autenticado para enviar invitaciones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = authState.user;
    final selectedUserRole = UserRole.fromString(result.role);

    final invitation = Invitation(
      email: result.email,
      teamId: widget.team.id,
      invitedByUserId: currentUser.id,
      role: selectedUserRole,
    );

    final createInvitationUseCase = context.read<CreateInvitationUseCase>();
    final response = await createInvitationUseCase(invitation, currentUser);

    if (!mounted) return;
    response.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invitación enviada a ${result.email} como '
              '${result.role == 'admin' ? 'admin' : 'espectador'}.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar acceso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipo: ${widget.team.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _members.isEmpty
                        ? const Center(
                            child: Text('No hay usuarios con acceso todavía.'),
                          )
                        : ListView.separated(
                            itemCount: _members.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final isCurrentUser =
                                  member.idUser == _currentUserId;

                              return ListTile(
                                title: Text(
                                  member.name.isNotEmpty
                                      ? member.name
                                      : 'Usuario',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (member.email.isNotEmpty)
                                      Text(
                                        member.email,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    Text(
                                      'Rol: ${_roleLabel(member.role)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: isCurrentUser
                                    ? null
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Quitar acceso',
                                        onPressed: () => _removeMember(member),
                                      ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _showInviteDialog,
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Invitar'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'player':
        return 'Jugador';
      case 'external':
      default:
        return 'Espectador';
    }
  }
}

class _TeamMember {
  _TeamMember({
    required this.idUser,
    required this.role,
    required this.name,
    required this.email,
  });

  final String idUser;
  final String role;
  final String name;
  final String email;
}

class _InviteData {
  _InviteData({required this.email, required this.role});

  final String email;
  final String role;
}
