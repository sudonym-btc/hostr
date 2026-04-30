import 'dart:async';
import 'dart:io' as dart_io;
import 'dart:typed_data';

import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/anvil/anvil.dart';
import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../datasources/lnbits/lnbits.dart';
import '../../../usecase/escrow/supported_escrow_contract/escrow_eip712_signer.dart';
import '../../../usecase/payments/constants.dart';
import '../../broadcast_isolate.dart';
import '../seed_pipeline_models.dart';
import 'seed_sink.dart';

/// Real-infrastructure [SeedSink] for the CLI relay-seeder.
///
/// Publishes events to a relay via [BroadcastIsolate], executes EVM
/// transactions against a live Anvil/chain node, optionally funds addresses
/// via `anvil_setBalance`, and sets up NIP-05 / LUD-16 via LNbits.
///
/// Owns all mutable infrastructure state (HTTP clients, nonce caches,
/// contract instances) and disposes them on [close].
class InfrastructureSink implements SeedSink {
  final String rpcUrl;
  final String contractAddress;
  final int chainId;
  final String? tradeSponsorPrivateKey;
  final BroadcastIsolate? _broadcaster;
  final LnbitsSetupConfig? _lnbitsConfig;

  http.Client? _httpClient;
  Web3Client? _web3Client;
  AnvilClient? _anvilClient;
  MultiEscrow? _escrowContract;
  EthPrivateKey? _tradeSponsorCredentials;
  int _clientGeneration = 0;

  // Pre-scanned on-chain state for idempotent re-seeding.
  final Map<String, String> _existingTrades = {}; // tradeIdHex → txHash
  final Set<String> _settledTrades = {};
  Future<void>? _logsScanFuture;

  // Per-address nonce cache + lock to prevent concurrent-fetch races.
  final Map<String, int> _nonces = {};
  final Map<String, Completer<void>> _nonceLocks = {};

  // Per-sender lock so nonce-sensitive transaction sequences are serialized.
  final Map<String, Future<void>> _senderLocks = {};
  final Set<String> _gasReadySenders = {};

  InfrastructureSink({
    required this.rpcUrl,
    required this.contractAddress,
    required this.chainId,
    this.tradeSponsorPrivateKey,
    BroadcastIsolate? broadcaster,
    LnbitsSetupConfig? lnbitsConfig,
  }) : _broadcaster = broadcaster,
       _lnbitsConfig = lnbitsConfig;

  // ── SeedSink implementation ───────────────────────────────────────────────

  @override
  Future<void> publish(Nip01Event event) async {
    _broadcaster?.submit(event.hashCode, event);
  }

  @override
  Future<TradeResult> submitTrade(SubmitTrade intent) async {
    return _submitTradeInner(intent, retries: 2);
  }

