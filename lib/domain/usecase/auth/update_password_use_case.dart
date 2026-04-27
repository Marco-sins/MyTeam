import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/repositories/i_auth_repository.dart';

class UpdatePasswordUseCase {
  UpdatePasswordUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Future<Either<Failure, Unit>> call(String newPassword) {
    return _authRepository.updatePassword(newPassword);
  }
}
