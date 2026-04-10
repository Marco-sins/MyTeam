import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/i_repositories/i_auth_repository.dart';

class UpdatePasswordUseCase {
  final IAuthRepository _authRepository;

  UpdatePasswordUseCase(this._authRepository);

  Future<Either<Failure, Unit>> call(String newPassword) {
    return _authRepository.updatePassword(newPassword);
  }
}
