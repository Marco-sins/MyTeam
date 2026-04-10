import 'package:flutter_bloc/flutter_bloc.dart';

class ConvocationState {
  final Map<int, bool> calledUp;

  const ConvocationState({this.calledUp = const {}});

  ConvocationState copyWith({Map<int, bool>? calledUp}) {
    return ConvocationState(calledUp: calledUp ?? this.calledUp);
  }
}

class ConvocationCubit extends Cubit<ConvocationState> {
  ConvocationCubit() : super(const ConvocationState());

  void toggleCalledUp(int playerId) {
    final current = state.calledUp[playerId] ?? false;
    final updated = Map<int, bool>.from(state.calledUp)..[playerId] = !current;
    emit(state.copyWith(calledUp: updated));
  }

  bool isCalledUp(int playerId) => state.calledUp[playerId] ?? false;

  int calledCountFor(Iterable<int> playerIds) {
    int count = 0;
    for (final id in playerIds) {
      if (state.calledUp[id] == true) count++;
    }
    return count;
  }
}
