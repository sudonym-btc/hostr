import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:rxdart/rxdart.dart';

class ListCubit<T extends Event, R extends BaseRepository<T>>
    extends Cubit<ListCubitState<T>> {
  R repo;
  NostrFilter? filter;
  ListCubit(this.repo) : super(ListCubitState<T>(data: []));

  setFilter(NostrFilter filter) {
    this.filter = filter;
  }

  list() {
    emit(state.copyWith(active: true, data: <T>[]));
    repo.list().whereType<Data<T>>().listen((data) {
      emit(state.copyWith(data: [...state.data, data.value]));
    });
  }
}

class ListCubitState<T> extends Equatable {
  final List<T> data;
  final bool active;

  const ListCubitState({required this.data, this.active = false});

  copyWith({
    List<T>? data,
    bool? active,
  }) =>
      ListCubitState<T>(data: data ?? this.data, active: active ?? this.active);

  @override
  List<Object?> get props => [data, active];
}
