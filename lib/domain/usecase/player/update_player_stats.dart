import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player_statitics.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class UpdatePlayerStatitics {
  final IPlayerRepository _playerRepository;

  UpdatePlayerStatitics(this._playerRepository);

  Future<Either<Failure, void>> call(PlayerStats playerStats) async {
    return await _playerRepository.updatePlayerStats(playerStats);
  }
}