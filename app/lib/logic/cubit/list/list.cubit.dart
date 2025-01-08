import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'filter.cubit.dart';
import 'post_result_filter.cubit.dart';
import 'sort.cubit.dart';

class ListCubit<T extends NostrEvent> extends HydratedCubit<ListCubitState<T>> {
  final Nostr? nostrInstance;
  final int? limit;

  final FilterCubit? filterCubit;
  final SortCubit? sortCubit;
  final PostResultFilterCubit? postResultFilterCubit;

  late StreamSubscription? filterSubscription;
  late StreamSubscription? sortSubscription;
  late StreamSubscription? postResultFilterSubscription;

  ListCubit({
    this.nostrInstance,
    this.limit,
    this.filterCubit,
    this.sortCubit,
    this.postResultFilterCubit,
  }) : super(ListCubitState<T>()) {
    filterSubscription = filterCubit?.stream.listen((filterState) {
      applyFilter(filterState);
    });

    sortSubscription = sortCubit?.stream.listen((sortState) {
      applySort(sortState.comparator);
    });

    postResultFilterSubscription =
        postResultFilterCubit?.stream.listen((postResultFilterState) {
      applyPostResultFilter(postResultFilterState);
    });
  }

  void next() {}

  void sync() {}

  void reset() {
    emit(ListCubitState());
  }

  /// Should be overridden if a child type of list wants to perform subquery on each Item added
  void addItem(T item) {
    emit(state.copyWith(
        results: [...state.results, item],
        resultsRaw: [...state.results, item],
        hasMore: state.hasMore));
  }

  void addItems(List<T> items) {
    emit(state.copyWith(results: [
      ...state.results,
      if (postResultFilterCubit != null)
        ...items.where(postResultFilterCubit!.state)
      else
        ...items,
    ], resultsRaw: [
      ...state.results,
      ...items
    ]));
  }

  void applyFilter(FilterState filter) {
    reset();
    next();
  }

  void applyPostResultFilter(bool Function(T item) postResultFilter) {}

  void applySort(Comparator<T> sortState) {
    emit(ListCubitState(
        results: state.results,
        resultsRaw: state.resultsRaw,
        hasMore: state.hasMore));
  }

  /// Override this function to set own deserialization method
  T deserialize(T item) => item;

  @override
  Map<String, dynamic>? toJson(ListCubitState<T> state) {
    return {
      'results': state.results.map((e) => e.toMap()).toList(),
      'resultsRaw': state.resultsRaw.map((e) => e.toMap()).toList(),
      'hasMore': state.hasMore,
    };
  }

  @override
  ListCubitState<T>? fromJson(Map<String, dynamic> json) {
    return ListCubitState(
      resultsRaw: json['resultsRaw'].map<T>((e) => deserialize(e)).toList(),
      results: json['results'].map<T>((e) => deserialize(e)).toList(),
      hasMore: json['hasMore'] ?? true,
    );
  }

  @override
  Future<void> close() {
    filterSubscription?.cancel();
    sortSubscription?.cancel();
    postResultFilterSubscription?.cancel();
    return super.close();
  }
}

class ListCubitState<T extends NostrEvent> {
  final bool listening;
  final bool synching;
  final bool fetching;
  final List<T> resultsRaw;
  final List<T> results;
  final bool? hasMore;

  ListCubitState({
    this.listening = false,
    this.synching = false,
    this.fetching = false,
    this.resultsRaw = const [],
    this.results = const [],
    this.hasMore,
  });

  ListCubitState<T> copyWith({
    bool? listening,
    bool? synching,
    bool? fetching,
    List<T>? resultsRaw,
    List<T>? results,
    bool? hasMore,
  }) {
    return ListCubitState(
      listening: listening ?? this.listening,
      synching: synching ?? this.synching,
      fetching: fetching ?? this.fetching,
      resultsRaw: resultsRaw ?? this.resultsRaw,
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
