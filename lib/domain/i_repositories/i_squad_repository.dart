import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/squad.dart';

abstract class ISquadRepository {
  Future<Either<Failure, void>> createSquad(Squad squad);
  Future<Either<Failure, List<Squad>>> getSquads();
  Future<Either<Failure, Squad>> getSquadById(int id);
  Future<Either<Failure, void>> updateSquad(Squad squad);
  Future<Either<Failure, void>> deleteSquad(int id);
}