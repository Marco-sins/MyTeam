import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_cubit.dart';
import 'package:football_manager/presentation/convocation/services/convocation_save_service.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_actions_row.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_datetime_section.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_header_section.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_notes_field.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_players_section.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_state.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';

class ConvocationPage extends StatefulWidget {
  final Team team;

  const ConvocationPage({super.key, required this.team});

  @override
  State<ConvocationPage> createState() => _ConvocationPageState();
}

class _ConvocationPageState extends State<ConvocationPage> {
  final TextEditingController _rivalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late final ConvocationCubit _convocationCubit;

  bool _isHome = true;
  String? _awayLocation;

  TimeOfDay _callTime = TimeOfDay.now();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _rivalController.dispose();
    _notesController.dispose();
    _convocationCubit.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _convocationCubit = ConvocationCubit();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickCallTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _callTime,
    );
    if (picked != null) {
      setState(() {
        _callTime = picked;
      });
    }
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formattedTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _onSavePressed() async {
    await ConvocationSaveService.save(
      context: context,
      team: widget.team,
      rivalController: _rivalController,
      notesController: _notesController,
      isHome: _isHome,
      awayLocation: _awayLocation,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      callTime: _callTime,
      convocationCubit: _convocationCubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _formattedDate(_selectedDate);
    final String formattedMatchTime = _formattedTime(_selectedTime);
    final String formattedCallTime = _formattedTime(_callTime);

    return BlocProvider.value(
      value: _convocationCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Convocatoria'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final getPlayersByTeamUseCase = context
                  .read<GetPlayersByTeamUseCase>();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        TeamDetailCubit(getPlayersByTeamUseCase)
                          ..loadTeam(widget.team.id),
                    child: TeamDetailPage(team: widget.team),
                  ),
                ),
                (route) => route.isFirst,
              );
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ConvocationHeaderSection(
                  rivalController: _rivalController,
                  isHome: _isHome,
                  awayLocation: _awayLocation,
                  onToggleHomeAway: () {
                    setState(() {
                      _isHome = !_isHome;
                    });
                  },
                  onAwayLocationSelected: (location) {
                    setState(() {
                      _awayLocation = location;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ConvocationDateTimeSection(
                  formattedDate: formattedDate,
                  formattedMatchTime: formattedMatchTime,
                  formattedCallTime: formattedCallTime,
                  onPickDate: _pickDate,
                  onPickMatchTime: _pickTime,
                  onPickCallTime: _pickCallTime,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                BlocBuilder<TeamDetailCubit, TeamDetailState>(
                  builder: (context, state) {
                    if (state is TeamDetailLoading ||
                        state is TeamDetailInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TeamDetailError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is TeamDetailLoaded) {
                      return ConvocationPlayersSection(players: state.players);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Divider(height: 1),
                ConvocationNotesField(notesController: _notesController),
                ConvocationActionsRow(
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _onSavePressed,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: TeamBottomBar(team: widget.team),
      ),
    );
  }
}
