import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../config.dart';
import '../../../../datasources/boltz/boltz.dart';
import '../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../injection.dart';
import '../../../../util/bitcoin_amount.dart';
import '../../../../util/custom_logger.dart';
import '../../../../util/http_client_factory.dart';
import '../../../escrow/supported_escrow_contract/multi_escrow.dart';
import '../../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../../main.dart';
import 'operations/swap_in/swap_in_operation.dart';
import 'operations/swap_out/swap_out_operation.dart';
import 'rif_relay/rif_relay.dart';

@Singleton()
class Rootstock extends EvmChain {
  final HostrConfig config;
  final Map<String, SupportedEscrowContract> _supportedContractCache = {};
  int _supportedContractCacheGeneration = -1;

  static Web3Client _buildWeb3Client(String rpcUrl) =>
      Web3Client(rpcUrl, createPlatformHttpClient());

  Rootstock({required this.config, required super.auth, required super.logger})
    : super(client: _buildWeb3Client(config.rootstockConfig.rpcUrl));

  RifRelay _rifRelayForSupportedContract(String contractName) {
    final contractConfig = config.rootstockConfig.supportedContracts
        .forContractName(contractName);
    return getIt<RifRelay>(param1: client, param2: contractConfig.rifRelay);
  }

  @override
  Web3Client buildClient() => _buildWeb3Client(config.rootstockConfig.rpcUrl);

  @override
  SupportedEscrowContract getSupportedEscrowContract(
    EscrowService escrowService,
  ) {
    return getSupportedEscrowContractByName(
      'MultiEscrow',
      EthereumAddress.fromHex(escrowService.contractAddress),
    );
  }

  @override
  SupportedEscrowContract getSupportedEscrowContractByName(
    String contractName,
    EthereumAddress address,
  ) {
    if (_supportedContractCacheGeneration != clientGeneration) {
      _supportedContractCache.clear();
      _supportedContractCacheGeneration = clientGeneration;
    }

    final cacheKey = '$contractName:${address.eip55With0x}';
    return _supportedContractCache.putIfAbsent(cacheKey, () {
      final rifRelay = _rifRelayForSupportedContract(contractName);
      if (contractName == 'MultiEscrow') {
        return MultiEscrowWrapper(
          chain: this,
          client: client,
          address: address,
          rifRelay: rifRelay,
          logger: getIt<CustomLogger>(),
        );
      }

      return SupportedEscrowContractRegistry.getSupportedContract(
        contractName,
        client,
        address,
        rifRelay: rifRelay,
      )!;
    });
  }

  @override
  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapInLimits() =>
      logger.span('getSwapInLimits', () async {
        final pair = await getIt<BoltzClient>().getReversePair();
        return (
          min: BitcoinAmount.fromInt(
            BitcoinUnit.sat,
            pair.limits.minimal.ceil(),
          ),
          max: BitcoinAmount.fromInt(
            BitcoinUnit.sat,
            pair.limits.maximal.floor(),
          ),
        );
      });

  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapOutLimits() =>
      logger.span('getSwapOutLimits', () async {
        final pair = await getIt<BoltzClient>().getSubmarinePair();
        return (
          min: BitcoinAmount.fromInt(
            BitcoinUnit.sat,
            pair.limits.minimal.ceil(),
          ),
          max: BitcoinAmount.fromInt(
            BitcoinUnit.sat,
            pair.limits.maximal.floor(),
          ),
        );
      });

  @override
  Future<EtherSwap> getEtherSwapContract() =>
      logger.span('getEtherSwapContract', () async {
        // Fetch RBTC contracts
        final rbtcContracts = await getIt<BoltzClient>().rbtcContracts();
        final rbtcSwapContract = rbtcContracts.swapContracts.etherSwap;

        logger.i('RBTC Swap contract: $rbtcSwapContract');
        // Initialize EtherSwap contract
        return EtherSwap(
          address: EthereumAddress.fromHex(rbtcSwapContract!),
          client: client,
        );
      });

  @override
  RootstockSwapInOperation swapIn(SwapInParams params) =>
      getIt<RootstockSwapInOperation>(param1: params);

  @override
  Future<List<RootstockSwapOutOperation>> swapOutAll() async {
    // Synchronously build a single operation for account 0 as a fallback.
    // The caller should prefer swapOutAllAddresses() for multi-address sweeps.
    return [
      getIt<RootstockSwapOutOperation>(
        param1: SwapOutParams(
          evmKey: await auth.hd.getActiveEvmKey(),
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
  Future<List<RootstockSwapOutOperation>> swapOutAllAddresses() =>
      logger.span('swapOutAllAddresses', () async {
        final funded = await getAddressesWithBalance();
        return Future.wait(
          funded.map((entry) async {
            return getIt<RootstockSwapOutOperation>(
              param1: SwapOutParams(
                evmKey: await auth.hd.getActiveEvmKey(
                  accountIndex: entry.accountIndex,
                ),
                accountIndex: entry.accountIndex,
                amount: null,
              ),
            );
          }),
        );
      });
}
