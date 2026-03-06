import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../config.dart';
import '../../../../datasources/boltz/boltz.dart';
import '../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../injection.dart';
import '../../../../util/bitcoin_amount.dart';
import '../../main.dart';
import 'operations/swap_in/swap_in_operation.dart';
import 'operations/swap_out/swap_out_operation.dart';

@Singleton()
class Rootstock extends EvmChain {
  final HostrConfig config;
  Rootstock({required this.config, required super.auth, required super.logger})
    : super(client: Web3Client(config.rootstockConfig.rpcUrl, http.Client()));

  @override
  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapInLimits() async {
    final pair = await getIt<BoltzClient>().getReversePair();
    return (
      min: BitcoinAmount.fromInt(BitcoinUnit.sat, pair.limits.minimal.ceil()),
      max: BitcoinAmount.fromInt(BitcoinUnit.sat, pair.limits.maximal.floor()),
    );
  }

  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapOutLimits() async {
    final pair = await getIt<BoltzClient>().getSubmarinePair();
    return (
      min: BitcoinAmount.fromInt(BitcoinUnit.sat, pair.limits.minimal.ceil()),
      max: BitcoinAmount.fromInt(BitcoinUnit.sat, pair.limits.maximal.floor()),
    );
  }

  @override
  Future<EtherSwap> getEtherSwapContract() async {
    // Fetch RBTC contracts
    final rbtcContracts = await getIt<BoltzClient>().rbtcContracts();
    final rbtcSwapContract = rbtcContracts.swapContracts.etherSwap;

    logger.i('RBTC Swap contract: $rbtcSwapContract');
    // Initialize EtherSwap contract
    return EtherSwap(
      address: EthereumAddress.fromHex(rbtcSwapContract!),
      client: client,
    );
  }

  @override
  RootstockSwapInOperation swapIn(SwapInParams params) =>
      getIt<RootstockSwapInOperation>(param1: params);

  @override
  List<RootstockSwapOutOperation> swapOutAll() {
    // Synchronously build a single operation for account 0 as a fallback.
    // The caller should prefer swapOutAllAddresses() for multi-address sweeps.
    return [
      getIt<RootstockSwapOutOperation>(
        param1: SwapOutParams(
          evmKey: auth.getActiveEvmKey(),
          accountIndex: 0,
          amount: null,
        ),
      ),
    ];
  }

  /// Returns one [RootstockSwapOutOperation] per funded HD-derived address.
  ///
  /// Scans all used addresses and creates a swap-out operation for each one
  /// that holds a non-zero balance.  If no used address has funds, falls back
  /// to a single operation targeting account index 0.
  @override
  Future<List<RootstockSwapOutOperation>> swapOutAllAddresses() async {
    final funded = await getAddressesWithBalance();

    if (funded.isEmpty) {
      // Nothing found – return single op for account 0 (will fail gracefully
      // with an insufficient-balance error during execution).
      return [
        getIt<RootstockSwapOutOperation>(
          param1: SwapOutParams(
            evmKey: auth.getActiveEvmKey(accountIndex: 0),
            accountIndex: 0,
            amount: null,
          ),
        ),
      ];
    }

    return funded.map((entry) {
      return getIt<RootstockSwapOutOperation>(
        param1: SwapOutParams(
          evmKey: auth.getActiveEvmKey(accountIndex: entry.accountIndex),
          accountIndex: entry.accountIndex,
          amount: null,
        ),
      );
    }).toList();
  }
}