  Future<TradeResult> _submitTradeInner(
    SubmitTrade intent, {
    required int retries,
  }) async {
    try {
      await _ensureLogsScan();

      // Check for existing on-chain trade (idempotent re-seed).
      final existing = _existingTrades[intent.tradeId];
      if (existing != null) {
        final settled = _settledTrades.contains(intent.tradeId);
        print(
          '[infra-sink] submitTrade: tradeId=${intent.tradeId} '
          'SKIPPED (already exists, ${settled ? "settled" : "active"}, '
          'fundTx=$existing)',
        );
        return TradeResult(txHash: existing, alreadyExisted: true);
      }

      // Derive addresses.
      final buyerCredentials = await deriveEvmKey(intent.buyerPrivateKey);
      final txCredentials = _tradeSponsor() ?? buyerCredentials;
      final buyer = buyerCredentials.address;
      final seller = (await deriveEvmKey(intent.sellerPrivateKey)).address;
      final arbiter = (await deriveEvmKey(intent.arbiterPrivateKey)).address;
      final tokenAddress = EthereumAddress.fromHex(intent.token.address);

      final tradeIdBytes = getBytes32(intent.tradeId);
      await _ensureSenderGasBalance(txCredentials);
      final gasPrice = await _retryChainCall((c) => c.getGasPrice());

      String txHash;

      // Avoid eth_estimateGas flakes while seeding. These values are well
      // above observed local costs and below Anvil's block gas limit.
      const nativeCreateGasLimit = 800000;
      const erc20ApproveGasLimit = 200000;
      const erc20CreateGasLimit = 1000000;

      if (intent.token.isNative) {
        // ── Native token: send msg.value from the transaction sender ────
        txHash = await _withSenderLock(txCredentials.address, () async {
          final nonce = await _nextNonce(txCredentials.address);
          return _escrow().createTrade(
            (
              tradeId: tradeIdBytes,
              buyer: buyer,
              seller: seller,
              arbiter: arbiter,
              token: tokenAddress,
              paymentAmount: intent.amountWei,
              bondAmount: intent.bondAmountWei ?? BigInt.zero,
              unlockAt: intent.unlockAt,
              escrowFee: BigInt.zero,
            ),
            credentials: txCredentials,
            transaction: Transaction(
              nonce: nonce,
              value: EtherAmount.inWei(
                intent.amountWei + (intent.bondAmountWei ?? BigInt.zero),
              ),
              gasPrice: gasPrice,
              maxGas: nativeCreateGasLimit,
            ),
          );
        });
      } else {
        // ── ERC-20 token: seed sender balance, approve, then create ─────
        // With a trade sponsor configured, the sponsor is the token source
        // and gas payer while the on-chain trade still records the real buyer.
        final sourceCredentials = txCredentials;
        txHash = await _withSenderLock(sourceCredentials.address, () async {
          final anvil = _anvil();
          final erc20 = IERC20(address: tokenAddress, client: _chainClient());

          // Use a large sentinel balance so repeated seeded trades do not
          // depend on prior token source balances.
          final largeBalance = BigInt.two.pow(128);

          // 1. Set the token source's ERC-20 balance via storage override.
          await anvil.setErc20Balance(
            token: tokenAddress.eip55With0x,
            account: sourceCredentials.address.eip55With0x,
            amount: largeBalance,
          );

          // 2+3. Reserve both nonces atomically so no other send from the
          // same account can interleave between approve and createTrade.
          final nonces = await _nextNonces(sourceCredentials.address, 2);
          final approveNonce = nonces[0];
          final createNonce = nonces[1];

          // 2. Approve the escrow contract to spend the tokens.
          final approveTx = await erc20.approve(
            (
              spender: EthereumAddress.fromHex(contractAddress),
              value: largeBalance,
            ),
            credentials: sourceCredentials,
            transaction: Transaction(
              nonce: approveNonce,
              gasPrice: gasPrice,
              maxGas: erc20ApproveGasLimit,
            ),
          );
          await _assertTxSucceeded(approveTx, 'erc20-approve', intent.tradeId);

          // 3. Call createTrade with msg.value = 0 (ERC-20 path).
          return _escrow().createTrade(
            (
              tradeId: tradeIdBytes,
              buyer: buyer,
              seller: seller,
              arbiter: arbiter,
              token: tokenAddress,
              paymentAmount: intent.amountWei,
              bondAmount: intent.bondAmountWei ?? BigInt.zero,
              unlockAt: intent.unlockAt,
              escrowFee: BigInt.zero,
            ),
            credentials: sourceCredentials,
            transaction: Transaction(
              nonce: createNonce,
              value: EtherAmount.zero(),
              gasPrice: gasPrice,
              maxGas: erc20CreateGasLimit,
            ),
          );
        });
      }

      print(
        '[infra-sink] submitTrade: tradeId=${intent.tradeId} '
        'fundTx=$txHash amountWei=${intent.amountWei} '
        'token=${intent.token.tagId} '
        'buyer=${buyer.eip55With0x} seller=${seller.eip55With0x} '
        'arbiter=${arbiter.eip55With0x} '
        'sender=${txCredentials.address.eip55With0x}',
      );
      await _assertTxSucceeded(txHash, 'createTrade', intent.tradeId);

      return TradeResult(txHash: txHash);
    } on RPCError catch (e) {
      if (retries > 0 && e.message.contains('nonce too low')) {
        // Nonce cache is stale — clear it and retry.
        final key =
            (_tradeSponsor() ?? await deriveEvmKey(intent.buyerPrivateKey))
                .address
                .eip55With0x;
        _nonces.remove(key);
        print(
          '[infra-sink] nonce too low for tradeId=${intent.tradeId}, '
          'retrying (${retries - 1} left)',
        );
        return _submitTradeInner(intent, retries: retries - 1);
      }
      rethrow;
    }
  }

