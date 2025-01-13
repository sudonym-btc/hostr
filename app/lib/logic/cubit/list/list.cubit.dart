import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'filter.cubit.dart';
import 'post_result_filter.cubit.dart';
import 'sort.cubit.dart';

class ListCubit<T extends NostrEvent> extends Cubit<ListCubitState<T>> {
  final CustomLogger logger = CustomLogger();
  final Nostr? nostrInstance;
  final int? limit;
  final NostrFilter? filter;
  final List<int> kinds;
  final PublishSubject<T> itemStream = PublishSubject<T>();

  final FilterCubit? filterCubit;
  final SortCubit<T>? sortCubit;
  final PostResultFilterCubit? postResultFilterCubit;

  late StreamSubscription? filterSubscription;
  late StreamSubscription? sortSubscription;
  late StreamSubscription? postResultFilterSubscription;

  ListCubit({
    this.nostrInstance,
    this.limit,
    required this.kinds,
    this.filterCubit,
    this.filter,
    this.sortCubit,
    this.postResultFilterCubit,
  }) : super(ListCubitState<T>()) {
    logger.i("ListCubit: $runtimeType");
    filterSubscription = filterCubit?.stream.listen((filterState) {
      applyFilter(filterState);
    });

    sortSubscription = sortCubit?.stream.listen((sortState) {
      emit(applySort(state, sortState.comparator));
    });

    postResultFilterSubscription =
        postResultFilterCubit?.stream.listen((postResultFilterState) {
      emit(applyPostResultFilter(state, postResultFilterState));
    });
  }

  void next() {
    logger.i("next");
    getIt<NostrSource>()
        .startRequest(
            request: NostrRequest(filters: [
              // Nostr treats separate NostrFilters as OR, so we need to combine them
              getCombinedFilter(
                  getCombinedFilter(NostrFilter(kinds: kinds), filter),
                  filterCubit?.state.filter)
            ]),
            onEose: (_, __) {})
        .stream
        .listen((event) {
      addItem(event as T);
    });
  }

  void sync() {
    next();
  }

  void reset() {
    emit(ListCubitState());
  }

  /// Should be overridden if a child type of list wants to perform subquery on each Item added
  void addItem(T item) {
    if (postResultFilterCubit?.state == null ||
        postResultFilterCubit!.state(item)) {
      itemStream.add(item);
    }
    emit(applySort(
        state.copyWith(
            results: [...state.results, item],
            resultsRaw: [...state.results, item]),
        sortCubit?.state.comparator));
  }

  void applyFilter(FilterState filter) {
    reset();
    next();
  }

  ListCubitState<T> applyPostResultFilter(
      ListCubitState<T> state, bool Function(T item)? postResultFilter) {
    if (postResultFilter == null) return state;
    return state.copyWith(
        results: state.resultsRaw.where(postResultFilter).toList());
  }

  ListCubitState<T> applySort(
      ListCubitState<T> state, Comparator<T>? sortState) {
    if (sortState == null) return state;
    state.results.sort(sortState);
    return state.copyWith(results: state.results);
  }

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
      resultsRaw: json['resultsRaw'].map<T>(NostrEvent.deserialized).toList(),
      results: json['results'].map<T>(NostrEvent.deserialized).toList(),
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

class HydratedListCubit<T extends NostrEvent> extends ListCubit<T> {
  HydratedListCubit({required super.kinds});

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
      resultsRaw: json['resultsRaw'].map<T>(NostrEvent.deserialized).toList(),
      results: json['results'].map<T>(NostrEvent.deserialized).toList(),
      hasMore: json['hasMore'] ?? true,
    );
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
