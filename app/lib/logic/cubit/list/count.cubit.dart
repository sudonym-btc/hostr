import 'dart:async';

import 'package:hostr/core/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ndk/ndk.dart';

import 'filter.cubit.dart';

class CountCubit<T extends Nip01Event> extends HydratedCubit<CountCubitState> {
  final CustomLogger logger = CustomLogger();
  final Ndk? nostrInstance;
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
    // nostrInstance.requests!.query(filters: filters)
    // nostrInstance.requests.requestNostrEvent(NdkRequest)
    // int count = await getIt<NostrService>().count(getCombinedFilter(
    //     NostrFilter(kinds: kinds), filterCubit?.state.filter));

    emit(CountCubitState(count: 0));
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