  @override
  Future<TradeResult> settleTrade(SettleTrade intent) async {
    await _ensureLogsScan();

    // Skip if already settled.
    if (_settledTrades.contains(intent.tradeId)) {
      print(
        '[infra-sink] settleTrade: tradeId=${intent.tradeId} '
        'SKIPPED (already settled)',
      );
      return TradeResult(
        txHash: _existingTrades[intent.tradeId] ?? '0x0',
        alreadyExisted: true,
      );
    }

    // Ensure chain time is past unlock for claimedByHost.
    if (intent.outcome == EscrowOutcome.claimedByHost &&
        intent.unlockAt != null) {
      final targetTimestamp = intent.unlockAt!.toInt() + 1;
      final block = await _retryChainCall((c) => c.getBlockInformation());
      final chainNow = block.timestamp.millisecondsSinceEpoch ~/ 1000;
      if (chainNow <= intent.unlockAt!.toInt()) {
        final delta = targetTimestamp - chainNow;
        print(
          '[infra-sink] settleTrade: warping Anvil time +${delta}s '
          'past unlockAt=${intent.unlockAt} for tradeId=${intent.tradeId}',
        );
        await _anvil().advanceChainTime(seconds: delta);
      }
    }

    final tradeIdBytes = getBytes32(intent.tradeId);
    final gasPrice = await _retryChainCall((c) => c.getGasPrice());
    final signer = EscrowEip712Signer(
      chainId: chainId,
      verifyingContract: EthereumAddress.fromHex(contractAddress),
    );

    // Use a generous fixed gas limit for all settle calls.
    // web3dart's eth_estimateGas produces a tight estimate; with concurrent
    // Future.wait execution the estimate can be stale (state changes between
    // estimate and mine), causing OOG failures (revert with empty revert data).
    // 300 000 gas is well above the typical settle cost (~60-80 k) and well
    // below Anvil's block gas limit.
    const settleGasLimit = 3000000;

    String txHash;
    late EthPrivateKey txCredentials;
    if (intent.outcome == EscrowOutcome.arbitrated) {
      final signatureCredentials = await deriveEvmKey(
        MockKeys.escrow.privateKey!,
      );
      txCredentials = _tradeSponsor() ?? signatureCredentials;
      await _ensureSenderGasBalance(txCredentials);
      final paymentFactor = BigInt.from(700); // 70% of payment → seller
      final bondFactor = BigInt.zero; // 0% of bond → seller (full bond → buyer)

      // ── Diagnostic: verify trade is active before arbitrating ──────
      final preCheck = await _escrow().activeTrade((tradeId: tradeIdBytes));
      if (!preCheck.isActive) {
        final raw = await _escrow().trades(($param28: tradeIdBytes));
        throw Exception(
          '[infra-sink] PRE-CHECK FAIL: tradeId=${intent.tradeId} is NOT '
          'active before arbitrate call. '
          'buyer=${raw.buyer}, amount=${raw.paymentAmount + raw.bondAmount}, '
          'sender=${txCredentials.address.eip55With0x}',
        );
      }
      // ──────────────────────────────────────────────────────────────

      final signature = signer.signArbitrate(
        tradeId: tradeIdBytes,
        paymentFactor: paymentFactor,
        bondFactor: bondFactor,
        signer: signatureCredentials,
      );
      txHash = await _withSenderLock(txCredentials.address, () async {
        final nonce = await _nextNonce(txCredentials.address);
        return _escrow().arbitrate(
          (
            tradeId: tradeIdBytes,
            paymentFactor: paymentFactor,
            bondFactor: bondFactor,
            signature: signature,
          ),
          credentials: txCredentials,
          transaction: Transaction(
            nonce: nonce,
            gasPrice: gasPrice,
            maxGas: settleGasLimit,
          ),
        );
      });
    } else if (intent.outcome == EscrowOutcome.claimedByHost) {
      final signatureCredentials = await deriveEvmKey(intent.settlerPrivateKey);
      txCredentials = _tradeSponsor() ?? signatureCredentials;
      await _ensureSenderGasBalance(txCredentials);
      final signature = signer.signClaim(
        tradeId: tradeIdBytes,
        signer: signatureCredentials,
      );
      txHash = await _withSenderLock(txCredentials.address, () async {
        final nonce = await _nextNonce(txCredentials.address);
        return _escrow().claim(
          (tradeId: tradeIdBytes, signature: signature),
          credentials: txCredentials,
          transaction: Transaction(
            nonce: nonce,
            gasPrice: gasPrice,
            maxGas: settleGasLimit,
          ),
        );
      });
    } else {
      final signatureCredentials = await deriveEvmKey(intent.settlerPrivateKey);
      txCredentials = _tradeSponsor() ?? signatureCredentials;
      await _ensureSenderGasBalance(txCredentials);
      final signature = signer.signRelease(
        tradeId: tradeIdBytes,
        actor: signatureCredentials.address,
        signer: signatureCredentials,
      );
      txHash = await _withSenderLock(txCredentials.address, () async {
        final nonce = await _nextNonce(txCredentials.address);
        return _escrow().releaseToCounterparty(
          (
            tradeId: tradeIdBytes,
            actor: signatureCredentials.address,
            signature: signature,
          ),
          credentials: txCredentials,
          transaction: Transaction(
            nonce: nonce,
            gasPrice: gasPrice,
            maxGas: settleGasLimit,
          ),
        );
      });
    }

    print(
      '[infra-sink] settleTrade: tradeId=${intent.tradeId} '
      'outcome=${intent.outcome.name} tx=$txHash '
      'sender=${txCredentials.address.eip55With0x}',
    );
    await _assertTxSucceeded(txHash, 'settle', intent.tradeId);
    _settledTrades.add(intent.tradeId);

    return TradeResult(txHash: txHash);
  }

