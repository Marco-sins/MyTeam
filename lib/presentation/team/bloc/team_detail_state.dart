import 'package:equatable/equatable.dart';
import 'package:football_manager/domain/entities/player.dart';

abstract class TeamDetailState extends Equatable {
  const TeamDetailState();

  @override
  List<Object?> get props => [];
}

class TeamDetailInitial extends TeamDetailState {}

class TeamDetailLoading extends TeamDetailState {}

class TeamDetailLoaded extends TeamDetailState {
  final List<Player> players;

  const TeamDetailLoaded(this.players);

  @override
  List<Object?> get props => [players];
}

class TeamDetailError extends TeamDetailState {
  final String message;

  const TeamDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
