import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/supabase_exception_handler.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/data/models/team_model.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/i_repositories/i_team_repository.dart';

class TeamRepository implements ITeamRepository {
  final SupabaseClient _supabase;

  TeamRepository(this._supabase);

  @override
  Future<Either<Failure, Unit>> addTeam(Team team) async {
    try {
      await _supabase.from('teams').insert({
        'name': team.name,
        'category': team.category,
        'logo_url': team.logoUrl,
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
  Future<Either<Failure, Unit>> deleteTeam(int id) async {
    try {
      await _supabase.from('teams').delete().eq('id', id);
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
  Future<Either<Failure, Team>> getTeamById(int id) async {
    try {
      final result = await _supabase
          .from('teams')
          .select()
          .eq('id', id)
          .single();
      TeamModel team = TeamModel.fromJson(result);
      return Right(team);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Team>>> getTeams() async {
    try {
      final result = await _supabase.from('teams').select();
      List<TeamModel> teams = result.map((e) => TeamModel.fromJson(e)).toList();
      return Right(teams);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTeam(Team team) async {
    try {
      await _supabase
          .from('teams')
          .update({
            'name': team.name,
            'category': team.category,
            'logo_url': team.logoUrl,
          })
          .eq('id', team.id);
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