  @override
  Future<void> fund(FundWallet intent) async {
    // The address field may contain a private key — derive EVM address.
    final evmAddr = (await deriveEvmKey(intent.address)).address.eip55With0x;
    final anvil = _anvil();
    final funded = await anvil.setBalance(
      address: evmAddr,
      amountWei: intent.amountWei,
    );
    if (!funded) {
      throw Exception('Could not fund $evmAddr on $rpcUrl.');
    }
    print('[infra-sink] funded $evmAddr with ${intent.amountWei} wei');
  }

  @override
  Future<void> registerIdentity(RegisterIdentity intent) async {
    if (_lnbitsConfig == null) {
      print(
        '[infra-sink] registerIdentity: no LNbits config — skipping '
        '${intent.username}@${intent.domain}',
      );
      return;
    }

    final datasource = LnbitsDatasource();
    await datasource.setupNip05ByDomain(
      nip05ByDomain: {
        intent.domain: {intent.username: intent.pubkey},
      },
      config: _lnbitsConfig,
    );
    print(
      '[infra-sink] registered identity '
      '${intent.username}@${intent.domain} → ${intent.pubkey}',
    );
  }

  // ── Chain infrastructure ──────────────────────────────────────────────────

  Web3Client _chainClient() {
    _httpClient ??= IOClient(
      dart_io.HttpClient()..idleTimeout = const Duration(seconds: 10),
    );
    _web3Client ??= Web3Client(rpcUrl, _httpClient!);
    return _web3Client!;
  }

  void _resetChainClientIfGeneration(int ifGeneration) {
    if (_clientGeneration != ifGeneration) return;
    _web3Client?.dispose();
    _web3Client = null;
    _httpClient?.close();
    _httpClient = null;
    _escrowContract = null;
    _clientGeneration++;
  }

  Future<T> _retryChainCall<T>(
    Future<T> Function(Web3Client) fn, {
    int retries = 1,
  }) async {
    for (int attempt = 1; attempt <= retries + 1; attempt++) {
      final gen = _clientGeneration;
      try {
        return await fn(_chainClient());
      } on http.ClientException catch (e) {
        if (attempt > retries) rethrow;
        print(
          '[infra-sink] Stale connection on attempt $attempt – resetting: $e',
        );
        _resetChainClientIfGeneration(gen);
      } on dart_io.HttpException catch (e) {
        if (attempt > retries) rethrow;
        print('[infra-sink] HTTP error on attempt $attempt – resetting: $e');
        _resetChainClientIfGeneration(gen);
      }
    }
    throw StateError('unreachable');
  }

  MultiEscrow _escrow() {
    _escrowContract ??= MultiEscrow(
      address: EthereumAddress.fromHex(contractAddress),
      client: _chainClient(),
    );
    return _escrowContract!;
  }

  AnvilClient _anvil() {
    _anvilClient ??= AnvilClient(rpcUri: Uri.parse(rpcUrl));
    return _anvilClient!;
  }

  EthPrivateKey? _tradeSponsor() {
    final key = tradeSponsorPrivateKey?.trim();
    if (key == null || key.isEmpty) return null;
    return _tradeSponsorCredentials ??= EthPrivateKey.fromHex(
      key.startsWith('0x') ? key : '0x$key',
    );
  }

