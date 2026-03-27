import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/boltz/ERC20Swap.g.dart' as erc20_swap;
import '../../../datasources/contracts/boltz/EtherSwap.g.dart' as ether_swap;
import '../../../util/custom_logger.dart';
import '../chain/evm_chain.dart';
import 'boltz_swap_provider.dart';

// ── Unified event types ─────────────────────────────────────────────
//
// Callers only need a small subset of event data. These lightweight types
// decouple the scanner's public API from the generated contract bindings
// (which differ between EtherSwap and ERC20Swap).

/// A verified on-chain Lockup event.
class ScannedLockup {
  final String transactionHash;
  final BigInt amount;
  final EthereumAddress claimAddress;
  final EthereumAddress refundAddress;
  final BigInt timelock;

  const ScannedLockup({
    required this.transactionHash,
    required this.amount,
    required this.claimAddress,
    required this.refundAddress,
    required this.timelock,
  });
}

/// A verified on-chain Claim event.
class ScannedClaim {
  final String transactionHash;
  final Uint8List preimage;

  const ScannedClaim({required this.transactionHash, required this.preimage});
}

/// A verified on-chain Refund event.
class ScannedRefund {
  final String transactionHash;

  const ScannedRefund({required this.transactionHash});
}

/// Scans on-chain Boltz swap contract events (Lockup, Claim, Refund).
///
/// Extracts the repetitive "pick contract, build filter, scan logs, match
/// by preimage hash" pattern from the operation classes.
class BoltzEventScanner {
  final BoltzSwapProvider swaps;
  final EvmChain chain;
  final CustomLogger logger;

  const BoltzEventScanner({
    required this.swaps,
    required this.chain,
    required this.logger,
  });

  int get _chainId => chain.config.chainId;

  // ── Public: find events by preimage hash ───────────────────────────

  /// Scans for a Lockup event matching [preimageHash].
  Future<ScannedLockup?> findLockup({
    required String preimageHash,
    int? fromBlock,
    String? tokenAddress,
  }) => logger.span('findLockup', () async {
    try {
      final isErc20 = tokenAddress != null;
      final contract = _swapContract(isErc20);
      final from = fromBlock != null
          ? BlockNum.exact(fromBlock)
          : const BlockNum.exact(0);

      logger.d(
        'findLockup: chain=$_chainId '
        'contract=${contract.address.eip55With0x} '
        'isErc20=$isErc20 preimageHash=$preimageHash '
        'fromBlock=${fromBlock ?? "genesis"}',
      );

      final event = contract.event('Lockup');
      final filter = FilterOptions.events(
        contract: contract,
        event: event,
        fromBlock: from,
        toBlock: const BlockNum.current(),
      );
      final logs = await chain.client.getLogs(filter);
      logger.d(
        'findLockup: ${logs.length} Lockup log(s) from '
        '${contract.address.eip55With0x} since block '
        '${fromBlock ?? "genesis"}',
      );
      for (final log in logs) {
        final topics = log.topics;
        if (topics == null || topics.length < 2) continue;
        final topicHex = topics[1]!.replaceFirst('0x', '').toLowerCase();
        if (topicHex != preimageHash.toLowerCase()) continue;

        return _decodeLockup(log, isErc20, event);
      }
      if (logs.isNotEmpty) {
        logger.w(
          'findLockup: ${logs.length} Lockup log(s) found but '
          'none matched preimageHash=$preimageHash on chain $_chainId',
        );
      }
      return null;
    } catch (e, st) {
      logger.w('Failed to query lockup events on chain $_chainId: $e');
      logger.d('findLockup stack trace: $st');
      return null;
    }
  });

