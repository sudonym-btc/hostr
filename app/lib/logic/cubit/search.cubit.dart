import 'dart:async';

import 'package:dart_nostr/nostr/model/request/filter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';

class CustomSearchController
    extends Cubit<CustomSearchControllerState<Listing>> {
  CustomLogger logger = CustomLogger();
  ListCubit listCubit =
      ListCubit<Listing, ListingRepository>(getIt<ListingRepository>());
  late final StreamSubscription listCubitSubscription;

  CustomSearchController()
      : super(
            CustomSearchControllerState(listState: ListCubitState(data: []))) {
    listCubitSubscription = listCubit.stream.listen((listState) {
      emit(state.copyWith(listState: listState as ListCubitState<Listing>));
    });
  }

  bool clientSideFilters(Listing event) {
    return true;
  }

  @override
  Future<void> close() {
    listCubitSubscription.cancel();
    return super.close();
  }

  setDateRange(DateTimeRange? dateRange) {
    emit(state.copyWith(dateRange: dateRange));
  }

  @override
  NostrFilter? filter;

  @override
  list() {
    return listCubit.list();
  }

  @override
  setFilter(NostrFilter filter) {
    // TODO: implement setFilter
    throw UnimplementedError();
  }
}

class CustomSearchControllerState<T> extends Equatable {
  final ListCubitState<T> listState;
  final DateTimeRange? dateRange;

  const CustomSearchControllerState({required this.listState, this.dateRange});

  copyWith({
    ListCubitState<T>? listState,
    DateTimeRange? dateRange,
  }) =>
      CustomSearchControllerState<T>(
          listState: listState ?? this.listState,
          dateRange: dateRange ?? this.dateRange);

  @override
  List<Object?> get props => [listState, dateRange];
}

class Filter {
  late String key;
  dynamic value;
}
