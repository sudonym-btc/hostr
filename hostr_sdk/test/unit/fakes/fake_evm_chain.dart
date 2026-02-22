import 'dart:typed_data';

import 'package:hostr_sdk/datasources/contracts/boltz/EtherSwap.g.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

/// A fake [EvmChain] for testing [SwapRecoveryService].
///
/// Instead of connecting to a real RPC or smart contract, this fake lets tests
/// configure the results of claim and refund operations.
class FakeEvmChain extends Fake implements EvmChain {
  /// If non-null, [_attemptClaim] (via RifRelay) will return this tx hash.
  /// If null, the claim will throw.
  String? claimResult;

  /// Optional per-boltzId override for claim results.
  final Map<String, String?> claimResultByBoltzId = {};

  /// If non-null, cooperative refund returns this tx hash.
  String? refundCooperativeResult;

  /// If non-null, timelock refund returns this tx hash.
  String? refundResult;

  /// The current block number (for timelock expiry checks).
  int currentBlockNumber = 0;

  late final FakeEtherSwap _etherSwap = FakeEtherSwap(this);

  @override
  Web3Client get client => FakeWeb3Client(this);

  @override
  Future<EtherSwap> getEtherSwapContract() async => _etherSwap;

  @override
  Future<TransactionReceipt> awaitReceipt(String txHash) async {
    return TransactionReceipt(
      transactionHash: Uint8List(32),
      transactionIndex: 0,
      blockHash: Uint8List(32),
      cumulativeGasUsed: BigInt.zero,
      status: true,
    );
  }

  @override
  CustomLogger get logger => CustomLogger();
}

/// A fake [EtherSwap] that delegates to [FakeEvmChain] for test control.
class FakeEtherSwap extends Fake implements EtherSwap {
  final FakeEvmChain _chain;
  FakeEtherSwap(this._chain);

  @override
  Future<String> refundCooperative$2(
    ({
      Uint8List preimageHash,
      BigInt amount,
      EthereumAddress claimAddress,
      BigInt timelock,
      BigInt v,
      Uint8List r,
      Uint8List s,
    })
    args, {
    required Credentials credentials,
    Transaction? transaction,
  }) async {
    final result = _chain.refundCooperativeResult;
    if (result == null) {
      throw Exception('Cooperative refund failed (test)');
    }
    return result;
  }

  @override
  Future<String> refund(
    ({
      Uint8List preimageHash,
      BigInt amount,
      EthereumAddress claimAddress,
      BigInt timelock,
    })
    args, {
    required Credentials credentials,
    Transaction? transaction,
  }) async {
    final result = _chain.refundResult;
    if (result == null) {
      throw Exception('Timelock refund failed (test)');
    }
    return result;
  }
}

/// A fake [Web3Client] that returns the configured block number.
class FakeWeb3Client extends Fake implements Web3Client {
  final FakeEvmChain _chain;
  FakeWeb3Client(this._chain);

  @override
  Future<int> getBlockNumber() async => _chain.currentBlockNumber;
}

/// A fake [RifRelay] for claim operations in tests.
class FakeRifRelay extends Fake implements RifRelay {
  final FakeEvmChain _chain;
  FakeRifRelay(this._chain);

  @override
  Future<String> relayClaimTransaction({
    required EthPrivateKey signer,
    required EtherSwap etherSwap,
    required Uint8List preimage,
    required BigInt amountWei,
    required EthereumAddress refundAddress,
    required BigInt timeoutBlockHeight,
  }) async {
    final result = _chain.claimResult;
    if (result == null) {
      throw Exception('Claim relay failed (test)');
    }
    return result;
  }
}
