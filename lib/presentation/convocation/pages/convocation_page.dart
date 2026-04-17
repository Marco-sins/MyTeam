import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/presentation/convocation/cubit/convocation_cubit.dart';
import 'package:football_manager/presentation/convocation/services/convocation_save_service.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_actions_row.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_datetime_section.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_header_section.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_notes_field.dart';
import 'package:football_manager/presentation/convocation/widgets/convocation_players_section.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';
import 'package:football_manager/presentation/team/widgets/team_area_background.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

/// Requiere [TeamContextCubit] en el árbol.
class ConvocationPage extends StatefulWidget {
  const ConvocationPage({super.key});

  @override
  State<ConvocationPage> createState() => _ConvocationPageState();
}

class _ConvocationPageState extends State<ConvocationPage> {
  final TextEditingController _rivalController = TextEditingController();
  final TextEditingController _awayLocationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late final ConvocationCubit _convocationCubit;

  bool _isHome = true;

  TimeOfDay _callTime = TimeOfDay.now();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _rivalController.dispose();
    _awayLocationController.dispose();
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
    final away = _awayLocationController.text.trim();
    await ConvocationSaveService.save(
      context: context,
      rivalController: _rivalController,
      notesController: _notesController,
      isHome: _isHome,
      awayLocation: away.isEmpty ? null : away,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      callTime: _callTime,
      convocationCubit: _convocationCubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    final String formattedDate = _formattedDate(_selectedDate);
    final String formattedMatchTime = _formattedTime(_selectedTime);
    final String formattedCallTime = _formattedTime(_callTime);
    final bottomInset =
        MediaQuery.of(context).padding.bottom + 72;

    return BlocProvider.value(
      value: _convocationCubit,
      child: TeamBrandedScope(
        team: team,
        child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.screenConvocation),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                TeamSessionRoutes.detailHomeReplacingStack(context),
                (route) => route.isFirst,
              );
            },
          ),
          actions: const [TeamQuickNavAppBarButton()],
        ),
        body: TeamAreaBackground(
          team: team,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConvocationHeaderSection(
                    rivalController: _rivalController,
                    awayLocationController: _awayLocationController,
                    isHome: _isHome,
                    onHomeAwayChanged: (home) {
                      setState(() {
                        _isHome = home;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ConvocationDateTimeSection(
                    formattedDate: formattedDate,
                    formattedMatchTime: formattedMatchTime,
                    formattedCallTime: formattedCallTime,
                    onPickDate: _pickDate,
                    onPickMatchTime: _pickTime,
                    onPickCallTime: _pickCallTime,
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<TeamDetailCubit, TeamDetailState>(
                    builder: (context, state) {
                      if (state is TeamDetailLoading ||
                          state is TeamDetailInitial) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      if (state is TeamDetailError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (state is TeamDetailLoaded) {
                        return ConvocationPlayersSection(
                            players: state.players);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 12),
                  ConvocationNotesField(notesController: _notesController),
                  const SizedBox(height: 8),
                  ConvocationActionsRow(
                    onCancel: () => Navigator.of(context).pop(),
                    onSave: _onSavePressed,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const TeamBottomBar(),
        ),
      ),
    );
  }
}
