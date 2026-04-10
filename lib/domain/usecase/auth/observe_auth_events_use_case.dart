import 'package:football_manager/domain/entities/auth_flow_event.dart';
import 'package:football_manager/domain/i_repositories/i_auth_repository.dart';

class ObserveAuthEventsUseCase {
  final IAuthRepository _authRepository;

  ObserveAuthEventsUseCase(this._authRepository);

  Stream<AuthFlowEvent> call() {
    return _authRepository.observeAuthEvents();
  }
}
