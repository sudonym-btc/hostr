import 'dart:async';

import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';
import 'package:hostr/injection.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import 'filter.cubit.dart';
import 'post_result_filter.cubit.dart';
import 'sort.cubit.dart';

class ListCubit<T extends Event> extends Cubit<ListCubitState<T>> {
  final CustomLogger logger = CustomLogger();
  final Ndk? nostrInstance;
  final int? limit;
  Filter? filter;
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
    Filter finalFilter = getCombinedFilter(
        getCombinedFilter(Filter(kinds: kinds), filter),
        filterCubit?.state.filter);
    print('listFilter: $finalFilter');
    getIt<NostrService>().startRequest<T>(filters: [
      // Nostr treats separate NostrFilters as OR, so we need to combine them
      finalFilter
    ]).listen((event) {
      addItem(event);
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
      'results': state.results.map((e) => e.nip01Event.toJson()).toList(),
      'resultsRaw': state.resultsRaw.map((e) => e.nip01Event.toJson()).toList(),
      'hasMore': state.hasMore,
    };
  }

  @override
  ListCubitState<T>? fromJson(Map<String, dynamic> json) {
    return ListCubitState(
      resultsRaw: json['resultsRaw'].map<T>(Nip01Event.fromJson).toList(),
      results: json['results'].map<T>(Nip01Event.fromJson).toList(),
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

class HydratedListCubit<T extends Event> extends ListCubit<T> {
  HydratedListCubit({required super.kinds});

  @override
  Map<String, dynamic>? toJson(ListCubitState<T> state) {
    return {
      'results': state.results.map((e) => e.nip01Event.toJson()).toList(),
      'resultsRaw': state.resultsRaw.map((e) => e.nip01Event.toJson()).toList(),
      'hasMore': state.hasMore,
    };
  }

  @override
  ListCubitState<T>? fromJson(Map<String, dynamic> json) {
    return ListCubitState(
      resultsRaw: json['resultsRaw'].map<T>(Nip01Event.fromJson).toList(),
      results: json['results'].map<T>(Nip01Event.fromJson).toList(),
      hasMore: json['hasMore'] ?? true,
    );
  }
}

class ListCubitState<T extends Event> {
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
