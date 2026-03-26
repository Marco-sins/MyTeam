import 'package:bloc/bloc.dart';
import 'package:tfg1/domain/usecase/auth/get_user_session_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_in_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_up_use_case.dart';
import 'package:tfg1/domain/usecase/auth/sign_out_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';

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

  Future<void> login(String username, String password) async {
    // Implement login logic here
    emit(AuthLoading());
    // Simulate a successful login after a delay
    final result = await signInUseCase(username, password);
    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await signOutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (_) => emit(AuthInitial()),
    );
  }

  Future<void> register(String email, String username, String password) async {
    // Implement registration logic here
    emit(AuthLoading());
    // Simulate a successful registration after a delay
    final result = await signUpUseCase(
      email,
      username,
      password,
    ); // You should replace this with a proper registration use case
    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (user) => emit(Authenticated(user: user)),
    );
  }
}
