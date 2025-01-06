import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

class EntityCubit<T, R extends BaseRepository> extends Cubit<EntityCubitState> {
  R repo = getIt<R>();
  NostrFilter? filter;
  EntityCubit() : super(const EntityCubitState(data: null));

  setFilter(NostrFilter filter) {
    this.filter = filter;
  }

  get() async {
    emit(state.copyWith(active: true, data: null));
    var item = await repo.get(filter: filter);
    emit(state.copyWith(data: item, active: false));
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
