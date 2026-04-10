import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class GetPlayersByMatchUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayersByMatchUseCase(this._playerRepository);

  Future<Either<Failure, List<Player>>> call(int matchId) {
    return _playerRepository.getPlayerByMatchId(matchId);
  }
}
