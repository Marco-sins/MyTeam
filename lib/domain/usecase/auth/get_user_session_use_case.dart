import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/repositories/i_auth_repository.dart';

class GetUserSessionUseCase {
  final IAuthRepository _authRepository;

  GetUserSessionUseCase(this._authRepository);

  Future<Either<Failure, AuthUser?>> call() async {
    return await _authRepository.getAuthenticatedUser();
  }
}
