import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ndk/ndk.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(FilterState());

  void updateFilter(Filter newFilter, {String? location}) {
    emit(state.copyWith(filter: newFilter, location: location));
  }

  void updateLocation(String location) {
    emit(state.copyWith(location: location));
  }

  void clear() {
    emit(FilterState());
  }
}

class FilterState {
  final Filter? filter;
  final String location;

  FilterState({this.filter, this.location = ''});

  FilterState copyWith({Filter? filter, String? location}) {
    return FilterState(
      filter: filter ?? this.filter,
      location: location ?? this.location,
    );
  }
}
