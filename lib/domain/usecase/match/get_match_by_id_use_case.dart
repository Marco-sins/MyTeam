import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class GetMatchByIdUseCase {
  GetMatchByIdUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, Match>> call(int id) => _repository.getMatchById(id);
}
