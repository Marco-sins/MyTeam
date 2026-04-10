import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/usecase/invitation/get_invitations_by_email_use_case.dart';
import 'package:football_manager/presentation/home/widgets/add_team.dart';
import 'package:football_manager/presentation/invitations/pages/invitations_page.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/pages/login_page.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_empty.dart';
import '../widgets/team_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _invitationsCount = 0;

  @override
  void initState() {
    super.initState();
    // Siempre que se construye HomePage, cargamos los equipos
    context.read<HomeCubit>().fetchTeams();
    _loadInvitationsCount();
  }

  Future<void> _loadInvitationsCount() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      if (mounted) {
        setState(() {
          _invitationsCount = 0;
        });
      }
      return;
    }

    try {
      final getInvitationsByEmailUseCase = context
          .read<GetInvitationsByEmailUseCase>();
      final result = await getInvitationsByEmailUseCase(authState.user.email);

      if (!mounted) return;

      result.fold(
        (_) {
          setState(() {
            _invitationsCount = 0;
          });
        },
        (invitations) {
          setState(() {
            _invitationsCount = invitations.length;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invitationsCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: const HomeAppBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'invitations',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvitationsPage(),
                      ),
                    );
                    if (!mounted) return;
                    _loadInvitationsCount();
                  },
                  backgroundColor: Colors.grey.shade200,
                  icon: const Icon(Icons.mail_outline, color: Colors.black87),
                  label: const Text(
                    'Invitaciones',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                if (_invitationsCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_invitationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            const AddTeam(),
          ],
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading || state is HomeInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (state is HomeLoaded) {
              if (state.teams.isEmpty) {
                return const HomeEmpty();
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int crossAxisCount = 2; // móviles por defecto
                  if (width >= 1200) {
                    crossAxisCount = 4; // escritorio / pantallas muy grandes
                  } else if (width >= 800) {
                    crossAxisCount = 3; // tablets o móviles muy anchos
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 190,
                    ),
                    itemCount: state.teams.length,
                    itemBuilder: (context, index) {
                      final team = state.teams[index];
                      return TeamCard(team: team);
                    },
                  );
                },
              );
            }

            if (state is HomeError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
