import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import 'filter.cubit.dart';
import 'post_result_filter.cubit.dart';
import 'sort.cubit.dart';

class ListCubit<T extends Nip01Event> extends Cubit<ListCubitState<T>> {
  final CustomLogger logger = CustomLogger();
  final Ndk? nostrInstance;
  final int? limit;
  Filter? filter;
  final List<int> kinds;
  final PublishSubject<T> itemStream = PublishSubject<T>();
  final Hostr nostrService;

  final FilterCubit? filterCubit;
  final SortCubit<T>? sortCubit;
  final PostResultFilterCubit? postResultFilterCubit;

  late StreamSubscription? filterSubscription;
  late StreamSubscription? sortSubscription;
  late StreamSubscription? postResultFilterSubscription;
  StreamSubscription<T>? nostrSubscription;
  StreamSubscription<T>? requestSubscription;
  StreamWithStatus<T>? _nostrResponse;

  ListCubit({
    this.nostrInstance,
    this.limit,
    required this.kinds,
    required this.nostrService,
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

    postResultFilterSubscription = postResultFilterCubit?.stream.listen((
      postResultFilterState,
    ) {
      emit(applyPostResultFilter(state, postResultFilterState.filter));
    });
  }

  /// Nostr treats separate NostrFilters as OR, so we need to combine them
  ///
  /// For pagination we move backwards in time with `until`.
  Filter getPaginationFilter() {
    final oldestTimestamp = state.results.isNotEmpty
        ? state.results.map((e) => e.createdAt).reduce((a, b) => a < b ? a : b)
        : null;
    return getCombinedFilter(
      getCombinedFilter(
        Filter(
          kinds: kinds,
          until: oldestTimestamp == null ? null : oldestTimestamp - 1,
          limit: limit,
        ),
        filter,
      ),
      filterCubit?.state.filter,
    );
  }

  /// Filter for live sync/new events subscription.
  Filter getSyncFilter() {
    final newestTimestamp = state.results.isNotEmpty
        ? state.results.map((e) => e.createdAt).reduce((a, b) => a > b ? a : b)
        : null;
    return getCombinedFilter(
      getCombinedFilter(
        Filter(kinds: kinds, since: newestTimestamp, limit: limit),
        filter,
      ),
      filterCubit?.state.filter,
    );
  }

  Future<void> next() async {
    if (state.fetching || state.hasMore == false) return;
    emit(state.copyWith(fetching: true, clearError: true));

    logger.i("next");
    Filter finalFilter = getPaginationFilter();
    logger.t('listFilter: $finalFilter');
    var fetchedCount = 0;
    try {
      await requestSubscription?.cancel();
      requestSubscription = nostrService.requests
          .query<T>(filter: finalFilter)
          .listen((event) {
            fetchedCount++;
            if (state.results.map((e) => e.id).contains(event.id)) {
              return;
            }
            addItem(event);
          });
      await requestSubscription?.asFuture();
    } catch (e, st) {
      logger.e('Error fetching next page for $runtimeType: $e\n$st');
      if (!isClosed) {
        emit(state.copyWith(fetching: false, error: e));
      }
      return;
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            fetching: false,
            hasMore: limit == null ? state.hasMore : fetchedCount >= limit!,
          ),
        );
      }
    }
  }

  Future<void> sync() async {
    await nostrSubscription?.cancel();
    _nostrResponse?.close();
    _nostrResponse = null;
    emit(state.copyWith(synching: true));
    logger.i("sync");
    await next();
    emit(state.copyWith(synching: false));
    Filter finalFilter = getSyncFilter();
    logger.t('listFilter: $finalFilter');
    _nostrResponse = nostrService.requests.subscribe<T>(filter: finalFilter);
    nostrSubscription = _nostrResponse!.stream.listen(
      (event) {
        addItem(event);
      },
      onError: (Object e, StackTrace st) {
        logger.e('Sync stream error for $runtimeType: $e\n$st');
        if (!isClosed) {
          emit(state.copyWith(error: e));
        }
      },
    );
  }

  void reset() {
    emit(ListCubitState());
  }

  /// Should be overridden if a child type of list wants to perform subquery on each Item added
  void addItem(T item) {
    if (isClosed || itemStream.isClosed) return;
    if (postResultFilterCubit?.state == null ||
        postResultFilterCubit!.state.filter(item)) {
      itemStream.add(item);
    }
    emit(
      applySort(
        state.copyWith(
          results: [...state.results, item],
          resultsRaw: [...state.results, item],
        ),
        sortCubit?.state.comparator,
      ),
    );
  }

  void applyFilter(FilterState filter) {
    nostrSubscription?.cancel();
    _nostrResponse?.close();
    _nostrResponse = null;
    requestSubscription?.cancel();
    reset();
    next();
  }

  ListCubitState<T> applyPostResultFilter(
    ListCubitState<T> state,
    bool Function(T item)? postResultFilter,
  ) {
    if (postResultFilter == null) return state;
    return state.copyWith(
      results: state.resultsRaw.where(postResultFilter).toList(),
    );
  }

  ListCubitState<T> applySort(
    ListCubitState<T> state,
    Comparator<T>? sortState,
  ) {
    if (sortState == null) return state;
    state.results.sort(sortState);
    return state.copyWith(results: state.results);
  }

  Map<String, dynamic>? toJson(ListCubitState<T> state) {
    return {
      'results': state.results.map((e) => e.toString()).toList(),
      'resultsRaw': state.resultsRaw.map((e) => e.toString()).toList(),
      'hasMore': state.hasMore,
    };
  }

  ListCubitState<T>? fromJson(Map<String, dynamic> json) {
    return ListCubitState(
      resultsRaw: json['resultsRaw'].map<T>(Nip01EventModel.fromJson).toList(),
      results: json['results'].map<T>(Nip01EventModel.fromJson).toList(),
      hasMore: json['hasMore'] ?? true,
    );
  }

  @override
  Future<void> close() async {
    await nostrSubscription?.cancel();
    await requestSubscription?.cancel();
    _nostrResponse?.close();
    _nostrResponse = null;
    filterSubscription?.cancel();
    sortSubscription?.cancel();
    postResultFilterSubscription?.cancel();
    await itemStream.close();
    return super.close();
  }
}

