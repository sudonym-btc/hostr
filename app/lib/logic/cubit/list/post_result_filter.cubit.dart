import 'package:flutter_bloc/flutter_bloc.dart';

class PostResultFilterCubit<T> extends Cubit<bool Function<T>(T x)> {
  PostResultFilterCubit() : super(<T>(T x) => true);

  void updateFilter(bool Function<T>(T x) newFilter) {
    emit(newFilter);
  }
}
