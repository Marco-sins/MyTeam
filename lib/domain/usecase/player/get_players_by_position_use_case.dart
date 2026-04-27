import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

class GetPlayersByPositionUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayersByPositionUseCase(this._playerRepository);

  Future<Either<Failure, List<Player>>> call(
    int teamId,
    PlayerPosition position,
  ) {
    return _playerRepository.getPlayersByPosition(teamId, position);
  }
}
