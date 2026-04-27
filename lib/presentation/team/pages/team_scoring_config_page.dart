import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/data/team_scoring_config_storage.dart';
import 'package:football_manager/domain/entities/team_scoring_config.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/utils/team_scoring_builtin_label.dart';
import 'package:football_manager/presentation/team/utils/team_scoring_duplicate_check.dart';

/// Puntuación por evento para la valoración de jugadores en partidos del equipo.
class TeamScoringConfigPage extends StatefulWidget {
  const TeamScoringConfigPage({super.key, required this.teamId});

  final int teamId;

  @override
  State<TeamScoringConfigPage> createState() => _TeamScoringConfigPageState();
}

class _TeamScoringConfigPageState extends State<TeamScoringConfigPage> {
  final List<TeamScoringLine> _lines = [];
  final List<TextEditingController> _pointsControllers = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  void _loadInitial() {
    final storage = context.read<TeamScoringConfigStorage>();
    final saved = storage.load(widget.teamId);
    final base = saved?.lines ?? TeamScoringConfig.defaultBuiltInLines();
    setState(() {
      _lines.clear();
      _lines.addAll(base);
      _rebuildControllers();
      _loaded = true;
    });
  }

  void _rebuildControllers() {
    for (final c in _pointsControllers) {
      c.dispose();
    }
    _pointsControllers.clear();
    for (final l in _lines) {
      _pointsControllers.add(
        TextEditingController(
          text: _formatPoints(l.points),
        ),
      );
    }
  }

  String _formatPoints(double p) => p.toString();

  @override
  void dispose() {
    for (final c in _pointsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _removeAt(int index) {
    setState(() {
      _lines.removeAt(index);
      _pointsControllers.removeAt(index).dispose();
    });
  }

  void _showAddDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final pointsController = TextEditingController(text: '0.1');
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.teamScoringAddDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.teamScoringEventName,
                  hintText: l10n.teamScoringCustomHint,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: InputDecoration(
                  labelText: l10n.teamScoringPoints,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final p = double.tryParse(
                  pointsController.text.trim().replaceAll(',', '.'),
                );
                if (name.isEmpty || p == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.teamScoringInvalidNumber)),
                  );
                  return;
                }
                final candidate = TeamScoringLine(
                  id: newCustomScoringId(),
                  name: name,
                  points: p,
                );
                if (hasDuplicateScoringLineTitles([..._lines, candidate], l10n)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.teamScoringDuplicateName)),
                  );
                  return;
                }
                setState(() {
                  _lines.add(candidate);
                  _pointsControllers.add(
                    TextEditingController(text: _formatPoints(p)),
                  );
                });
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.actionConfirm),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final updated = <TeamScoringLine>[];
    for (var i = 0; i < _lines.length; i++) {
      final raw = _pointsControllers[i].text.trim().replaceAll(',', '.');
      final p = double.tryParse(raw);
      if (p == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teamScoringInvalidNumber)),
        );
        return;
      }
      final line = _lines[i];
      updated.add(
        TeamScoringLine(id: line.id, name: line.name, points: p),
      );
    }
    if (hasDuplicateScoringLineTitles(updated, l10n)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teamScoringDuplicateName)),
      );
      return;
    }
    final config = TeamScoringConfig(lines: updated);
    await context.read<TeamScoringConfigStorage>().save(
          widget.teamId,
          config,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamMgmtSaveSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamScoringScreenTitle),
        centerTitle: true,
        actions: [
          if (_loaded)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: l10n.teamScoringSave,
              onPressed: _save,
            ),
        ],
      ),
      body: _loaded
          ? Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _lines.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final line = _lines[i];
                      final title = line.isCustom
                          ? (line.name?.trim().isNotEmpty == true
                              ? line.name!
                              : l10n.teamScoringUnnamed)
                          : teamScoringBuiltinTitle(l10n, line.id);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                width: 88,
                                child: TextField(
                                  controller: _pointsControllers[i],
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(
                                        r'^-?[0-9]*\.?[0-9]*',
                                      ),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.teamScoringDeleteTooltip,
                                icon: Icon(Icons.remove_circle_outline,
                                    color: scheme.error),
                                onPressed: () => _removeAt(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: FilledButton.tonalIcon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.teamScoringAddEvent),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
