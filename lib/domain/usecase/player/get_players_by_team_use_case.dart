import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/exception/server_exception.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class GetPlayersByTeamUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayersByTeamUseCase(this._playerRepository);

  Future<Either<Failure, List<Player>>> call(int teamId) async {
    final response = await _playerRepository.getPlayersByTeam(teamId);
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(
        () => throw ServerException(message: 'Failed to get players by team'),
      ),
    );
  }
}
