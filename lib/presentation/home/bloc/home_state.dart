import 'package:equatable/equatable.dart';
import 'package:football_manager/domain/entities/team.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Team> teams; 
  const HomeLoaded(this.teams);
  @override
  List<Object?> get props => [teams];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}