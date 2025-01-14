import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

class EntityCubit<T extends NostrEvent> extends Cubit<EntityCubitState<T>> {
  CustomLogger logger = CustomLogger();
  NostrService nostr = getIt<NostrService>();
  final NostrFilter? filter;

  EntityCubit({required this.filter})
      : super(const EntityCubitState(data: null));

  get() async {
    logger.i("getting $filter");
    emit(state.copyWith(active: true));
    try {
      T result = await nostr
          .startRequestAsync(
              request: NostrRequest(
                  filters: [getCombinedFilter(filter, NostrFilter(limit: 1))]))
          .then((items) => items.first as T);
      if (result == null) {
        emit(EntityCubitStateError(data: state.data, error: 'not found'));
        return;
      }
      emit(EntityCubitState(data: result, active: false));
    } catch (e) {
      emit(EntityCubitStateError(data: state.data, error: e));
    }
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

class EntityCubitStateError<T extends NostrEvent> extends EntityCubitState<T> {
  dynamic error;
  EntityCubitStateError({required super.data, required this.error});
}
