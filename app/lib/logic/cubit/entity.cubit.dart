import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:rxdart/rxdart.dart';

class EntityCubit<T, R extends BaseRepository> extends Cubit<EntityCubitState> {
  R repo;
  NostrFilter? filter;
  EntityCubit(this.repo) : super(const EntityCubitState(data: null));

  setFilter(NostrFilter filter) {
    this.filter = filter;
  }

  get() {
    emit(state.copyWith(active: true, data: null));
    repo.list(filter: filter).whereType<Data>().listen((data) {
      emit(state.copyWith(data: data.value, active: false));
    });
  }
}

class EntityCubitState<T> extends Equatable {
  final T data;
  final bool active;

  const EntityCubitState({required this.data, this.active = false});

  EntityCubitState copyWith({
    T? data,
    bool? active,
  }) =>
      EntityCubitState(data: data ?? this.data, active: active ?? this.active);

  @override
  List<Object?> get props => [data, active];
}
