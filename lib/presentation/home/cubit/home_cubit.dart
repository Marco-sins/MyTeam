import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/usecase/team/get_teams_use_case.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetTeamsUseCase _getTeamsUseCase;

  HomeCubit(this._getTeamsUseCase) : super(HomeInitial());

  /// Si [showLoading] es false y ya hay lista cargada, no se muestra la pantalla
  /// completa de carga (evita parpadeos al refrescar o al volver del segundo plano).
  Future<void> fetchTeams({bool showLoading = false}) async {
    final showFullScreenLoading =
        showLoading || state is! HomeLoaded;
    if (showFullScreenLoading) {
      emit(HomeLoading());
    }
    final result = await _getTeamsUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (teams) => emit(HomeLoaded(teams)),
    );
  }
}
