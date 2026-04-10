import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/usecase/team/get_teams_use_case.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetTeamsUseCase _getTeamsUseCase;

  HomeCubit(this._getTeamsUseCase) : super(HomeInitial());

  Future<void> fetchTeams() async {
    emit(HomeLoading());
    final result = await _getTeamsUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (teams) => emit(HomeLoaded(teams)),
    );
  }
}
