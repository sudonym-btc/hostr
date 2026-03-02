import 'dart:async';
import 'dart:math';

import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../usecase/auth/auth.dart';
import '../../../util/bitcoin_amount.dart';
import '../../../util/custom_logger.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../operations/swap_in/swap_in_models.dart';
import '../operations/swap_in/swap_in_operation.dart';
import '../operations/swap_out/swap_out_operation.dart';

abstract class EvmChain {
  final Web3Client client;
  final CustomLogger logger;
  final Auth auth;
  EvmChain({required this.client, required this.auth, required this.logger});

  SupportedEscrowContract getSupportedEscrowContract(
    EscrowService escrowService,
  ) {
    return SupportedEscrowContractRegistry.getSupportedContract(
      'MultiEscrow', // to be replaced with ABI hash or bytecode hash
      client,
      EthereumAddress.fromHex(escrowService.parsedContent.contractAddress),
    )!;
  }

  Future<BigInt> getChainId() async {
    return await client.getChainId();
  }

  Future<BitcoinAmount> getBalance(EthereumAddress address) async {
    logger.d('Getting balance for $address');
    return await client.getBalance(address).then((val) {
      logger.d('Balance for $address: $val');
      return BitcoinAmount.inWei(val.getInWei);
    });
  }

  /// Emits a new block number whenever the chain advances.
  ///
  /// Uses `eth_blockNumber` polling — the most universally supported RPC
  /// method across all EVM nodes (Rootstock, Anvil, Geth, etc.).
  /// Unlike `eth_newBlockFilter` or `eth_subscribe`, this works with every
  /// HTTP and WebSocket RPC endpoint.
  Stream<int> _newBlocks({
    Duration interval = const Duration(seconds: 15),
  }) async* {
    int? lastBlock;
    while (true) {
      try {
        final current = await client.getBlockNumber();
        if (lastBlock == null || current > lastBlock!) {
          lastBlock = current;
          yield current;
        }
      } catch (e) {
        logger.w('Block number poll failed: $e');
      }
      await Future.delayed(interval);
    }
  }

  Stream<BitcoinAmount> subscribeBalance(EthereumAddress address) async* {
    try {
      yield await getBalance(address);
    } catch (e) {
      logger.w('Failed initial balance fetch: $e');
    }

    await for (final _ in _newBlocks()) {
      try {
        yield await getBalance(address);
      } catch (e) {
        logger.w('Failed to fetch balance on new block: $e');
      }
    }
  }

  Future<TransactionInformation?> getTransaction(String txHash) async {
    logger.d('Getting transaction for $txHash');
    return await client.getTransactionByHash(txHash).then((val) {
      logger.d(
        'Transaction for $txHash: from ${val?.from} to ${val?.to} amount ${val?.value.getInWei}',
      );
      return val;
    });
  }

