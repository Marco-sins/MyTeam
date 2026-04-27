import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class FetchRemoteMatchStatusUseCase {
  FetchRemoteMatchStatusUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, MatchStatus?>> call(int matchId) =>
      _repository.getMatchStatus(matchId);
}
