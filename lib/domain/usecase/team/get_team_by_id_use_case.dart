import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

class GetTeamByIdUseCase {
  final ITeamRepository _teamRepository;

  GetTeamByIdUseCase(this._teamRepository);

  Future<Either<Failure, Team>> call(int id) async {
    final response = await _teamRepository.getTeamById(id);
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(
        () => throw ServerException(message: 'Failed to get team by id'),
      ),
    );
  }
}
