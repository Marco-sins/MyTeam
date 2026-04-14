import 'package:equatable/equatable.dart';
import 'package:football_manager/domain/entities/auth_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AuthUser user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Registro correcto pero sin sesión hasta confirmar el correo (Supabase).
class AwaitingEmailVerification extends AuthState {
  final String email;

  const AwaitingEmailVerification(this.email);

  @override
  List<Object?> get props => [email];
}

class Unauthenticated extends AuthState {}
