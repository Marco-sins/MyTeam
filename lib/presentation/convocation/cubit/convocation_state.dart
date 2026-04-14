class ConvocationState {
  final Map<int, bool> calledUp;

  const ConvocationState({this.calledUp = const {}});

  ConvocationState copyWith({Map<int, bool>? calledUp}) {
    return ConvocationState(calledUp: calledUp ?? this.calledUp);
  }
}
