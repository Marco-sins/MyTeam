import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'create_player_state.dart';

class CreatePlayerCubit extends Cubit<CreatePlayerState> {
  final AddNewPlayerUseCase addNewPlayerUseCase;
  final AuthUser currentUser;

  CreatePlayerCubit(this.addNewPlayerUseCase, this.currentUser)
    : super(CreatePlayerInitial());

  Future<void> createPlayer({
    required int teamId,
    required String firstName,
    String? lastName,
    int? number,
    String? phone,
    String? email,
    List<PlayerPosition>? positions,
  }) async {
    emit(CreatePlayerLoading());
    final player = Player(
      teamId: teamId,
      firstName: firstName,
      lastName: lastName,
      number: number,
      phone: phone,
      email: email,
      positions: positions,
    );
    final result = await addNewPlayerUseCase(player, currentUser);
    result.fold(
      (failure) => emit(CreatePlayerError(failure.message)),
      (_) => emit(CreatePlayerSuccess()),
    );
  }
}
