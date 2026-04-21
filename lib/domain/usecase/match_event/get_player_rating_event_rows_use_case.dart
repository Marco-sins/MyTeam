import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetPlayerRatingEventRowsUseCase {
  GetPlayerRatingEventRowsUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, List<Map<String, dynamic>>>> call(int matchId) =>
      _repository.getRowsForPlayerRatings(matchId);
}
