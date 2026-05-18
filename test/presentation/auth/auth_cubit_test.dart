import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/sign_up_success.dart';
import 'package:football_manager/domain/repositories/i_auth_repository.dart';
import 'package:football_manager/domain/usecase/auth/get_user_session_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_in_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_out_use_case.dart';
import 'package:football_manager/domain/usecase/auth/sign_up_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFailure extends Failure {
  TestFailure(super.rawMessage);
}

class FakeAuthRepository implements IAuthRepository {
  FakeAuthRepository({
    required this.signInResult,
    required this.signUpResult,
    required this.signOutResult,
    required this.isSignedInResult,
    required this.getAuthenticatedUserResult,
  });

  final Either<Failure, AuthUser> signInResult;
  final Either<Failure, SignUpSuccess> signUpResult;
  final Either<Failure, Unit> signOutResult;
  final Either<Failure, bool> isSignedInResult;
  final Either<Failure, AuthUser?> getAuthenticatedUserResult;

  @override
  Future<Either<Failure, AuthUser>> signIn(
    String email,
    String password,
  ) async {
    return signInResult;
  }

  @override
  Future<Either<Failure, SignUpSuccess>> signUp(
    String email,
    String name,
    String password,
  ) async {
    return signUpResult;
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    return signOutResult;
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    return isSignedInResult;
  }

  @override
  Future<Either<Failure, AuthUser?>> getAuthenticatedUser() async {
    return getAuthenticatedUserResult;
  }
}

AuthUser buildUser() {
  return AuthUser(
    id: 'user-1',
    email: 'player@example.com',
    name: 'Player One',
    teamRoles: {1: UserRole.player},
  );
}

void main() {
  group('AuthCubit', () {
    test(
      'login emits loading and authenticated when credentials are valid',
      () async {
        final user = buildUser();
        final repository = FakeAuthRepository(
          signInResult: right(user),
          signUpResult: right(SignUpSuccess.authenticated(user)),
          signOutResult: right(unit),
          isSignedInResult: right(true),
          getAuthenticatedUserResult: right(user),
        );

        final cubit = AuthCubit(
          signInUseCase: SignInUseCase(repository),
          signUpUseCase: SignUpUseCase(repository),
          signOutUseCase: SignOutUseCase(repository),
          getUserSessionUseCase: GetUserSessionUseCase(repository),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<Authenticated>().having(
              (state) => state.user.email,
              'user email',
              user.email,
            ),
          ]),
        );

        await cubit.login('player@example.com', 'secret123');

        await expectation;

        await cubit.close();
      },
    );

    test(
      'register emits awaiting email verification when confirmation is required',
      () async {
        final repository = FakeAuthRepository(
          signInResult: right(buildUser()),
          signUpResult: right(
            SignUpSuccess.awaitingEmailVerification('new-user@example.com'),
          ),
          signOutResult: right(unit),
          isSignedInResult: right(false),
          getAuthenticatedUserResult: right(null),
        );

        final cubit = AuthCubit(
          signInUseCase: SignInUseCase(repository),
          signUpUseCase: SignUpUseCase(repository),
          signOutUseCase: SignOutUseCase(repository),
          getUserSessionUseCase: GetUserSessionUseCase(repository),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AwaitingEmailVerification>().having(
              (state) => state.email,
              'email',
              'new-user@example.com',
            ),
          ]),
        );

        await cubit.register('new-user@example.com', 'New User', 'secret123');

        await expectation;

        await cubit.close();
      },
    );

    test('logout emits an auth error when repository fails', () async {
      final repository = FakeAuthRepository(
        signInResult: right(buildUser()),
        signUpResult: right(SignUpSuccess.authenticated(buildUser())),
        signOutResult: left(TestFailure('No se pudo cerrar la sesión')),
        isSignedInResult: right(true),
        getAuthenticatedUserResult: right(buildUser()),
      );

      final cubit = AuthCubit(
        signInUseCase: SignInUseCase(repository),
        signUpUseCase: SignUpUseCase(repository),
        signOutUseCase: SignOutUseCase(repository),
        getUserSessionUseCase: GetUserSessionUseCase(repository),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (state) => state.message,
            'message',
            'No se pudo cerrar la sesión',
          ),
        ]),
      );

      await cubit.logout();

      await expectation;

      await cubit.close();
    });
  });
}
