import 'package:tfg1/data/mappers/player_stats_mapper.dart';
import 'package:tfg1/data/models/player_model.dart';
import 'package:tfg1/data/models/player_stats_model.dart';
import 'package:tfg1/domain/entities/player.dart';

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
      positions: playerModel.positions,
      stats: playerModel.stats != null 
          ? PlayerStatsMapper.toEntity(playerModel.stats! as PlayerStatsModel) 
          : null,
    );
  }
}