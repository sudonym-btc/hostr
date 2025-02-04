import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ndk/ndk.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(FilterState());

  void updateFilter(Filter newFilter) {
    emit(FilterState(newFilter));
  }
}

class FilterState {
  final Filter? filter;

  FilterState([this.filter]);
}
