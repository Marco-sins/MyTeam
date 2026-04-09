import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'team_detail_state.dart';

class TeamDetailCubit extends Cubit<TeamDetailState> {
  final GetPlayersByTeamUseCase _getPlayersByTeamUseCase;

  TeamDetailCubit(this._getPlayersByTeamUseCase) : super(TeamDetailInitial());

  Future<void> loadTeam(int teamId) async {
    emit(TeamDetailLoading());
    final result = await _getPlayersByTeamUseCase(teamId);
    result.fold(
      (failure) => emit(TeamDetailError(failure.message)),
      (players) => emit(TeamDetailLoaded(players)),
    );
  }
}
