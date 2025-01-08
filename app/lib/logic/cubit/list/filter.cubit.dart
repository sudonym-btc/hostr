import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(FilterState());

  void updateFilter(NostrFilter newFilter) {
    emit(FilterState(newFilter));
  }
}

class FilterState {
  final NostrFilter filter;

  FilterState([this.filter = const NostrFilter()]);
}