  Future<TransactionInformation> awaitTransaction(String txHash) async {
    // Poll until our RPC node sees the transaction (may lag behind Boltz).
    while (true) {
      final tx = await getTransaction(txHash);
      if (tx != null) {
        logger.i(
          'Transaction $txHash confirmed: from ${tx.from} value ${tx.value.getInWei}',
        );
        return tx;
      }
      logger.i('Transaction $txHash not found, retrying…');
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<TransactionReceipt> awaitReceipt(String txHash) async {
    while (true) {
      final receipt = await client.getTransactionReceipt(txHash);
      if (receipt != null) return receipt;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Returns the first HD-derived EVM address that has never been used
  /// on-chain (zero nonce **and** zero balance).
  ///
  /// Addresses are derived from [auth] using BIP-44 account indices
  /// (`m/44'/60'/0'/0/{index}`).  To minimise latency the function checks
  /// [_batchSize] addresses in parallel per round, which keeps RPC round-trips
  /// to a minimum while staying within typical rate-limits.
  ///
  /// Returns a record containing both the [EthereumAddress] and its
  /// [accountIndex] so callers can persist or re-derive the key later.
  Future<({EthereumAddress address, int accountIndex})>
  getNextUnusedAddress() async {
    const batchSize = 5;

    for (var offset = 0; ; offset += batchSize) {
      // Derive a batch of addresses.
      final indices = List.generate(batchSize, (i) => offset + i);
      final addresses = indices.map(
        (i) => (index: i, address: auth.getEvmAddress(accountIndex: i)),
      );

      // Fire nonce + balance queries for every address in the batch at once.
      final results = await Future.wait(
        addresses.map((entry) async {
          final nonce = await client.getTransactionCount(entry.address);
          final balance = await client.getBalance(entry.address);
          return (
            index: entry.index,
            address: entry.address,
            used: nonce > 0 || balance.getInWei > BigInt.zero,
          );
        }),
      );

      // Return the first unused address (results are in index order).
      for (final r in results) {
        if (!r.used) {
          return (address: r.address, accountIndex: r.index);
        }
      }
    }
  }

  /// Returns all HD-derived EVM addresses that hold a non-zero balance,
  /// along with their account index and current balance.
  ///
  /// Unlike the previous nonce-based approach, this scans a fixed window of
  /// [_maxScanIndex] addresses by **balance only**.  Addresses that received
  /// funds via swap-in never send a transaction (nonce stays 0), so
  /// nonce-based gap detection would miss them.
  static const _maxScanIndex = 20;

  Future<
    List<({EthereumAddress address, int accountIndex, BitcoinAmount balance})>
  >
  getAddressesWithBalance() async {
    const batchSize = 5;
    final funded =
        <
          ({EthereumAddress address, int accountIndex, BitcoinAmount balance})
        >[];

    for (var offset = 0; offset < _maxScanIndex; offset += batchSize) {
      final count = min(batchSize, _maxScanIndex - offset);
      final indices = List.generate(count, (i) => offset + i);
      final addresses = indices.map(
        (i) => (index: i, address: auth.getEvmAddress(accountIndex: i)),
      );

      final results = await Future.wait(
        addresses.map((entry) async {
          final balance = await client.getBalance(entry.address);
          return (index: entry.index, address: entry.address, balance: balance);
        }),
      );

      for (final r in results) {
        if (r.balance.getInWei > BigInt.zero) {
          funded.add((
            address: r.address,
            accountIndex: r.index,
            balance: BitcoinAmount.inWei(r.balance.getInWei),
          ));
        }
      }
    }

    return funded;
  }

  /// Returns the total balance across all HD-derived addresses that hold
  /// funds, scanning up to [_maxScanIndex] indices.
  Future<BitcoinAmount> getTotalBalance() async {
    final addresses = await getAddressesWithBalance();
    return addresses.fold<BitcoinAmount>(
      BitcoinAmount.zero(),
      (sum, entry) => sum + entry.balance,
    );
  }

  /// Emits the total balance across all used addresses on each new block.
  Stream<BitcoinAmount> subscribeTotalBalance() async* {
    try {
      yield await getTotalBalance();
    } catch (e) {
      logger.w('Failed initial total balance fetch: $e');
    }

    await for (final _ in _newBlocks()) {
      try {
        yield await getTotalBalance();
      } catch (e) {
        logger.w('Failed to fetch total balance on new block: $e');
      }
    }
  }

  Future<EtherSwap> getEtherSwapContract();

  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapInLimits();

  SwapInOperation swapIn(SwapInParams params);

  List<SwapOutOperation> swapOutAll();

  /// Async version that scans all HD-derived addresses for non-zero balances
  /// and returns one [SwapOutOperation] per funded address.
  ///
  /// Subclasses should override to provide chain-specific implementations.
  /// The default falls back to [swapOutAll] (account 0 only).
  Future<List<SwapOutOperation>> swapOutAllAddresses() async => swapOutAll();

  Future<List<dynamic>> call(
    ContractAbi abi,
    EthereumAddress address,
    ContractFunction func,
    params,
  ) {
    return client.call(
      contract: DeployedContract(abi, address),
      function: func,
      params: params,
    );
  }
}

double convertWeiToSatoshi(BigInt wei) {
  return wei.toDouble() / pow(10, 18 - 8);
}

double convertWeiToBTC(BigInt wei) {
  return wei.toDouble() / pow(10, 18);
}
