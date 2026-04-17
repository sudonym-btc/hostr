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
/// transactions against a live Anvil/chain node, funds addresses via
/// `anvil_setBalance`, and sets up NIP-05 / LUD-16 via LNbits.
///
/// Owns all mutable infrastructure state (HTTP clients, nonce caches,
/// contract instances) and disposes them on [close].
class InfrastructureSink implements SeedSink {
  final String rpcUrl;
  final String contractAddress;
  final int chainId;
  final BroadcastIsolate? _broadcaster;
  final LnbitsSetupConfig? _lnbitsConfig;

  http.Client? _httpClient;
  Web3Client? _web3Client;
  AnvilClient? _anvilClient;
  MultiEscrow? _escrowContract;
  int _clientGeneration = 0;

  // Pre-scanned on-chain state for idempotent re-seeding.
  final Map<String, String> _existingTrades = {}; // tradeIdHex → txHash
  final Set<String> _settledTrades = {};
  Future<void>? _logsScanFuture;

  // Per-address nonce cache + lock to prevent concurrent-fetch races.
  final Map<String, int> _nonces = {};
  final Map<String, Completer<void>> _nonceLocks = {};

  // Per-buyer lock so that the entire ERC-20 sequence
  // (setBalance → approve → createTrade) is serialised per address.
  final Map<String, Future<void>> _buyerLocks = {};

