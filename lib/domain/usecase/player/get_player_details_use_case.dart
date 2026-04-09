import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class GetPlayerDetailsUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayerDetailsUseCase(this._playerRepository);

  Future<Either<Failure, Player>> call(int id) async {
    final response = await _playerRepository.getPlayerById(id);
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(
        () => throw ServerException(message: 'Failed to get player details'),
      ),
    );
  }
}
