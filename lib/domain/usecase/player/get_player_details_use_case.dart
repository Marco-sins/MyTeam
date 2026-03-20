import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class GetPlayerDetailsUseCase {
  final IPlayerRepository _playerRepository;

  GetPlayerDetailsUseCase(this._playerRepository);

  Future<Either<Failure, Player>> call(int id) async {
    final response = await _playerRepository.getPlayerById(id);
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(() => throw Exception('Failed to get player details')),
    );
  }
}
