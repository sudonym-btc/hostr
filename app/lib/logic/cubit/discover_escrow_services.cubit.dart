import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;
import 'package:wallet/wallet.dart' show EthereumAddress;

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

/// Discovers escrow services whose on-chain runtime bytecode is one that this
/// client natively supports.
///
/// For each discovered service, the contract address is fetched and its
/// runtime bytecode is hashed on demand via
/// [SupportedEscrowContractRegistry.bytecodeHashForAddress], then compared
/// against the hash stored in the [EscrowService] event.  This avoids keeping
/// a compile-time list of known hashes.
class DiscoverEscrowServicesCubit extends Cubit<DiscoverEscrowServicesState> {
  final Hostr hostr;

  DiscoverEscrowServicesCubit({required this.hostr})
    : super(const DiscoverEscrowServicesState());

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      // Query all escrow service events (no author filter).
      final allServices = await hostr.escrows.list(
        Filter(kinds: EscrowService.kinds),
      );

      // For each service, resolve the actual on-chain bytecode hash and
      // compare it to what the service advertises.  We use the first
      // configured EVM chain's client as a best-effort transport; services
      // on other chains are included when their contractBytecodeHash matches.
      final chains = hostr.evm.configuredChains;
      if (chains.isEmpty) {
        emit(DiscoverEscrowServicesState(data: [], loading: false));
        return;
      }

      final client = chains.first.client;
      final compatible = <EscrowService>[];

      for (final service in allServices) {
        try {
          final actualHash =
              await SupportedEscrowContractRegistry.bytecodeHashForAddress(
                client,
                EthereumAddress.fromHex(service.contractAddress),
              );
          if (actualHash == service.contractBytecodeHash) {
            compatible.add(service);
          }
        } catch (_) {
          // Skip services whose contract address cannot be resolved.
        }
      }

      emit(DiscoverEscrowServicesState(data: compatible, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e));
    }
  }
}