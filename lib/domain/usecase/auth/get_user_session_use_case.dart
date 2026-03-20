import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/i_repositories/i_auth_repository.dart';

class GetUserSessionUseCase {
  final IAuthRepository _authRepository;

  GetUserSessionUseCase(this._authRepository);

  Future<Either<Failure, AuthUser?>> call() async {
    return await _authRepository.getAuthenticatedUser();
  }
}