  InfrastructureSink({
    required this.rpcUrl,
    required this.contractAddress,
    required this.chainId,
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
      final guestCredentials = await deriveEvmKey(intent.buyerPrivateKey);
      final buyer = guestCredentials.address;
      final seller = (await deriveEvmKey(intent.sellerPrivateKey)).address;
      final arbiter = (await deriveEvmKey(intent.arbiterPrivateKey)).address;
      final tokenAddress = EthereumAddress.fromHex(intent.token.address);

      final tradeIdBytes = getBytes32(intent.tradeId);
      final gasPrice = await _retryChainCall((c) => c.getGasPrice());

      String txHash;

      if (intent.token.isNative) {
        // ── Native token: send msg.value from the buyer ────────────────
        final nonce = await _nextNonce(guestCredentials.address);
        txHash = await _escrow().createTrade(
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
          credentials: guestCredentials,
          transaction: Transaction(
            nonce: nonce,
            value: EtherAmount.inWei(
              intent.amountWei + (intent.bondAmountWei ?? BigInt.zero),
            ),
            gasPrice: gasPrice,
          ),
        );
      } else {
        // ── ERC-20 token: use anvil impersonation ─────────────────────
        // The setBalance → approve → createTrade sequence must be
        // serialised per buyer address: concurrent trades for the same
        // buyer can race on the storage-slot overwrite and on Anvil's
        // sequential nonce processing, leading to spurious reverts.
        final buyerKey = buyer.eip55With0x;
        while (_buyerLocks.containsKey(buyerKey)) {
          await _buyerLocks[buyerKey];
        }
        final lockCompleter = Completer<void>();
        _buyerLocks[buyerKey] = lockCompleter.future;

        try {
          final anvil = _anvil();
          final erc20 = IERC20(address: tokenAddress, client: _chainClient());

          // Use a large sentinel balance so concurrent trades for the same
          // buyer don't race on _setErc20Balance (each call overwrites the
          // raw storage slot, so the last writer wins).
          final largeBalance = BigInt.two.pow(128);

          // 1. Set the buyer's ERC-20 balance via storage override.
          await _setErc20Balance(
            anvil: anvil,
            token: tokenAddress.eip55With0x,
            account: buyer.eip55With0x,
            amount: largeBalance,
          );

          // 2+3. Reserve both nonces atomically so concurrent trades for
          // the same buyer can't interleave between approve and createTrade.
          final nonces = await _nextNonces(guestCredentials.address, 2);
          final approveNonce = nonces[0];
          final createNonce = nonces[1];

          // 2. Approve the escrow contract to spend the tokens.
          final approveTx = await erc20.approve(
            (
              spender: EthereumAddress.fromHex(contractAddress),
              value: largeBalance,
            ),
            credentials: guestCredentials,
            transaction: Transaction(nonce: approveNonce, gasPrice: gasPrice),
          );
          await _assertTxSucceeded(approveTx, 'erc20-approve', intent.tradeId);

          // 3. Call createTrade with msg.value = 0 (ERC-20 path).
          txHash = await _escrow().createTrade(
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
            credentials: guestCredentials,
            transaction: Transaction(
              nonce: createNonce,
              value: EtherAmount.zero(),
              gasPrice: gasPrice,
            ),
          );
        } finally {
          _buyerLocks.remove(buyerKey);
          lockCompleter.complete();
        }
      }

      print(
        '[infra-sink] submitTrade: tradeId=${intent.tradeId} '
        'fundTx=$txHash amountWei=${intent.amountWei} '
        'token=${intent.token.tagId} '
        'buyer=${buyer.eip55With0x} seller=${seller.eip55With0x} '
        'arbiter=${arbiter.eip55With0x}',
      );
      await _assertTxSucceeded(txHash, 'createTrade', intent.tradeId);

      return TradeResult(txHash: txHash);
    } on RPCError catch (e) {
      if (retries > 0 && e.message.contains('nonce too low')) {
        // Nonce cache is stale — clear it and retry.
        final key = (await deriveEvmKey(
          intent.buyerPrivateKey,
        )).address.eip55With0x;
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

    String txHash;
    if (intent.outcome == EscrowOutcome.arbitrated) {
      final credentials = await deriveEvmKey(MockKeys.escrow.privateKey!);
      final nonce = await _nextNonce(credentials.address);
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
          'arbiterNonce=$nonce',
        );
      }
      // ──────────────────────────────────────────────────────────────

      final signature = signer.signArbitrate(
        tradeId: tradeIdBytes,
        paymentFactor: paymentFactor,
        bondFactor: bondFactor,
        signer: credentials,
      );
      txHash = await _escrow().arbitrate(
        (
          tradeId: tradeIdBytes,
          paymentFactor: paymentFactor,
          bondFactor: bondFactor,
          signature: signature,
        ),
        credentials: credentials,
        transaction: Transaction(nonce: nonce, gasPrice: gasPrice),
      );
    } else if (intent.outcome == EscrowOutcome.claimedByHost) {
      final credentials = await deriveEvmKey(intent.settlerPrivateKey);
      final nonce = await _nextNonce(credentials.address);
      final signature = signer.signClaim(
        tradeId: tradeIdBytes,
        signer: credentials,
      );
      txHash = await _escrow().claim(
        (tradeId: tradeIdBytes, signature: signature),
        credentials: credentials,
        transaction: Transaction(nonce: nonce, gasPrice: gasPrice),
      );
    } else {
      final credentials = await deriveEvmKey(intent.settlerPrivateKey);
      final nonce = await _nextNonce(credentials.address);
      final signature = signer.signRelease(
        tradeId: tradeIdBytes,
        actor: credentials.address,
        signer: credentials,
      );
      txHash = await _escrow().releaseToCounterparty(
        (
          tradeId: tradeIdBytes,
          actor: credentials.address,
          signature: signature,
        ),
        credentials: credentials,
        transaction: Transaction(nonce: nonce, gasPrice: gasPrice),
      );
    }

    print(
      '[infra-sink] settleTrade: tradeId=${intent.tradeId} '
      'outcome=${intent.outcome.name} tx=$txHash',
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

  /// Set an ERC-20 balance for [account] by writing directly to storage.
  ///
  /// Assumes a standard OpenZeppelin `balanceOf` mapping at slot 0.
  /// Uses `anvil_setStorageAt` — works on Anvil and Hardhat.
  Future<void> _setErc20Balance({
    required AnvilClient anvil,
    required String token,
    required String account,
    required BigInt amount,
  }) async {
    // balanceOf mapping slot: keccak256(abi.encode(address, slot))
    // For OpenZeppelin ERC-20, the mapping is at slot 0.
    final paddedAccount = account
        .replaceFirst('0x', '')
        .toLowerCase()
        .padLeft(64, '0');
    const paddedSlot =
        '0000000000000000000000000000000000000000000000000000000000000000';
    final preimage = '$paddedAccount$paddedSlot';

    // Compute keccak256.
    final preimageBytes = Uint8List.fromList([
      for (var i = 0; i < preimage.length; i += 2)
        int.parse(preimage.substring(i, i + 2), radix: 16),
    ]);
    final hash = keccak256(preimageBytes);
    final slot = '0x${bytesToHex(hash)}';
    final value = '0x${amount.toRadixString(16).padLeft(64, '0')}';

    final ok = await anvil.setStorageAt(
      address: token,
      slot: slot,
      value: value,
    );
    if (!ok) {
      throw Exception(
        '[infra-sink] Failed to set ERC-20 balance for $account on $token',
      );
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
    _buyerLocks.clear();
    _logsScanFuture = null;
    _clientGeneration++;
  }
}
