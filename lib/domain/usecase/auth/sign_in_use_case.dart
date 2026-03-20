import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/i_repositories/i_auth_repository.dart';

class SignInUseCase {
  final IAuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  Future<Either<Failure, AuthUser>> call(String email, String password) async {
    return await _authRepository.signIn(email, password);
  }
}