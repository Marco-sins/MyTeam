import 'package:football_manager/data/mappers/player_stats_mapper.dart';

/// Mapeador entre `PlayerModel` y la entidad de dominio `Player`.
import 'package:football_manager/data/models/player_model.dart';
import 'package:football_manager/data/models/player_stats_model.dart';
import 'package:football_manager/domain/entities/player.dart';

class PlayerMapper {
  static PlayerModel toModel(Player player) {
    return PlayerModel(
      id: player.id,
      teamId: player.teamId,
      firstName: player.firstName,
      lastName: player.lastName,
      number: player.number,
      phone: player.phone,
      email: player.email,
      imgUrl: player.imgUrl,
      positions: player.positions,
      stats: player.stats != null
          ? PlayerStatsMapper.toModel(player.stats!)
          : null,
    );
  }

  static Player toEntity(PlayerModel playerModel) {
    return Player(
      id: playerModel.id,
      teamId: playerModel.teamId,
      firstName: playerModel.firstName,
      lastName: playerModel.lastName,
      number: playerModel.number,
      phone: playerModel.phone,
      email: playerModel.email,
      imgUrl: playerModel.imgUrl,
      positions: playerModel.positions,
      stats: playerModel.stats != null
          ? PlayerStatsMapper.toEntity(playerModel.stats! as PlayerStatsModel)
          : null,
    );
  }
}
