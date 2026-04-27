import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/auth_server_exception.dart';
import 'package:football_manager/core/errors/exception/network_exception.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/network_failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/core/errors/failure/unknow_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ejecuta código que puede lanzar (p. ej. datasources) y devuelve siempre
/// [Either]: nunca propaga excepciones al dominio o la UI.
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
