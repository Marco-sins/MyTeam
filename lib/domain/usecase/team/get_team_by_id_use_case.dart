import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class GetTeamByIdUseCase {
  final ITeamRepository _teamRepository;

  GetTeamByIdUseCase(this._teamRepository);

  Future<Either<Failure, Team>> call(int id) {
    return _teamRepository.getTeamById(id);
  }
}
