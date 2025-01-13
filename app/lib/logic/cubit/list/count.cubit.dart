import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'filter.cubit.dart';

class CountCubit<T extends NostrEvent> extends HydratedCubit<CountCubitState> {
  final CustomLogger logger = CustomLogger();
  final Nostr? nostrInstance;
  final List<int> kinds;

  final FilterCubit? filterCubit;

  late StreamSubscription? filterSubscription;

  CountCubit({
    this.nostrInstance,
    required this.kinds,
    this.filterCubit,
  }) : super(CountCubitState()) {
    filterSubscription = filterCubit?.stream.listen((filterState) {
      count();
    });
  }

  void count() async {
    logger.i("count");
    emit(CountCubitStateLoading());
    int count = await getIt<NostrSource>().count(getCombinedFilter(
        NostrFilter(kinds: kinds), filterCubit?.state.filter));

    emit(CountCubitState(count: count));
  }

  @override
  Map<String, dynamic>? toJson(CountCubitState state) {
    return {
      'count': state.count,
    };
  }

  @override
  CountCubitState? fromJson(Map<String, dynamic> json) {
    return CountCubitState(
      count: json['count'],
    );
  }

  @override
  Future<void> close() {
    filterSubscription?.cancel();
    return super.close();
  }
}

class CountCubitState {
  final int? count;
  CountCubitState({
    this.count,
  });
}

class CountCubitStateLoading extends CountCubitState {}

class CountCubitStateError extends CountCubitState {
  final String? error;
  CountCubitStateError({
    this.error,
  });
}
