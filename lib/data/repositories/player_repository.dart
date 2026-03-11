import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/supabase_exception_handler.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/player_stats.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class PlayerRepository implements IPlayerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Either<Failure, Unit>> addPlayer(Player player) async{
    try {
      final newPlayer = await _supabase.from('players').insert({ {
        'teamId': player.teamId,
        'firstname': player.firstName,
        'lastname': player.lastName,
        'number': player.number,
        'phone': player.phone,
        'email': player.email,
        'position': player.positions.toString().split('.').last,
      }}).select('id').single();

      final int playerId = newPlayer['id'];

      await _supabase.from('player_stats').insert({
        'playerId': playerId,
        'goals': 0,
        'assists': 0,
        'yellowCards': 0,
        'redCards': 0,
        'matchesPlayed': 0,
      });

      return const Right(unit);

    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlayer(int id) {
    // TODO: implement deletePlayer
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Player>> getPlayerById(int id) {
    // TODO: implement getPlayerById
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByMatchId(int matchId) {
    // TODO: implement getPlayerByMatchId
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByName(int teamId, String name) {
    // TODO: implement getPlayerByName
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayers() {
    // TODO: implement getPlayers
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByNumber(int teamId, int number) {
    // TODO: implement getPlayersByNumber
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByPosition(int teamId, PlayerPosition position) {
    // TODO: implement getPlayersByPosition
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByTeam(int teamId) {
    // TODO: implement getPlayersByTeam
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> updatePlayer(Player player) {
    // TODO: implement updatePlayer
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> updatePlayerStats(PlayerStats playerStats) {
    // TODO: implement updatePlayerStats
    throw UnimplementedError();
  }
  
}