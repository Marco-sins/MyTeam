import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetLatestMatchEventByDbTypeUseCase {
  GetLatestMatchEventByDbTypeUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, MatchEvent?>> call({
    required int matchId,
    required String typeDbValue,
  }) =>
      _repository.getLatestEventByTypeString(
        matchId: matchId,
        typeDbValue: typeDbValue,
      );
}
