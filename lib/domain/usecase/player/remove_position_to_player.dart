import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class RemovePositionToPlayer {
  final IPlayerRepository _playerRepository;

  RemovePositionToPlayer(this._playerRepository);

  Future<Either<Failure, void>> call(Player player, PlayerPosition position) {
    List<PlayerPosition> updatedPositions = [];
    if (player.positions != null) {
      updatedPositions.addAll(player.positions!);
    }
    updatedPositions.remove(position);
    Player updatedPlayer = Player(
      id: player.id,
      teamId: player.teamId,
      firstName: player.firstName,
      lastName: player.lastName,
      number: player.number,
      phone: player.phone,
      email: player.email,
      positions: updatedPositions,
      statistics: player.statistics,
    );
    return _playerRepository.updatePlayer(updatedPlayer);
  }
}