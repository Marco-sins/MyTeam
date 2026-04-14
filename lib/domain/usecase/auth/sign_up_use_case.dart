import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/sign_up_success.dart';
import 'package:football_manager/domain/i_repositories/i_auth_repository.dart';

class SignUpUseCase {
  final IAuthRepository _authRepository;

  SignUpUseCase(this._authRepository);

  Future<Either<Failure, SignUpSuccess>> call(
    String email,
    String name,
    String password,
  ) async {
    return await _authRepository.signUp(email, name, password);
  }
}
