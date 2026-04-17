import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';

/// Estado compartido del equipo al navegar (nombre, color, escudo…).
/// Debe proporcionarse por encima de [TeamDetailPage] y pantallas hijas.
class TeamContextCubit extends Cubit<Team> {
  TeamContextCubit(super.initialTeam);

  void setTeam(Team team) => emit(team);
}