  /// Scans for a Claim event matching [preimageHash].
  Future<ScannedClaim?> findClaim({
    required String preimageHash,
    int? fromBlock,
    String? tokenAddress,
  }) => logger.span('findClaim', () async {
    try {
      final isErc20 = tokenAddress != null;
      final contract = _swapContract(isErc20);
      final from = fromBlock != null
          ? BlockNum.exact(fromBlock)
          : const BlockNum.exact(0);

      final event = contract.event('Claim');
      final filter = FilterOptions.events(
        contract: contract,
        event: event,
        fromBlock: from,
        toBlock: const BlockNum.current(),
      );
      final logs = await chain.client.getLogs(filter);
      for (final log in logs) {
        final topics = log.topics;
        if (topics == null || topics.length < 2) continue;
        final topicHex = topics[1]!.replaceFirst('0x', '').toLowerCase();
        if (topicHex != preimageHash.toLowerCase()) continue;

        try {
          final decoded = event.decodeResults(topics, log.data!);
          // Claim layout is identical for EtherSwap and ERC20Swap:
          // [preimageHash, preimage]
          return ScannedClaim(
            transactionHash: log.transactionHash!,
            preimage: decoded[1] as Uint8List,
          );
        } catch (e) {
          logger.d('Standard Claim decode failed, raw data parse: $e');
          final dataBytes = _hexToBytes(log.data!);
          return ScannedClaim(
            transactionHash: log.transactionHash!,
            preimage: Uint8List.fromList(dataBytes.sublist(0, 32)),
          );
        }
      }
      return null;
    } catch (e) {
      logger.w('Failed to query claim events: $e');
      return null;
    }
  });

  /// Scans for a Refund event matching [preimageHash].
  Future<ScannedRefund?> findRefund({
    required String preimageHash,
    int? fromBlock,
    String? tokenAddress,
  }) => logger.span('findRefund', () async {
    try {
      final isErc20 = tokenAddress != null;
      final contract = _swapContract(isErc20);
      final from = fromBlock != null
          ? BlockNum.exact(fromBlock)
          : const BlockNum.exact(0);

      final event = contract.event('Refund');
      final filter = FilterOptions.events(
        contract: contract,
        event: event,
        fromBlock: from,
        toBlock: const BlockNum.current(),
      );
      final logs = await chain.client.getLogs(filter);
      final preimageHashBytes = Uint8List.fromList(hex.decode(preimageHash));
      for (final log in logs) {
        final decoded = event.decodeResults(log.topics!, log.data!);
        // Refund layout is identical for both contracts: [preimageHash]
        final refundHash = decoded[0] as Uint8List;
        if (_bytesEqual(refundHash, preimageHashBytes)) {
          return ScannedRefund(transactionHash: log.transactionHash!);
        }
      }
      return null;
    } catch (e) {
      logger.w('Failed to query refund events: $e');
      return null;
    }
  });

  // ── Diagnostics ───────────────────────────────────────────────────

