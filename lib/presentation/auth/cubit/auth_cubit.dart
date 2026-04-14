import 'package:bloc/bloc.dart';
import 'package:football_manager/domain/usecase/auth/get_user_session_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_in_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_up_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_out_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetUserSessionUseCase getUserSessionUseCase;

  AuthCubit({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getUserSessionUseCase,
  }) : super(AuthInitial());

  Future<void> checkUserSession() async {
    emit(AuthLoading());
    final result = await getUserSessionUseCase();
    result.fold((failure) => emit(AuthInitial()), (user) {
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(AuthInitial());
      }
    });
  }

  /// Vuelve a cargar el usuario (p. ej. `team_members` / roles) sin pasar por [AuthLoading].
  /// Util tras aceptar una invitación o cambios de membresía manteniendo la sesión.
  Future<void> refreshAuthenticatedUser() async {
    final result = await getUserSessionUseCase();
    result.fold((_) {}, (user) {
      if (user != null) {
        emit(Authenticated(user: user));
      }
    });
  }

  Future<void> login(String username, String password) async {
    // Implement login logic here
    emit(AuthLoading());
    // Simulate a successful login after a delay
    final result = await signInUseCase(username, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await signOutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthInitial()),
    );
  }

  Future<void> register(String email, String username, String password) async {
    emit(AuthLoading());
    final result = await signUpUseCase(
      email,
      username,
      password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (success) {
        if (success.awaitingEmailConfirmation) {
          emit(AwaitingEmailVerification(success.email));
        } else {
          emit(Authenticated(user: success.user!));
        }
      },
    );
  }

  void resetToLogin() => emit(AuthInitial());
}
