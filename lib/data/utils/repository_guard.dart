import 'package:dartz/dartz.dart';
import 'package:football_manager/data/errors/auth_server_exception.dart';
import 'package:football_manager/data/errors/network_exception.dart';
import 'package:football_manager/data/errors/server_exception.dart';
import 'package:football_manager/data/errors/unknow_exception.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/failures/network_failure.dart';
import 'package:football_manager/domain/failures/server_failure.dart';
import 'package:football_manager/domain/failures/unknow_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mapea excepciones de la capa de datos a [Failure] (dominio) sin filtrarlas a la UI.
Future<Either<Failure, T>> runRepositoryGuard<T>(
  Future<T> Function() body,
) async {
  try {
    return Right(await body());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on AuthServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on UnknowException catch (e) {
    return Left(UnknowFailure(e.message));
  } on PostgrestException catch (e) {
    return Left(ServerFailure(e.message));
  } catch (e) {
    return Left(UnknowFailure(e));
  }
}
