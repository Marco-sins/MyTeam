import 'package:flutter_bloc/flutter_bloc.dart';

import 'convocation_state.dart';

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
