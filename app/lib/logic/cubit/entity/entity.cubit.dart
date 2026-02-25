import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EntityCubit<T extends Event> extends Cubit<EntityCubitState<T>> {
  CustomLogger logger = CustomLogger();
  final CrudUseCase<T> crud;
  final Filter? filter;
  StreamSubscription<T>? _updatesSub;

  EntityCubit({required this.filter, required this.crud})
    : super(const EntityCubitState(data: null)) {
    _updatesSub = crud.updates.listen(_onUpdate);
  }

  /// Checks whether [event] matches this cubit's filter (same d-tag and
  /// author) and re-emits state with the updated data when it does.
  void _onUpdate(T event) {
    if (isClosed) return;
    final current = state.data;
    if (current == null) return;

    final matches =
        current.getDtag() != null &&
        current.getDtag() == event.getDtag() &&
        current.pubKey == event.pubKey;
    if (matches) {
      emit(EntityCubitState(data: event, active: false));
    }
  }

  Future<T?> get() async {
    logger.i("getting $filter");
    emit(state.copyWith(active: true));
    try {
      T? result = await crud.getOne(filter!);
      if (result == null) {
        logger.e("Not found error");
        emit(EntityCubitStateError(data: state.data, error: 'not found'));
        return null;
      }
      logger.i("Entity Cubit found $result");
      emit(EntityCubitState(data: result, active: false));
      return result;
    } catch (e) {
      logger.e("Error $e");
      emit(EntityCubitStateError(data: state.data, error: e));
    }
    return null;
  }

  @override
  Future<void> close() {
    _updatesSub?.cancel();
    return super.close();
  }
}

class EntityCubitState<T extends Event> extends Equatable {
  final T? data;
  final bool active;

  const EntityCubitState({required this.data, this.active = false});

  EntityCubitState<T> copyWith({T? data, bool? active}) =>
      EntityCubitState(data: data ?? this.data, active: active ?? this.active);

  @override
  List<Object?> get props => [data, active];
}

class EntityCubitStateError<T extends Event> extends EntityCubitState<T> {
  final dynamic error;
  const EntityCubitStateError({required super.data, required this.error});
}
