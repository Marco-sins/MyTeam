import 'package:equatable/equatable.dart';

abstract class CreateTeamState extends Equatable {
  const CreateTeamState();

  @override
  List<Object?> get props => [];
}

class CreateTeamInitial extends CreateTeamState {}

class CreateTeamLoading extends CreateTeamState {}

class CreateTeamSuccess extends CreateTeamState {}

class CreateTeamError extends CreateTeamState {
  final String message;

  const CreateTeamError(this.message);

  @override
  List<Object?> get props => [message];
}