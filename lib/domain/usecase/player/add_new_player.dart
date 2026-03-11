import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class AddNewPlayer {
  final IPlayerRepository _playerRepository;

  AddNewPlayer(this._playerRepository);

  Future<Either<Failure, void>> call(Player player) async {
    return await _playerRepository.addPlayer(player);
  }
}
