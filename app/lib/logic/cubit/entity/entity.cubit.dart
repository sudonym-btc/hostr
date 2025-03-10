import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EntityCubit<T extends Event> extends Cubit<EntityCubitState<T>> {
  CustomLogger logger = CustomLogger();
  NostrService nostr = getIt<NostrService>();
  final Filter? filter;

  EntityCubit({required this.filter})
      : super(const EntityCubitState(data: null));

  get() async {
    logger.i("getting $filter");
    emit(state.copyWith(active: true));
    try {
      T? result = await nostr.startRequestAsync(filters: [
        getCombinedFilter(filter, Filter(limit: 1))
      ]).then((items) => items.isNotEmpty ? items.first as T : null);
      if (result == null) {
        logger.e("Not found error");
        emit(EntityCubitStateError(data: state.data, error: 'not found'));
        return;
      }
      logger.i("Entity Cubit found $result");
      emit(EntityCubitState(data: result, active: false));
    } catch (e) {
      logger.e("Error $e");
      emit(EntityCubitStateError(data: state.data, error: e));
    }
  }
}

class EntityCubitState<T extends Event> extends Equatable {
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

class EntityCubitStateError<T extends Event> extends EntityCubitState<T> {
  dynamic error;
  EntityCubitStateError({required super.data, required this.error});
}
