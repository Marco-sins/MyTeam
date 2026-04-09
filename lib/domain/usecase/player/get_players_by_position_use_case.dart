import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class GetPlayersByPositionUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayersByPositionUseCase(this._playerRepository);

  Future<Either<Failure, List<Player>>> call(
    int teamId,
    PlayerPosition position,
  ) async {
    final response = await _playerRepository.getPlayersByPosition(
      teamId,
      position,
    );
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(
        () =>
            throw ServerException(message: 'Failed to get players by position'),
      ),
    );
  }
}
