import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/match_event.dart';
import 'package:tfg1/domain/i_repositories/i_match_event_repository.dart';

class UpdateMatchEvent {
  final IMatchEventRepository _matchEventRepository;

  UpdateMatchEvent(this._matchEventRepository);

  Future<Either<Failure, void>> call(MatchEvent matchEvent) async {
    return await _matchEventRepository.updateMatchEvent(matchEvent);
  }
}