class HydratedListCubit<T extends Nip01Event> extends ListCubit<T> {
  HydratedListCubit({required super.kinds, required super.nostrService});

  @override
  Map<String, dynamic>? toJson(ListCubitState<T> state) {
    return {
      'results': state.results.map((e) => e.toString()).toList(),
      'resultsRaw': state.resultsRaw.map((e) => e.toString()).toList(),
      'hasMore': state.hasMore,
    };
  }

  @override
  ListCubitState<T>? fromJson(Map<String, dynamic> json) {
    return ListCubitState(
      resultsRaw: json['resultsRaw'].map<T>(Nip01EventModel.fromJson).toList(),
      results: json['results'].map<T>(Nip01EventModel.fromJson).toList(),
      hasMore: json['hasMore'] ?? true,
    );
  }
}

class ListCubitState<T extends Nip01Event> {
  final bool listening;
  final bool synching;
  final bool fetching;
  final List<T> resultsRaw;
  final List<T> results;
  final bool? hasMore;
  final Object? error;

  ListCubitState({
    this.listening = false,
    this.synching = false,
    this.fetching = false,
    this.resultsRaw = const [],
    this.results = const [],
    this.hasMore,
    this.error,
  });

  bool get hasError => error != null;

  ListCubitState<T> copyWith({
    bool? listening,
    bool? synching,
    bool? fetching,
    List<T>? resultsRaw,
    List<T>? results,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ListCubitState(
      listening: listening ?? this.listening,
      synching: synching ?? this.synching,
      fetching: fetching ?? this.fetching,
      resultsRaw: resultsRaw ?? this.resultsRaw,
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
