import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

class GetPlayerDetailsUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayerDetailsUseCase(this._playerRepository);

  Future<Either<Failure, Player>> call(int id) {
    return _playerRepository.getPlayerById(id);
  }
}
