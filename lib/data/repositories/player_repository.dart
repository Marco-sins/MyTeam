import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/supabase_exception_handler.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/data/models/player_model.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/player_stats.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class PlayerRepository implements IPlayerRepository {
  final SupabaseClient _supabase;

  PlayerRepository(this._supabase);

  @override
  Future<Either<Failure, Unit>> addPlayer(Player player) async {
    try {
      final newPlayer = await _supabase
          .from('players')
          .insert({
            {
              'team_id': player.teamId,
              'firstname': player.firstName,
              'lastname': player.lastName,
              'number': player.number,
              'phone': player.phone,
              'email': player.email,
              'position': player.positions.toString().split('.').last,
            },
          })
          .select('id')
          .single();

      final int playerId = newPlayer['id'];

      await _supabase.from('player_stats').insert({
        'player_id': playerId,
        'goals': 0,
        'assists': 0,
        'yellow_cards': 0,
        'red_cards': 0,
        'matches_played': 0,
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
  Future<Either<Failure, Unit>> deletePlayer(int id) async {
    try {
      await _supabase.from('players').delete().eq('id', id);
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
  Future<Either<Failure, Player>> getPlayerById(int id) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('id', id)
          .single();
      PlayerModel player = PlayerModel.fromJson(result);
      return Right(player);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByMatchId(int matchId) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('match_id', matchId);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return Right(players);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByName(
    int teamId,
    String name,
  ) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .ilike('firstname', '%$name%');
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return Right(players);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayers() async {
    try {
      final result = await _supabase.from('players').select();
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return Right(players);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByNumber(
    int teamId,
    int number,
  ) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .eq('number', number);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return Right(players);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByPosition(
    int teamId,
    PlayerPosition position,
  ) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .eq('position', position.toString().split('.').last);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return Right(players);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByTeam(int teamId) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return Right(players);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePlayer(Player player) async {
    try {
      await _supabase
          .from('players')
          .update({
            'team_id': player.teamId,
            'firstname': player.firstName,
            'lastname': player.lastName,
            'number': player.number,
            'phone': player.phone,
            'email': player.email,
            'position': player.positions.toString().split('.').last,
          })
          .eq('id', player.id);
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
  Future<Either<Failure, Unit>> updatePlayerStats(
    int playerId,
    PlayerStats playerStats,
  ) async {
    try {
      await _supabase
          .from('player_stats')
          .update({
            'goals': playerStats.goals,
            'assists': playerStats.assists,
            'yellow_cards': playerStats.yellowCards,
            'red_cards': playerStats.redCards,
            'matches_played': playerStats.matchesPlayed,
          })
          .eq('player_id', playerId);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