  Future<void> _ensureSenderGasBalance(EthPrivateKey credentials) async {
    final address = credentials.address;
    final key = address.eip55With0x;
    if (_gasReadySenders.contains(key)) return;

    final current = await _retryChainCall((c) => c.getBalance(address));
    const minimumWei = '1000000000000000000'; // 1 ETH
    if (current.getInWei >= BigInt.parse(minimumWei)) {
      _gasReadySenders.add(key);
      return;
    }

    // The real-infrastructure seeder targets local Anvil/Hardhat for writes.
    // Make sponsor-funded seeding robust even after chain restarts where the
    // configured sponsor key is not among the node's prefunded accounts.
    final targetWei = BigInt.parse('100000000000000000000'); // 100 ETH
    final funded = await _anvil().setBalance(
      address: key,
      amountWei: targetWei,
    );
    if (!funded) {
      throw Exception(
        '[infra-sink] Sender $key has only ${current.getInWei} wei for gas, '
        'and $rpcUrl does not allow anvil/hardhat balance top-up.',
      );
    }

    _gasReadySenders.add(key);
    print('[infra-sink] funded tx sender $key with $targetWei wei for gas');
  }

  Future<T> _withSenderLock<T>(
    EthereumAddress address,
    Future<T> Function() body,
  ) async {
    final key = address.eip55With0x;

    while (_senderLocks.containsKey(key)) {
      await _senderLocks[key]!;
    }

    final completer = Completer<void>();
    _senderLocks[key] = completer.future;

    try {
      return await body();
    } finally {
      _senderLocks.remove(key);
      completer.complete();
    }
  }

  /// Fetch (or cache) the next nonce for [address].
  ///
  /// Serializes per-address so that concurrent [submitTrade] /
  /// [settleTrade] calls for the same sender don't race on the
  /// initial `getTransactionCount` fetch and end up re-using a nonce.
  Future<int> _nextNonce(EthereumAddress address) async {
    return (await _nextNonces(address, 1)).first;
  }

  /// Reserve [count] consecutive nonces atomically for [address].
  ///
  /// This prevents other coroutines from interleaving nonces between
  /// a multi-tx sequence (e.g. ERC-20 approve + createTrade).
  Future<List<int>> _nextNonces(EthereumAddress address, int count) async {
    final key = address.eip55With0x;

    // Wait until no other coroutine is inside this critical section
    // for the same address.
    while (_nonceLocks.containsKey(key)) {
      await _nonceLocks[key]!.future;
    }

    final completer = Completer<void>();
    _nonceLocks[key] = completer;

    try {
      if (!_nonces.containsKey(key)) {
        _nonces[key] = await _retryChainCall(
          (c) =>
              c.getTransactionCount(address, atBlock: const BlockNum.pending()),
        );
      }
      final first = _nonces[key]!;
      _nonces[key] = first + count;
      return List.generate(count, (i) => first + i);
    } finally {
      _nonceLocks.remove(key);
      completer.complete();
    }
  }

  /// Batch-scan on-chain logs to discover already-created and settled trades.
  ///
  /// Memoised: the first caller triggers the scan; all concurrent callers
  /// await the same [Future] so the results are available before any
  /// [submitTrade] proceeds.
  Future<void> _ensureLogsScan() => _logsScanFuture ??= _performLogsScan();

  Future<void> _performLogsScan() async {
    final contract = _escrow();

    await Future.wait([
      // Scan TradeCreated logs.
      () async {
        final event = contract.self.event('TradeCreated');
        final filter = FilterOptions.events(
          contract: contract.self,
          event: event,
          fromBlock: const BlockNum.exact(0),
        );
        final logs = await _retryChainCall((c) => c.getLogs(filter));
        for (final log in logs) {
          final decoded = event.decodeResults(log.topics!, log.data!);
          final idHex = _bytesToHex(decoded[0] as Uint8List);
          if (log.transactionHash != null) {
            _existingTrades[idHex] = log.transactionHash!;
          }
        }
      }(),
      // Scan all settlement event types.
      for (final eventName in [
        'Claimed',
        'Arbitrated',
        'ReleasedToCounterparty',
      ])
        () async {
          final event = contract.self.event(eventName);
          final filter = FilterOptions.events(
            contract: contract.self,
            event: event,
            fromBlock: const BlockNum.exact(0),
          );
          final logs = await _retryChainCall((c) => c.getLogs(filter));
          for (final log in logs) {
            final decoded = event.decodeResults(log.topics!, log.data!);
            _settledTrades.add(_bytesToHex(decoded[0] as Uint8List));
          }
        }(),
    ]);

    print(
      '[infra-sink] Log scan: ${_existingTrades.length} created, '
      '${_settledTrades.length} settled on-chain.',
    );
  }

