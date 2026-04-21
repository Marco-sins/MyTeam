import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/profile/get_profiles_by_ids_use_case.dart';
import 'package:football_manager/domain/usecase/invitation/create_invitation_use_case.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_area_background.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

class TeamAccessPage extends StatefulWidget {
  const TeamAccessPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamAccessPage> createState() => _TeamAccessPageState();
}

class _TeamAccessPageState extends State<TeamAccessPage>
    with WidgetsBindingObserver {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  String? _currentUserId;
  List<_TeamMember> _members = [];
  RealtimeChannel? _teamMembersChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMembers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeTeamMembersRealtime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final ch = _teamMembersChannel;
    _teamMembersChannel = null;
    if (ch != null) {
      unawaited(_supabase.removeChannel(ch));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMembers(silent: true);
    }
  }

  /// Lista siempre al día: alguien entra/sale del equipo o cambia rol.
  void _subscribeTeamMembersRealtime() {
    final teamId = widget.team.id;
    _teamMembersChannel = _supabase
        .channel(
          'team_access_${teamId}_${_supabase.auth.currentUser?.id ?? 'x'}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'team_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_team',
            value: teamId,
          ),
          callback: (_) {
            if (!mounted) return;
            _loadMembers(silent: true);
          },
        )
        .subscribe();
  }

  Future<void> _loadMembers({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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

      if (!mounted) return;
      final defaultUserName = AppLocalizations.of(
        context,
      )!.accessDefaultUserName;
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
              name: profile?.username ?? defaultUserName,
              email: profile?.email ?? '',
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _members = members;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(context)!.teamAccessLoadMembersError;
        _loading = false;
      });
    }
  }

  ColorScheme _brandedScheme(BuildContext context) =>
      TeamBrandTheme.wrap(context, widget.team.color).colorScheme;

  bool _memberRoleIsSuperAdmin(String roleStr) {
    try {
      return UserRole.fromString(roleStr) == UserRole.superAdmin;
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeMember(_TeamMember member) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final myRole = authState.user.teamRoles[widget.team.id];
    if (myRole == null || !myRole.hasAdminPrivileges) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.accessAdminOnlyRevoke),
          backgroundColor: _brandedScheme(context).error,
        ),
      );
      return;
    }
    UserRole targetRole;
    try {
      targetRole = UserRole.fromString(member.role);
    } catch (_) {
      targetRole = UserRole.external;
    }
    if (targetRole == UserRole.superAdmin && myRole != UserRole.superAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Solo el creador del equipo (superadmin) puede quitar a otro superadmin.',
          ),
          backgroundColor: _brandedScheme(context).error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dlgL10n = AppLocalizations.of(ctx)!;
        final dlgScheme = _brandedScheme(ctx);
        return Theme(
          data: TeamBrandTheme.wrap(ctx, widget.team.color),
          child: AlertDialog(
            title: Text(dlgL10n.dialogRevokeAccessTitle),
            content: Text(dlgL10n.accessRevokeBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(dlgL10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: dlgScheme.error,
                  foregroundColor: dlgScheme.onError,
                ),
                child: Text(dlgL10n.accessRevokeAction),
              ),
            ],
          ),
        );
      },
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
      final okScheme = _brandedScheme(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.accessRevokedOk,
            style: TextStyle(color: okScheme.onPrimary),
          ),
          backgroundColor: okScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.accessRevokeFail),
          backgroundColor: _brandedScheme(context).error,
        ),
      );
    }
  }

  Future<void> _showInviteDialog() async {
    final authForInvite = context.read<AuthCubit>().state;
    final myRoleForInvite = authForInvite is Authenticated
        ? authForInvite.user.teamRoles[widget.team.id]
        : null;
    final canInviteAsAdmin = myRoleForInvite == UserRole.superAdmin;

    final emailController = TextEditingController();
    var selectedRole = 'external';

    final result = await showDialog<_InviteData>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final scheme = _brandedScheme(ctx);
            final l10n = AppLocalizations.of(ctx)!;
            return Theme(
              data: TeamBrandTheme.wrap(ctx, widget.team.color),
              child: AlertDialog(
                title: Text(l10n.dialogInviteUserTitle),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.loginEmailLabel,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.accessInviteRole,
                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (canInviteAsAdmin)
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'external',
                              label: Text(l10n.roleSpectator),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                            ),
                            ButtonSegment(
                              value: 'admin',
                              label: Text(l10n.roleAdmin),
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18,
                              ),
                            ),
                          ],
                          selected: {selectedRole},
                          onSelectionChanged: (s) {
                            setState(() => selectedRole = s.first);
                          },
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.accessInviteSpectatorOnlyHint,
                              style: Theme.of(ctx).textTheme.bodyMedium
                                  ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 20,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        l10n.roleSpectator,
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        return;
                      }
                      Navigator.of(
                        ctx,
                      ).pop(_InviteData(email: email, role: selectedRole));
                    },
                    child: Text(l10n.accessInviteSend),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.accessInviteNeedAuth),
          backgroundColor: _brandedScheme(context).error,
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
        final s = _brandedScheme(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: s.error),
        );
      },
      (_) {
        final loc = AppLocalizations.of(context)!;
        final s = _brandedScheme(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.accessInviteSent(
                result.email,
                result.role == 'admin' ? loc.roleAdmin : loc.roleSpectator,
              ),
              style: TextStyle(color: s.onPrimary),
            ),
            backgroundColor: s.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandingTeam = context.watch<TeamContextCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthCubit>().state;
    final UserRole? myTeamRole = authState is Authenticated
        ? authState.user.teamRoles[widget.team.id]
        : null;
    final bool canManageAccess = myTeamRole?.hasAdminPrivileges ?? false;

    return TeamBrandedScope(
      team: widget.team,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.screenTeamAccess),
              actions: const [TeamQuickNavAppBarButton()],
            ),
            body: SafeArea(
              top: false,
              child: TeamAreaBackground(
                team: widget.team,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _loading
                      ? RefreshIndicator(
                          onRefresh: _loadMembers,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.35,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                      ? RefreshIndicator(
                          onRefresh: _loadMembers,
                          child: ListView(
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
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMembers,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      brandingTeam.name,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        color: scheme.onSurface,
                                        height: 1.15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 14),
                                    Card(
                                      margin: EdgeInsets.zero,
                                      color: scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.55),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          12,
                                          14,
                                          12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.people_outline_rounded,
                                                  size: 22,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    l10n.accessUsersWithAccess,
                                                    style: textTheme.titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              l10n.accessListBlurb,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                    height: 1.35,
                                                  ),
                                            ),
                                            if (_members.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                _members.length == 1
                                                    ? l10n.accessPeopleCountSingle
                                                    : l10n.accessPeopleCountMany(
                                                        _members.length,
                                                      ),
                                                style: textTheme.labelLarge
                                                    ?.copyWith(
                                                      color: scheme.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              if (_members.isEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.group_add_outlined,
                                          size: 56,
                                          color: scheme.outline.withValues(
                                            alpha: 0.65,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.accessEmptyMembersTitle,
                                          style: textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.accessEmptyMembersHint,
                                          style: textTheme.bodySmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SliverToBoxAdapter(
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      itemCount: _members.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            height: 1,
                                            indent: 16,
                                            endIndent: 16,
                                            color: scheme.outlineVariant
                                                .withValues(alpha: 0.45),
                                          ),
                                      itemBuilder: (context, index) {
                                        final member = _members[index];
                                        final isCurrentUser =
                                            member.idUser == _currentUserId;
                                        final bool hideRemoveForTarget =
                                            _memberRoleIsSuperAdmin(
                                              member.role,
                                            ) &&
                                            myTeamRole != UserRole.superAdmin;
                                        final bool showRemoveButton =
                                            canManageAccess &&
                                            !isCurrentUser &&
                                            !hideRemoveForTarget;

                                        final displayName =
                                            member.name.isNotEmpty
                                            ? member.name
                                            : l10n.accessProfileNoName;
                                        final displayEmail =
                                            member.email.isNotEmpty
                                            ? member.email
                                            : l10n.accessProfileNoEmail;

                                        return ListTile(
                                          isThreeLine: true,
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                scheme.surfaceContainerHighest,
                                            child: Text(
                                              (member.name.isNotEmpty
                                                      ? member.name[0]
                                                      : '?')
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            '${l10n.accessNamePrefix}$displayName',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${l10n.accessEmailPrefix}$displayEmail',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            member
                                                                .email
                                                                .isNotEmpty
                                                            ? scheme
                                                                  .onSurfaceVariant
                                                            : scheme.outline,
                                                        fontStyle:
                                                            member
                                                                .email
                                                                .isNotEmpty
                                                            ? FontStyle.normal
                                                            : FontStyle.italic,
                                                        height: 1.3,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${l10n.accessRolePrefix}${_roleLabel(member.role, l10n)}',
                                                  style: textTheme.labelLarge
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          trailing: isCurrentUser
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  child: Text(
                                                    l10n.accessYou,
                                                    style: textTheme.labelLarge
                                                        ?.copyWith(
                                                          color: scheme.primary,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                )
                                              : showRemoveButton
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .person_remove_outlined,
                                                    color: scheme.error,
                                                  ),
                                                  tooltip: l10n
                                                      .dialogRevokeAccessTitle,
                                                  onPressed: () =>
                                                      _removeMember(member),
                                                )
                                              : const SizedBox.shrink(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: canManageAccess
                                      ? FilledButton.icon(
                                          onPressed: _showInviteDialog,
                                          icon: const Icon(
                                            Icons.person_add_alt_1_rounded,
                                          ),
                                          label: Text(
                                            l10n.dialogInviteUserTitle,
                                          ),
                                        )
                                      : Text(
                                          l10n.accessAdminOnlyInvite,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            height: 1.35,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(String role, AppLocalizations l10n) {
    switch (role.trim().toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
        return l10n.roleSuperAdmin;
      case 'admin':
        return l10n.roleAdmin;
      case 'player':
        return l10n.rolePlayer;
      case 'external':
      default:
        return l10n.roleSpectator;
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
