import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_out/swap_out_operation.dart';
import 'package:hostr_sdk/usecase/evm/main.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../datasources/boltz/boltz.dart';
import '../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../util/bitcoin_amount.dart';
import 'operations/swap_in/swap_in_operation.dart';

@Singleton()
class Rootstock extends EvmChain {
  final HostrConfig config;
  Rootstock({required this.config, required super.auth, required super.logger})
    : super(client: Web3Client(config.rootstockConfig.rpcUrl, http.Client()));

  @override
  Future<BitcoinAmount> getMinimumSwapIn() async {
    final response = (await getIt<BoltzClient>().getSwapReserve());
    return BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      response.body["BTC"]["RBTC"]["limits"]["minimal"],
    );
  }

  Future<BitcoinAmount> getMinimumSwapOut() async {
    final response = (await getIt<BoltzClient>().getSwapSubmarine());
    return BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      response.body["RBTC"]["BTC"]["limits"]["minimal"],
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
  RootstockSwapOutOperation swapOutAll() => getIt<RootstockSwapOutOperation>(
    param1: SwapOutParams(evmKey: auth.getActiveEvmKey(), amount: null),
  );
}
