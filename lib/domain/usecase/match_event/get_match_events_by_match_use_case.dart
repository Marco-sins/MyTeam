/// Caso de uso para obtener eventos de un partido concreto desde el repositorio
/// (resuelve la conversión a entidades de dominio).
import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetMatchEventsByMatchUseCase {
  final IMatchEventRepository _matchEventRepository;

  GetMatchEventsByMatchUseCase(this._matchEventRepository);

  Future<Either<Failure, List<MatchEvent>>> call(int matchId) {
    return _matchEventRepository.getMatchEventsByMatch(matchId);
  }
}