  Future<void> _assertTxSucceeded(
    String txHash,
    String stage,
    String tradeIdHex,
  ) async {
    final receipt = await _waitForReceipt(txHash);
    if (receipt == null) {
      final tx = await _retryChainCall((c) => c.getTransactionByHash(txHash));
      throw Exception(
        '[infra-sink] tradeId=$tradeIdHex stage=$stage tx=$txHash '
        'has no receipt (txKnown=${tx != null})',
      );
    }
    if (receipt.status != true) {
      // Diagnostic: replay the tx as eth_call to get the revert reason,
      // and check on-chain state to understand why the tx reverted.
      String diag = '';
      try {
        // 1. Get revert reason via eth_call replay.
        final tx = await _retryChainCall((c) => c.getTransactionByHash(txHash));
        if (tx != null) {
          try {
            // Use blockNumber - 1 (the state BEFORE the failed tx) so the
            // eth_call simulation is against the same pre-tx state the tx
            // actually ran against. Using blockNumber itself is wrong: since
            // the tx reverted (no state change), the end-of-block state equals
            // the pre-tx state, so the simulation would SUCCEED and return "0x"
            // (the void return value of the called function) — making it look
            // like there was no revert data when really the diagnostic just
            // succeeded silently.
            final prevBlock = receipt.blockNumber.blockNum - 1;
            final blockHex = '0x${prevBlock.toRadixString(16)}';
            final revertData = await _chainClient().makeRPCCall<String>(
              'eth_call',
              [
                {
                  'from': tx.from.eip55With0x,
                  'to': tx.to?.eip55With0x,
                  'data': bytesToHex(tx.input, include0x: true),
                  'value': '0x${tx.value.getInWei.toRadixString(16)}',
                  // Omit gas limit so the replay uses block gas limit,
                  // avoiding a spurious OutOfGas that masks the real error.
                },
                blockHex,
              ],
            );
            diag += ' | revertData=$revertData';
          } catch (rpcErr) {
            // RPCError.message often contains the decoded revert reason.
            diag += ' | revertRpc=$rpcErr';
          }
        }

        // 2. Check post-tx on-chain state.
        final tradeIdBytes = getBytes32(tradeIdHex);
        final postCheck = await _escrow().activeTrade((tradeId: tradeIdBytes));
        final raw = await _escrow().trades(($param28: tradeIdBytes));
        diag +=
            ' | postTx: isActive=${postCheck.isActive}, '
            'buyer=${raw.buyer}, '
            'amount=${(raw.paymentAmount + raw.bondAmount)}, '
            'arbiter=${raw.arbiter}';
      } catch (_) {}
      throw Exception(
        '[infra-sink] tradeId=$tradeIdHex stage=$stage tx=$txHash '
        'failed (status=${receipt.status})$diag',
      );
    }
  }

  Future<dynamic> _waitForReceipt(String txHash) async {
    const maxAttempts = 60;
    var delay = const Duration(milliseconds: 100);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final receipt = await _retryChainCall(
        (c) => c.getTransactionReceipt(txHash),
      );
      if (receipt != null) return receipt;
      await Future<void>.delayed(delay);
      // Ramp up: 100 → 200 → 400 → 500 (cap) ms.
      if (delay < const Duration(milliseconds: 500)) {
        delay = delay * 2;
        if (delay > const Duration(milliseconds: 500)) {
          delay = const Duration(milliseconds: 500);
        }
      }
    }
    return null;
  }

  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Enable auto-mining on the Anvil node.
  Future<void> enableAutomine() async {
    await _anvil().setAutomine(true);
  }

  /// Disable auto-mining, switch to interval mining.
  Future<void> disableAutomine({int intervalSeconds = 3}) async {
    await _anvil().setAutomine(false);
    await _anvil().setIntervalMining(intervalSeconds);
  }

  /// Dispose all infrastructure resources.
  void close() {
    _web3Client?.dispose();
    _web3Client = null;
    _httpClient?.close();
    _httpClient = null;
    _escrowContract = null;
    _anvilClient?.close();
    _anvilClient = null;
    _nonces.clear();
    _nonceLocks.clear();
    _senderLocks.clear();
    _logsScanFuture = null;
    _clientGeneration++;
  }
}
