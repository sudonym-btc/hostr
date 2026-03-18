import 'dart:async';
import 'dart:io' as dart_io;
import 'dart:typed_data';

import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/anvil/anvil.dart';
import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../datasources/lnbits/lnbits.dart';
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

  InfrastructureSink({
    required this.rpcUrl,
    required this.contractAddress,
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

    final tradeIdBytes = getBytes32(intent.tradeId);
    final nonce = await _nextNonce(guestCredentials.address);
    final gasPrice = await _retryChainCall((c) => c.getGasPrice());

    final txHash = await _escrow().createTrade(
      (
        tradeId: tradeIdBytes,
        buyer: buyer,
        seller: seller,
        arbiter: arbiter,
        unlockAt: intent.unlockAt,
        escrowFee: BigInt.zero,
      ),
      credentials: guestCredentials,
      transaction: Transaction(
        nonce: nonce,
        value: EtherAmount.inWei(intent.amountWei),
        maxGas: 450000,
        gasPrice: gasPrice,
      ),
    );

    print(
      '[infra-sink] submitTrade: tradeId=${intent.tradeId} '
      'fundTx=$txHash amountWei=${intent.amountWei} '
      'buyer=${buyer.eip55With0x} seller=${seller.eip55With0x} '
      'arbiter=${arbiter.eip55With0x}',
    );
    await _assertTxSucceeded(txHash, 'createTrade', intent.tradeId);

    return TradeResult(txHash: txHash);
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
    if (intent.outcome == EscrowOutcome.claimedByHost) {
      // Find the unlock time from the existing trade; for simplicity,
      // we rely on the caller having set a reasonable unlockAt.
      // No-op here — the caller manages timing.
    }

    final tradeIdBytes = getBytes32(intent.tradeId);
    final gasPrice = await _retryChainCall((c) => c.getGasPrice());

    String txHash;
    if (intent.outcome == EscrowOutcome.arbitrated) {
      final credentials = await deriveEvmKey(MockKeys.escrow.privateKey!);
      final nonce = await _nextNonce(credentials.address);
      txHash = await _escrow().arbitrate(
        (tradeId: tradeIdBytes, factor: BigInt.from(700)),
        credentials: credentials,
        transaction: Transaction(
          nonce: nonce,
          maxGas: 250000,
          gasPrice: gasPrice,
        ),
      );
    } else if (intent.outcome == EscrowOutcome.claimedByHost) {
      final credentials = await deriveEvmKey(intent.settlerPrivateKey);
      final nonce = await _nextNonce(credentials.address);
      txHash = await _escrow().claim(
        (tradeId: tradeIdBytes),
        credentials: credentials,
        transaction: Transaction(
          nonce: nonce,
          maxGas: 250000,
          gasPrice: gasPrice,
        ),
      );
    } else {
      final credentials = await deriveEvmKey(intent.settlerPrivateKey);
      final nonce = await _nextNonce(credentials.address);
      txHash = await _escrow().releaseToCounterparty$2(
        (tradeId: tradeIdBytes),
        credentials: credentials,
        transaction: Transaction(
          nonce: nonce,
          maxGas: 250000,
          gasPrice: gasPrice,
        ),
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
      final nonce = _nonces[key]!;
      _nonces[key] = nonce + 1;
      return nonce;
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
          fromBlock: const BlockNum.genesis(),
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
            fromBlock: const BlockNum.genesis(),
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
      throw Exception(
        '[infra-sink] tradeId=$tradeIdHex stage=$stage tx=$txHash '
        'failed (status=${receipt.status})',
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
  Future<void> disableAutomine({int intervalSeconds = 30}) async {
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
    _logsScanFuture = null;
    _clientGeneration++;
  }
}
