import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class GetPlayerDetails {
  final IPlayerRepository _playerRepository;

  GetPlayerDetails(this._playerRepository);

  Future<Either<Failure, Player>> call(int id) async {
    return await _playerRepository.getPlayerById(id);
  }
}
