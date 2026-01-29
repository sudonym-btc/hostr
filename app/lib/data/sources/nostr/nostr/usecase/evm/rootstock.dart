import 'package:hostr/data/sources/boltz/boltz.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/injection.dart';
import 'package:wallet/wallet.dart';

import 'evm_chain.dart';

class Rootstock extends EvmChain {
  Rootstock({required super.client});

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
}
