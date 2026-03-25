import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  // Función para cargar equipos
  Future<void> fetchTeams() async {
    emit(HomeLoading());
    try {
      // AQUÍ IRÍA TU LLAMADA A SUPABASE:
      // final teams = await repository.getTeams();
      
      await Future.delayed(const Duration(seconds: 1)); // Simulación
      final List<Team> mockTeams = []; // Cambia a [Team(...)] para probar la lista
      
      emit(HomeLoaded(mockTeams));
    } catch (e) {
      emit(HomeError("No se pudieron cargar los equipos"));
    }
  }
}