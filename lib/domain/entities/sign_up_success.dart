import 'package:football_manager/domain/entities/auth_user.dart';

/// Resultado de [signUp]: sesión activa o pendiente de verificar correo.
class SignUpSuccess {
  const SignUpSuccess._({
    required this.email,
    required this.awaitingEmailConfirmation,
    this.user,
  });

  final String email;
  final bool awaitingEmailConfirmation;
  final AuthUser? user;

  factory SignUpSuccess.authenticated(AuthUser user) {
    return SignUpSuccess._(
      email: user.email,
      awaitingEmailConfirmation: false,
      user: user,
    );
  }

  factory SignUpSuccess.awaitingEmailVerification(String email) {
    return SignUpSuccess._(
      email: email,
      awaitingEmailConfirmation: true,
      user: null,
    );
  }
}
