import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class TrustedEscrowsState extends Equatable {
  final EscrowTrust? data;
  final bool loading;
  final Object? error;

  const TrustedEscrowsState({this.data, this.loading = false, this.error});

  TrustedEscrowsState copyWith({
    EscrowTrust? data,
    bool? loading,
    Object? error,
  }) => TrustedEscrowsState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    error: error,
  );

  /// Pubkeys of trusted escrows extracted from the event tags.
  List<String> get pubkeys =>
      data?.tags.where((el) => el[0] == 'p').map((el) => el[1]).toList() ?? [];

  @override
  List<Object?> get props => [data, loading, error];
}

class TrustedEscrowsCubit extends Cubit<TrustedEscrowsState> {
  final Hostr hostr;

  TrustedEscrowsCubit({required this.hostr})
    : super(const TrustedEscrowsState());

  /// Load trusted escrows once. Subsequent calls are no-ops unless [force] is
  /// true.
  Future<void> load({bool force = false}) async {
    if (!force && (state.loading || state.data != null)) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final result = await hostr.escrowTrusts.myTrusted();
      emit(TrustedEscrowsState(data: result, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e));
    }
  }

  /// Reload from the relay. Call after adding or removing a trusted escrow.
  Future<void> refresh() => load(force: true);
}
