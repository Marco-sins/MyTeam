part of 'player_event_rating_settings_cubit.dart';

class PlayerEventRatingSettingsState extends Equatable {
  const PlayerEventRatingSettingsState({
    required this.rules,
    required this.isLoading,
    required this.error,
  });

  const PlayerEventRatingSettingsState.initial()
    : rules = const [],
      isLoading = false,
      error = null;

  final List<PlayerEventRatingRule> rules;
  final bool isLoading;
  final String? error;

  PlayerEventRatingSettingsState copyWith({
    List<PlayerEventRatingRule>? rules,
    bool? isLoading,
    String? error,
  }) {
    return PlayerEventRatingSettingsState(
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [rules, isLoading, error];
}
