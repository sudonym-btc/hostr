import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

class EntityCubit<T extends NostrEvent> extends Cubit<EntityCubitState<T>> {
  NostrProvider nostr = getIt<NostrProvider>();
  final NostrFilter? filter;

  EntityCubit({required this.filter})
      : super(const EntityCubitState(data: null));

  get() async {
    emit(state.copyWith(active: true));
    try {
      T result = await nostr
          .startRequestAsync(
              request: NostrRequest(
                  filters: [getCombinedFilter(filter, NostrFilter(limit: 1))]))
          .then((items) => items.first as T);

      print('result $result');

      emit(EntityCubitState(data: result, active: false));
    } catch (e) {
      emit(state.copyWith(active: false));
    }
    print('done');
  }
}

class EntityCubitState<T extends NostrEvent> extends Equatable {
  final T? data;
  final bool active;

  const EntityCubitState({required this.data, this.active = false});

  EntityCubitState<T> copyWith({
    T? data,
    bool? active,
  }) =>
      EntityCubitState(data: data ?? this.data, active: active ?? this.active);

  @override
  List<Object?> get props => [data, active];
}
