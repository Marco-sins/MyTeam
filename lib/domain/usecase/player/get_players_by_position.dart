import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class GetPlayersByPosition {
  final IPlayerRepository _playerRepository;

  GetPlayersByPosition(this._playerRepository);

  Future<Either<Failure, List<Player>>> call(int teamId, PlayerPosition position) async {
    return await _playerRepository.getPlayersByPosition(teamId, position);
  }
}