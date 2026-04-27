import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'team_detail_state.dart';

class TeamDetailCubit extends Cubit<TeamDetailState> {
  final GetPlayersByTeamUseCase _getPlayersByTeamUseCase;

  TeamDetailCubit(this._getPlayersByTeamUseCase) : super(TeamDetailInitial());

  /// Último equipo para el que ya tenemos respuesta correcta (éxito).
  int? _lastFetchedTeamId;

  /// Carga la plantilla. Si ya hay datos del mismo [teamId], no emite
  /// [TeamDetailLoading] para no quitar la lista de la UI (recarga en segundo plano).
  Future<void> loadTeam(int teamId) async {
    final silent =
        state is TeamDetailLoaded && _lastFetchedTeamId == teamId;
    if (!silent) {
      emit(TeamDetailLoading());
    }
    final result = await _getPlayersByTeamUseCase(teamId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TeamDetailError(failure.message)),
      (players) {
        _lastFetchedTeamId = teamId;
        emit(TeamDetailLoaded(players));
      },
    );
  }
}
