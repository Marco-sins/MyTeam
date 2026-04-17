import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetLatestFormationNoteByMatchUseCase {
  GetLatestFormationNoteByMatchUseCase(this._matchEventRepository);

  final IMatchEventRepository _matchEventRepository;

  Future<Either<Failure, String?>> call(int matchId) {
    return _matchEventRepository.getLatestFormationNoteByMatchId(matchId);
  }
}
