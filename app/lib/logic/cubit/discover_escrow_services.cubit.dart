import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

class DiscoverEscrowServicesState extends Equatable {
  final List<EscrowService>? data;
  final bool loading;
  final Object? error;

  const DiscoverEscrowServicesState({
    this.data,
    this.loading = false,
    this.error,
  });

  /// Distinct pubkeys from the discovered escrow services.
  List<String> get distinctPubkeys =>
      data != null ? data!.map((s) => s.pubKey).toSet().toList() : [];

  DiscoverEscrowServicesState copyWith({
    List<EscrowService>? data,
    bool? loading,
    Object? error,
  }) => DiscoverEscrowServicesState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    error: error,
  );

  @override
  List<Object?> get props => [data, loading, error];
}

/// Discovers escrow services whose contract bytecode hash matches the locally
/// supported MultiEscrow bytecode hash. Returns all matching [EscrowService]
/// events from which we extract distinct operator pubkeys.
class DiscoverEscrowServicesCubit extends Cubit<DiscoverEscrowServicesState> {
  final Hostr hostr;

  DiscoverEscrowServicesCubit({required this.hostr})
    : super(const DiscoverEscrowServicesState());

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      // Query all escrow service events (no author filter)
      final allServices = await hostr.escrows.list(
        Filter(kinds: EscrowService.kinds),
      );

        // Filter to only those whose contract bytecode hash we support.
        final supportedHashes = getIt<Hostr>().escrowMethods.supportedContractBytecodeHashes;
      final compatible = allServices
          .where((s) => supportedHashes.contains(s.contractBytecodeHash))
          .toList();

      emit(DiscoverEscrowServicesState(data: compatible, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e));
    }
  }
}
