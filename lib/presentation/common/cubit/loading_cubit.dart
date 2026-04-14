import 'package:flutter_bloc/flutter_bloc.dart';

class LoadingCubit extends Cubit<bool> {
  LoadingCubit() : super(false);

  void start() => emit(true);
  void stop() => emit(false);
}
