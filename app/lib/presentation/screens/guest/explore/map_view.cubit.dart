import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

class MapViewCubit extends Cubit<int> {
  MapViewCubit() : super(1);

  void scrollUp() {
    int x = state;
    emit(min(x++, 2));
  }

  void scrollDown() {
    int x = state;
    emit(max(x--, 0));
  }
}
