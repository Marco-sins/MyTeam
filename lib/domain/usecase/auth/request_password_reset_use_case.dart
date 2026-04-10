import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/i_repositories/i_auth_repository.dart';

class RequestPasswordResetUseCase {
  final IAuthRepository _authRepository;

  RequestPasswordResetUseCase(this._authRepository);

  Future<Either<Failure, Unit>> call(String email, {String? redirectTo}) {
    return _authRepository.requestPasswordReset(email, redirectTo: redirectTo);
  }
}
