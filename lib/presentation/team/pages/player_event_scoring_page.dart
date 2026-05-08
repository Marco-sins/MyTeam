import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/presentation/match/cubit/player_event_rating_settings_cubit.dart';
import 'package:football_manager/presentation/match/utils/player_event_rating_settings_store.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';

class PlayerEventScoringPage extends StatefulWidget {
  const PlayerEventScoringPage({super.key});

  @override
  State<PlayerEventScoringPage> createState() => _PlayerEventScoringPageState();
}

class _PlayerEventScoringPageState extends State<PlayerEventScoringPage> {
  @override
  void initState() {
    super.initState();
    // Cargar reglas del equipo cuando la página se inicializa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final teamContext = context.read<TeamContextCubit>();
        context.read<PlayerEventRatingSettingsCubit>().loadForTeam(
          teamContext.state.id,
        );
      } catch (_) {
        // Si no hay equipo en contexto, no hacer nada
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      PlayerEventRatingSettingsCubit,
      PlayerEventRatingSettingsState
    >(
      builder: (context, state) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Puntuacion de eventos'),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () => context
                          .read<PlayerEventRatingSettingsCubit>()
                          .resetToDefaults(),
                child: const Text('Reset'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isLoading ? null : () => _editRule(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear'),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (state.error != null) ...[
                      Card(
                        color: scheme.errorContainer.withValues(alpha: 0.25),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(state.error!),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Edita cuanto suma o resta cada evento de jugador en la puntuacion.',
                    ),
                    const SizedBox(height: 12),
                    for (final rule in state.rules)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            rule.enabled ? Icons.tune : Icons.block,
                            color: rule.enabled
                                ? scheme.primary
                                : scheme.outline,
                          ),
                          title: Text(rule.label),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rule.points.toStringAsFixed(2),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: rule.enabled,
                                onChanged: (value) {
                                  context
                                      .read<PlayerEventRatingSettingsCubit>()
                                      .upsertRule(
                                        rule.copyWith(enabled: value),
                                      );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _editRule(context, existing: rule),
                              ),
                              // Ocultar/Deshabilitar eliminación para eventos por defecto
                              Builder(
                                builder: (ctx) {
                                  final isDefault =
                                      PlayerEventRatingSettingsStore.defaultRules()
                                          .any(
                                            (d) =>
                                                d.key.toLowerCase() ==
                                                rule.key.toLowerCase(),
                                          );
                                  if (isDefault) {
                                    return IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: null,
                                      tooltip:
                                          'Evento por defecto (no se puede eliminar)',
                                    );
                                  }
                                  return IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _confirmDelete(context, rule),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PlayerEventRatingRule rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('Se eliminara la regla "${rule.label}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PlayerEventRatingSettingsCubit>().deleteRule(rule.key);
    }
  }

  Future<void> _editRule(
    BuildContext context, {
    PlayerEventRatingRule? existing,
  }) async {
    final keyInitial = existing?.key;
    final labelController = TextEditingController(text: existing?.label ?? '');
    final pointsController = TextEditingController(
      text: existing?.points.toStringAsFixed(2) ?? '0.00',
    );
    var enabled = existing?.enabled ?? true;

    final allEventKeys = MatchEventEnum.values
        .map((e) => canonicalMatchEventTypeKey(e))
        .toList();
    final usedKeys = context
        .read<PlayerEventRatingSettingsCubit>()
        .state
        .rules
        .map((r) => r.key.toLowerCase())
        .toSet();

    final availableKeys = allEventKeys
        .where((k) => keyInitial == k || !usedKeys.contains(k.toLowerCase()))
        .toList();
    var selectedKey =
        keyInitial ??
        (availableKeys.isNotEmpty ? availableKeys.first : allEventKeys.first);

    final saved = await showDialog<PlayerEventRatingRule>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Crear regla' : 'Modificar regla'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedKey,
                      decoration: const InputDecoration(labelText: 'Evento'),
                      items: availableKeys
                          .map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        if (v != null) selectedKey = v;
                      }),
                    ),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Etiqueta'),
                    ),
                    TextField(
                      controller: pointsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Puntuacion',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo'),
                      value: enabled,
                      onChanged: (value) => setState(() => enabled = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    final points = double.tryParse(
                      pointsController.text.trim().replaceAll(',', '.'),
                    );
                    if (selectedKey.isEmpty ||
                        label.isEmpty ||
                        points == null) {
                      return;
                    }
                    Navigator.of(ctx).pop(
                      PlayerEventRatingRule(
                        key: selectedKey,
                        label: label,
                        points: points,
                        enabled: enabled,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != null && context.mounted) {
      await context.read<PlayerEventRatingSettingsCubit>().upsertRule(saved);
    }
  }
}
