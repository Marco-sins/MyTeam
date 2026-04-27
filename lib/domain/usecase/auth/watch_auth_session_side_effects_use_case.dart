import 'package:football_manager/domain/entities/auth_session_side_effect.dart';
import 'package:football_manager/domain/repositories/i_auth_repository.dart';

class WatchAuthSessionSideEffectsUseCase {
  WatchAuthSessionSideEffectsUseCase(this._authRepository);

  final IAuthRepository _authRepository;

  Stream<AuthSessionSideEffect> call() {
    return _authRepository.watchSessionSideEffects();
  }
}
