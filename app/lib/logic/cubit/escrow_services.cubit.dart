import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

class EscrowServicesState extends Equatable {
  final List<EscrowService>? data;
  final bool loading;
  final Object? error;

  const EscrowServicesState({this.data, this.loading = false, this.error});

  EscrowServicesState copyWith({
    List<EscrowService>? data,
    bool? loading,
    Object? error,
  }) => EscrowServicesState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    error: error,
  );

  @override
  List<Object?> get props => [data, loading, error];
}

/// Loads all [EscrowService] events authored by a given pubkey.
class EscrowServicesCubit extends Cubit<EscrowServicesState> {
  final Hostr hostr;
  final String pubkey;

  EscrowServicesCubit({required this.hostr, required this.pubkey})
    : super(const EscrowServicesState());

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final services = await hostr.escrows.list(
        Filter(kinds: EscrowService.kinds, authors: [pubkey]),
      );
      emit(EscrowServicesState(data: services, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e));
    }
  }
}
