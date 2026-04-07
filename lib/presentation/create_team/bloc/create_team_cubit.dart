import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/team/create_team_use_case.dart';
import 'create_team_state.dart';

class CreateTeamCubit extends Cubit<CreateTeamState> {
  final CreateTeamUseCase createTeamUseCase;

  CreateTeamCubit(this.createTeamUseCase) : super(CreateTeamInitial());

  Future<void> createTeam(
    String teamName,
    String category, [
    String? logoUrl,
  ]) async {
    emit(CreateTeamLoading());
    final result = await createTeamUseCase(
      Team(name: teamName, category: category, logoUrl: logoUrl),
    );

    result.fold(
      (failure) => emit(CreateTeamError(failure.message)),
      (_) => emit(CreateTeamSuccess()),
    );
  }
}
