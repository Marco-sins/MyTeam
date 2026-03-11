import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/supabase_exception_handler.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/data/models/match_event_model.dart';
import 'package:tfg1/domain/entities/match_event.dart';
import 'package:tfg1/domain/i_repositories/i_match_event_repository.dart';

class MatchEventRepository implements IMatchEventRepository {
  final SupabaseClient _supabase;

  MatchEventRepository(this._supabase);

  @override
  Future<Either<Failure, Unit>> deleteMatchEvent(int id) async {
    try {
      await _supabase.from('match_events').delete().eq('id', id);
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
  Future<Either<Failure, List<MatchEvent>>> getMatchEventsByMatch(
    int matchId,
  ) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select()
          .eq('match_id', matchId);
      List<MatchEventModel> events = result
          .map((e) => MatchEventModel.fromJson(e))
          .toList();
      return Right(events);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveMatchEvent(MatchEvent matchEvent) async {
    try {
      await _supabase.from('match_events').insert({
        'match_id': matchEvent.matchId,
        'player_id1': matchEvent.playerId1,
        'player_id2': matchEvent.playerId2,
        'minute': matchEvent.minute,
        'type': matchEvent.type,
        'note': matchEvent.note,
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
  Future<Either<Failure, Unit>> updateMatchEvent(MatchEvent matchEvent) async {
    try {
      await _supabase
          .from('match_events')
          .update({
            'match_id': matchEvent.matchId,
            'player_id1': matchEvent.playerId1,
            'player_id2': matchEvent.playerId2,
            'minute': matchEvent.minute,
            'type': matchEvent.type,
            'note': matchEvent.note,
          })
          .eq('id', matchEvent.id);
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
