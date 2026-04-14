import 'package:equatable/equatable.dart';

abstract class CreatePlayerState extends Equatable {
  const CreatePlayerState();

  @override
  List<Object?> get props => [];
}

class CreatePlayerInitial extends CreatePlayerState {}

class CreatePlayerLoading extends CreatePlayerState {}

class CreatePlayerSuccess extends CreatePlayerState {}

class CreatePlayerError extends CreatePlayerState {
  final String message;

  const CreatePlayerError(this.message);

  @override
  List<Object?> get props => [message];
}
