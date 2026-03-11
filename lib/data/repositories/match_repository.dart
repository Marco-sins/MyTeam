import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/supabase_exception_handler.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/data/models/match_model.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/match_lineup.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';

class MatchRepository implements IMatchRepository {
  final SupabaseClient _supabase;

  MatchRepository(this._supabase);

  @override
  Future<Either<Failure, Unit>> createMatch(Match match) async {
    try {
      await _supabase.from('matches').insert({
        'team_id': match.teamId,
        'opponent': match.opponent,
        'goals_scored': match.goalsScored,
        'goals_conceded': match.goalsConceded,
        'date': match.date.toIso8601String(),
        'status': match.status
            .toString()
            .split('.')
            .last, // Store enum as string
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
  Future<Either<Failure, Unit>> deleteMatch(int id) async {
    try {
      await _supabase.from('matches').delete().eq('id', id);
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
  Future<Either<Failure, Match>> getMatchById(int id) async {
    try {
      final result = await _supabase
          .from('matches')
          .select()
          .eq('id', id)
          .single();
      Match match = MatchModel.fromJson(result);
      return Right(match);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getMatches() async {
    try {
      final result = await _supabase.from('matches').select();
      List<Match> matches = result.map((e) => MatchModel.fromJson(e)).toList();
      return Right(matches);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getMatchesByTeamId(int teamId) async {
    try {
      final result = await _supabase
          .from('matches')
          .select()
          .eq('team_id', teamId);
      List<Match> matches = result.map((e) => MatchModel.fromJson(e)).toList();
      return Right(matches);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMatch(Match match) async {
    try {
      await _supabase
          .from('matches')
          .update({
            'team_id': match.teamId,
            'opponent': match.opponent,
            'goals_scored': match.goalsScored,
            'goals_conceded': match.goalsConceded,
            'date': match.date.toIso8601String(),
            'status': match.status
                .toString()
                .split('.')
                .last, // Store enum as string
          })
          .eq('id', match.id);
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
  Future<Either<Failure, Unit>> addMatchLineup(MatchLineup lineup) async{
    try {
      await _supabase.from('match_lineups').insert({
        'player_id': lineup.playerId,
        'match_id': lineup.matchId,
        'is_starting': lineup.isStarting,
        'minutes_played': lineup.minutesPlayed,
        'rating': lineup.rating,
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
}