  /// Diagnostic logging when a Lockup event cannot be found despite Boltz
  /// reporting a lockup tx. Logs contract addresses, receipt logs, and
  /// checks for EtherSwap / ERC20Swap mismatch.
  Future<void> logLockupDiagnostics({
    required String boltzId,
    required String txHash,
    required String preimageHash,
    required int? creationBlockHeight,
    required String? tokenAddress,
  }) async {
    try {
      final etherSwapAddr = swaps.getEtherSwapContract().self.address;
      final erc20SwapAddr = swaps.getERC20SwapContract().self.address;
      final isErc20 = tokenAddress != null;
      final queriedAddr = isErc20 ? erc20SwapAddr : etherSwapAddr;

      final receipt = await chain.client.getTransactionReceipt(txHash);
      if (receipt == null) {
        logger.e(
          '[lockup-diag] chain=$_chainId tx=$txHash receipt=null (not yet mined?)',
        );
        return;
      }

      logger.e(
        '[lockup-diag] chain=$_chainId boltzId=$boltzId tx=$txHash '
        'receiptStatus=${receipt.status} '
        'isErc20=$isErc20 tokenAddress=$tokenAddress '
        'queriedContract=${queriedAddr.eip55With0x} '
        'etherSwap=${etherSwapAddr.eip55With0x} '
        'erc20Swap=${erc20SwapAddr.eip55With0x} '
        'boltzChainKey=${swaps.chainInfo.chainKey} '
        'preimageHash=$preimageHash '
        'fromBlock=$creationBlockHeight '
        'receiptLogCount=${receipt.logs.length}',
      );

      for (var i = 0; i < receipt.logs.length; i++) {
        final log = receipt.logs[i];
        final logAddr = log.address?.eip55With0x ?? 'null';
        final matchesQueried =
            log.address?.eip55With0x == queriedAddr.eip55With0x;
        final matchesEtherSwap =
            log.address?.eip55With0x == etherSwapAddr.eip55With0x;
        final matchesErc20Swap =
            log.address?.eip55With0x == erc20SwapAddr.eip55With0x;
        final topics = log.topics?.map((t) => t ?? 'null').join(', ') ?? 'none';
        logger.e(
          '[lockup-diag] log[$i] address=$logAddr '
          'matchesQueried=$matchesQueried '
          'matchesEtherSwap=$matchesEtherSwap '
          'matchesERC20Swap=$matchesErc20Swap '
          'topics=[$topics] '
          'dataLen=${((log.data?.length ?? 2) - 2) ~/ 2} bytes',
        );
      }

      final otherAddr = isErc20 ? etherSwapAddr : erc20SwapAddr;
      final otherName = isErc20 ? 'EtherSwap' : 'ERC20Swap';
      if (receipt.logs.any(
        (l) => l.address?.eip55With0x == otherAddr.eip55With0x,
      )) {
        logger.e(
          '[lockup-diag] ⚠️  Event(s) found from $otherName '
          '(${otherAddr.eip55With0x}) — we queried '
          '${isErc20 ? "ERC20Swap" : "EtherSwap"} '
          '(${queriedAddr.eip55With0x}). '
          'isErc20=$isErc20 may be wrong for boltzChainKey='
          '${swaps.chainInfo.chainKey}, '
          'tokens=${swaps.chainInfo.tokens.keys.toList()}',
        );
      }
    } catch (e) {
      logger.e('[lockup-diag] Failed to fetch diagnostics: $e');
    }
  }

  // ── Contract resolution ───────────────────────────────────────────

  DeployedContract _swapContract(bool isErc20) => isErc20
      ? swaps.getERC20SwapContract().self
      : swaps.getEtherSwapContract().self;

  // ── Lockup decoding ───────────────────────────────────────────────

  /// Decodes a Lockup log using the correct generated type for the
  /// contract (EtherSwap vs ERC20Swap), falling back to raw topic/data
  /// parsing for legacy contract versions with different indexed layouts.
  ScannedLockup _decodeLockup(
    FilterEvent log,
    bool isErc20,
    ContractEvent event,
  ) {
    try {
      final decoded = event.decodeResults(log.topics!, log.data!);
      if (isErc20) {
        // ERC20Swap: [preimageHash, amount, tokenAddress, claimAddress,
        //             refundAddress, timelock]
        final lockup = erc20_swap.Lockup(decoded, log);
        return ScannedLockup(
          transactionHash: log.transactionHash!,
          amount: lockup.amount,
          claimAddress: lockup.claimAddress,
          refundAddress: lockup.refundAddress,
          timelock: lockup.timelock,
        );
      } else {
        // EtherSwap: [preimageHash, amount, claimAddress, refundAddress,
        //             timelock]
        final lockup = ether_swap.Lockup(decoded, log);
        return ScannedLockup(
          transactionHash: log.transactionHash!,
          amount: lockup.amount,
          claimAddress: lockup.claimAddress,
          refundAddress: lockup.refundAddress,
          timelock: lockup.timelock,
        );
      }
    } catch (e) {
      logger.d(
        'Generated Lockup decode failed (isErc20=$isErc20), '
        'falling back to raw topic/data parse: $e',
      );
      return _decodeLockupFromRaw(log, isErc20);
    }
  }

