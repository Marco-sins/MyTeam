import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/i_repositories/i_auth_repository.dart';

class SignOutUseCase {
  final IAuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  Future<Either<Failure, Unit>> call() async {
    return await _authRepository.signOut();
  }
}