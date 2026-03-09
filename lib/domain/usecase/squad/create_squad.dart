import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/squad.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';
import 'package:tfg1/domain/i_repositories/i_squad_repository.dart';

class CreateSquad {
  final ISquadRepository _squadRepository;
  final IMatchRepository _matchRepository;

  CreateSquad(this._squadRepository, this._matchRepository);

  Future<Either<Failure, void>> call(Squad squad, Match match) async {
    Either<Failure, void> result = await _squadRepository.createSquad(squad);
    if (result.isLeft()) {
      return result;
    }
    return _matchRepository.createMatch(match);
  }
}