  /// Raw topic/data decoder for Lockup events. Handles both current
  /// EtherSwap/ERC20Swap layouts and legacy versions with different
  /// indexed-parameter counts.
  ScannedLockup _decodeLockupFromRaw(FilterEvent log, bool isErc20) {
    final topics = log.topics!;
    final dataBytes = _hexToBytes(log.data!);
    final wordCount = dataBytes.length ~/ 32;
    final topicCount = topics.length;

    BigInt amount = BigInt.zero;
    EthereumAddress claimAddress = EthereumAddress(Uint8List(20));
    EthereumAddress refundAddress = EthereumAddress(Uint8List(20));
    BigInt timelock = BigInt.zero;

    if (topicCount >= 4 && wordCount >= 3 && isErc20) {
      // Current ERC20Swap v6: 3 indexed (preimageHash, claimAddress,
      // refundAddress), 3 data words (amount, tokenAddress, timelock).
      claimAddress = _addressFromTopic(topics[2]!);
      refundAddress = _addressFromTopic(topics[3]!);
      amount = _bigIntFromWord(dataBytes, 0);
      // dataBytes word 1 = tokenAddress (skip — caller already knows)
      timelock = _bigIntFromWord(dataBytes, 2);
    } else if (topicCount >= 4 && wordCount >= 2) {
      // Current EtherSwap v6: 3 indexed, 2 data (amount, timelock).
      claimAddress = _addressFromTopic(topics[2]!);
      refundAddress = _addressFromTopic(topics[3]!);
      amount = _bigIntFromWord(dataBytes, 0);
      timelock = _bigIntFromWord(dataBytes, 1);
    } else if (topicCount >= 3 && wordCount >= 3) {
      // Legacy: 2 indexed (preimageHash, claimAddress), data has
      // [amount, refundAddress, timelock].
      claimAddress = _addressFromTopic(topics[2]!);
      amount = _bigIntFromWord(dataBytes, 0);
      refundAddress = _addressFromDataWord(dataBytes, 1);
      timelock = _bigIntFromWord(dataBytes, 2);
    } else if (topicCount >= 3 && wordCount >= 2) {
      // Legacy: 2 indexed, 2 data words — no refundAddress in event.
      claimAddress = _addressFromTopic(topics[2]!);
      amount = _bigIntFromWord(dataBytes, 0);
      timelock = _bigIntFromWord(dataBytes, 1);
    } else if (topicCount >= 2 && wordCount >= 4) {
      // Legacy: 1 indexed (preimageHash only), everything else in data.
      amount = _bigIntFromWord(dataBytes, 0);
      claimAddress = _addressFromDataWord(dataBytes, 1);
      refundAddress = _addressFromDataWord(dataBytes, 2);
      timelock = _bigIntFromWord(dataBytes, 3);
    }

    return ScannedLockup(
      transactionHash: log.transactionHash!,
      amount: amount,
      claimAddress: claimAddress,
      refundAddress: refundAddress,
      timelock: timelock,
    );
  }

  // ── Low-level ABI helpers ─────────────────────────────────────────

  static Uint8List _hexToBytes(String hexStr) {
    return Uint8List.fromList(hex.decode(hexStr.replaceFirst('0x', '')));
  }

  static BigInt _bigIntFromWord(Uint8List data, int wordIndex) {
    final start = wordIndex * 32;
    return BigInt.parse(hex.encode(data.sublist(start, start + 32)), radix: 16);
  }

  static EthereumAddress _addressFromTopic(String topicHex) {
    final bytes = hex.decode(topicHex.replaceFirst('0x', ''));
    return EthereumAddress(Uint8List.fromList(bytes.sublist(12, 32)));
  }

  static EthereumAddress _addressFromDataWord(Uint8List data, int wordIndex) {
    final start = wordIndex * 32;
    return EthereumAddress(
      Uint8List.fromList(data.sublist(start + 12, start + 32)),
    );
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
