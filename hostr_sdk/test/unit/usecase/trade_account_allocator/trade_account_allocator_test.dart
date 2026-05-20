@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/messaging/thread.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/orders/orders.dart';
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator_impl.dart';
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_cache.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:hostr_sdk/util/stream_status.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart'
    show BlockNum, EthPrivateKey, Web3Client;

// ── Fakes ──────────────────────────────────────────────────────────────

class _FakeAuth extends Fake implements Auth {
  int _maxAccountIndex = -1;
  final KeyPair? _keyPair;

  _FakeAuth({KeyPair? keyPair, int maxAccountIndex = -1})
    : _keyPair = keyPair,
      _maxAccountIndex = maxAccountIndex;

  @override
  KeyPair? get activeKeyPair => _keyPair;

  @override
  int get storedMaxAccountIndex => _maxAccountIndex;

  @override
  Future<void> updateMaxAccountIndex(int maxAccountIndex) async {
    if (maxAccountIndex > _maxAccountIndex) {
      _maxAccountIndex = maxAccountIndex;
    }
  }
}

class _FakeDeterministicKeys extends Fake implements DeterministicKeys {
  /// Map from accountIndex → tradeId.
  final Map<int, String> tradeIds;

  /// Map from accountIndex → EVM address.
  final Map<int, bip.EthereumAddress> evmAddresses;

  final List<int> tradeIdLookups = [];

  static final KeyPair _tradeKey = MockKeys.reviewer;

  _FakeDeterministicKeys({
    this.tradeIds = const {},
    this.evmAddresses = const {},
  });

  @override
  Future<String> getTradeId({required int accountIndex}) async {
    tradeIdLookups.add(accountIndex);
    return tradeIds[accountIndex] ?? 'trade-$accountIndex';
  }

  @override
  Future<bip.EthereumAddress> getEvmAddress({int accountIndex = 0}) async =>
      evmAddresses[accountIndex] ??
      bip.EthereumAddress.fromHex(
        '0x${accountIndex.toRadixString(16).padLeft(40, '0')}',
      );

  @override
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0}) async =>
      EthPrivateKey.fromHex(
        (accountIndex + 1).toRadixString(16).padLeft(64, '0'),
      );

  @override
  Future<KeyPair> getTradeKeyPair({required int accountIndex}) async =>
      _tradeKey;
}

class _FakeEvmChain extends Fake implements EvmChain {
  @override
  final Web3Client client;

  final Map<String, bip.EthereumAddress> smartAddressesByEoa;
  final Set<String> usedSmartAddresses;

  _FakeEvmChain(
    this.client, {
    this.smartAddressesByEoa = const {},
    this.usedSmartAddresses = const {},
  });

  @override
  Future<bool> hasAccountActivity(
    EthPrivateKey signer, {
    bip.EthereumAddress? eoaAddress,
  }) async {
    final eoa = eoaAddress ?? signer.address;
    final eoaNonce = await client.getTransactionCount(eoa);
    final eoaBalance = await client.getBalance(eoa);
    if (eoaNonce > 0 || eoaBalance.getInWei > BigInt.zero) return true;

    final smartAddress =
        smartAddressesByEoa[eoa.with0x.toLowerCase()] ??
        smartAddressesByEoa[eoa.eip55With0x.toLowerCase()];
    if (smartAddress == null) return false;

    final smartKey = smartAddress.with0x.toLowerCase();
    if (usedSmartAddresses.contains(smartKey)) return true;

    final smartNonce = await client.getTransactionCount(smartAddress);
    final smartBalance = await client.getBalance(smartAddress);
    return smartNonce > 0 || smartBalance.getInWei > BigInt.zero;
  }
}

class _FakeWeb3Client extends Fake implements Web3Client {
  final Map<String, int> nonces; // address → nonce
  final Map<String, BigInt> balances; // address → balance

  _FakeWeb3Client({this.nonces = const {}, this.balances = const {}});

  @override
  Future<int> getTransactionCount(
    bip.EthereumAddress address, {
    BlockNum? atBlock,
  }) async {
    return nonces[address.eip55With0x] ?? nonces[address.with0x] ?? 0;
  }

  @override
  Future<bip.EtherAmount> getBalance(
    bip.EthereumAddress address, {
    BlockNum? atBlock,
  }) async {
    final bal =
        balances[address.eip55With0x] ??
        balances[address.with0x] ??
        BigInt.zero;
    return bip.EtherAmount.inWei(bal);
  }
}

class _FakeEvm extends Fake implements Evm {
  @override
  final List<EvmChain> configuredChains;

  _FakeEvm(this.configuredChains);
}

class _FakeOrders extends Fake implements Orders {
  /// tradeIds that "exist" — will return a non-empty list.
  final Set<String> existingTradeIds;

  _FakeOrders({this.existingTradeIds = const {}});

  @override
  Future<List<Order>> getByTradeId(String tradeId) async {
    if (existingTradeIds.contains(tradeId)) {
      // Return a non-empty list to signal "trade exists".
      return [_dummyOrder];
    }
    return [];
  }
}

class _FakeOrder extends Fake implements Order {}

final _dummyOrder = _FakeOrder();

class _FakeThreads extends Fake implements Threads {
  final Set<String> existingTradeIds;
  @override
  final StreamWithStatus<Nip01Event> events$ = StreamWithStatus<Nip01Event>()
    ..addStatus(StreamStatusLive());

  _FakeThreads({this.existingTradeIds = const {}});

  @override
  List<Thread> findByConversationTag(String tag) =>
      existingTradeIds.contains(tag) ? [_FakeThread()] : [];
}

class _FakeThread extends Fake implements Thread {}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  late _FakeAuth auth;
  late _FakeDeterministicKeys hd;
  late _FakeWeb3Client web3;
  late _FakeEvm evm;
  late _FakeOrders orders;
  late CustomLogger logger;
  late TradeAccountCache cache;
  late TradeAccountAllocatorImpl allocator;

  setUp(() {
    auth = _FakeAuth(keyPair: KeyPair('ccdd' * 8, 'aabb' * 8, null, null));
    hd = _FakeDeterministicKeys();
    web3 = _FakeWeb3Client();
    evm = _FakeEvm([_FakeEvmChain(web3)]);
    orders = _FakeOrders();
    logger = CustomLogger();
    cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
    allocator = TradeAccountAllocatorImpl(
      auth: auth,
      hd: hd,
      evm: evm,
      orders: orders,
      threads: _FakeThreads(),
      cache: cache,
      logger: logger,
    );
  });

  group('reserveNextTradeIndex', () {
    test('returns 1 when maxAccountIndex is -1 and no collisions', () async {
      final index = await allocator.reserveNextTradeIndex();
      expect(index, 1);
      expect(auth.storedMaxAccountIndex, 1);
    });

    test('starts at maxAccountIndex + 1', () async {
      auth = _FakeAuth(
        keyPair: KeyPair('ccdd' * 8, 'aabb' * 8, null, null),
        maxAccountIndex: 4,
      );
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.reserveNextTradeIndex();
      expect(index, 5);
    });

    test('skips indices with existing trades', () async {
      // Index 1 has an existing trade.
      hd = _FakeDeterministicKeys(tradeIds: {1: 'taken-trade'});
      orders = _FakeOrders(existingTradeIds: {'taken-trade'});
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.reserveNextTradeIndex();
      expect(index, 2); // skipped trade index 1
    });

    test('skips indices with existing trade thread', () async {
      hd = _FakeDeterministicKeys(tradeIds: {1: 'taken-trade'});
      final threads = _FakeThreads(existingTradeIds: {'taken-trade'});
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: threads,
        cache: cache,
        logger: logger,
      );

      final index = await allocator.reserveNextTradeIndex();
      expect(index, 2);
    });

    test('skips indices with used EVM addresses (nonce > 0)', () async {
      final usedAddress = bip.EthereumAddress.fromHex(
        '0x${1.toRadixString(16).padLeft(40, '0')}',
      );
      hd = _FakeDeterministicKeys(evmAddresses: {1: usedAddress});
      web3 = _FakeWeb3Client(nonces: {usedAddress.with0x: 1});
      evm = _FakeEvm([_FakeEvmChain(web3)]);
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.reserveNextTradeIndex();
      expect(index, 2); // skipped trade index 1
    });

    test('skips indices with used EVM addresses (balance > 0)', () async {
      final usedAddress = bip.EthereumAddress.fromHex(
        '0x${1.toRadixString(16).padLeft(40, '0')}',
      );
      hd = _FakeDeterministicKeys(evmAddresses: {1: usedAddress});
      web3 = _FakeWeb3Client(balances: {usedAddress.with0x: BigInt.from(1000)});
      evm = _FakeEvm([_FakeEvmChain(web3)]);
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.reserveNextTradeIndex();
      expect(index, 2); // skipped trade index 1
    });

    test('skips indices with used AA smart accounts', () async {
      final eoaAddress = bip.EthereumAddress.fromHex(
        '0x${1.toRadixString(16).padLeft(40, '0')}',
      );
      final smartAddress = bip.EthereumAddress.fromHex(
        '0x${101.toRadixString(16).padLeft(40, '0')}',
      );
      hd = _FakeDeterministicKeys(evmAddresses: {1: eoaAddress});
      web3 = _FakeWeb3Client();
      evm = _FakeEvm([
        _FakeEvmChain(
          web3,
          smartAddressesByEoa: {eoaAddress.with0x.toLowerCase(): smartAddress},
          usedSmartAddresses: {smartAddress.with0x.toLowerCase()},
        ),
      ]);
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.reserveNextTradeIndex();
      expect(index, 2);
    });

    test('updates maxAccountIndex via Auth', () async {
      await allocator.reserveNextTradeIndex();
      expect(auth.storedMaxAccountIndex, 1);
    });
  });

  group('findTradeAccountIndexByTradeId', () {
    test('returns matching index', () async {
      hd = _FakeDeterministicKeys(tradeIds: {3: 'target-id'});
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.findTradeAccountIndexByTradeId('target-id');
      expect(index, 3);
    });

    test('throws StateError when no match found', () async {
      expect(
        () => allocator.findTradeAccountIndexByTradeId('nonexistent'),
        throwsStateError,
      );
    });
  });

  group('tryFindTradeAccountIndexByTradeId', () {
    test('returns index on match', () async {
      hd = _FakeDeterministicKeys(tradeIds: {7: 'found-it'});
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.tryFindTradeAccountIndexByTradeId(
        'found-it',
      );
      expect(index, 7);
    });

    test('finds owned order trade outside the first scanned batch', () async {
      hd = _FakeDeterministicKeys(tradeIds: {42: 'old-order'});
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.tryFindTradeAccountIndexByTradeId(
        'old-order',
      );

      expect(index, 42);
      expect(auth.storedMaxAccountIndex, 42);
      expect(hd.tradeIdLookups, contains(42));
    });

    test(
      'extends tradeId cache after persisted maxAccountIndex grows',
      () async {
        auth = _FakeAuth(
          keyPair: KeyPair('ccdd' * 8, 'aabb' * 8, null, null),
          maxAccountIndex: 1,
        );
        hd = _FakeDeterministicKeys(tradeIds: {3: 'later-order'});
        cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
        allocator = TradeAccountAllocatorImpl(
          auth: auth,
          hd: hd,
          evm: evm,
          orders: orders,
          threads: _FakeThreads(),
          cache: cache,
          logger: logger,
        );

        expect(
          await allocator.tryFindTradeAccountIndexByTradeId(
            'missing',
            maxScan: 1,
          ),
          isNull,
        );

        await auth.updateMaxAccountIndex(3);

        final index = await allocator.tryFindTradeAccountIndexByTradeId(
          'later-order',
          maxScan: 1,
        );

        expect(index, 3);
        expect(auth.storedMaxAccountIndex, 3);
      },
    );

    test('returns null when no match', () async {
      final index = await allocator.tryFindTradeAccountIndexByTradeId(
        'missing',
      );
      expect(index, isNull);
    });

    test('stops a foreign trade id lookup at a large bounded scan', () async {
      const scanLimit = 4096;
      hd = _FakeDeterministicKeys();
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      final index = await allocator.tryFindTradeAccountIndexByTradeId(
        'foreign-trade-id',
        maxScan: scanLimit,
      );

      expect(index, isNull);
      expect(hd.tradeIdLookups.length, scanLimit);
      expect(hd.tradeIdLookups.first, 0);
      expect(hd.tradeIdLookups.last, scanLimit - 1);
      expect(hd.tradeIdLookups, isNot(contains(scanLimit)));
    });

    test('yields to the event queue while scanning misses', () async {
      var timerFired = false;
      Timer.run(() {
        timerFired = true;
      });

      final index = await allocator.tryFindTradeAccountIndexByTradeId(
        'missing',
        maxScan: 3,
      );

      expect(index, isNull);
      expect(timerFired, isTrue);
    });
  });

  group('getReservedTradeIndices', () {
    test('returns empty list when no active key pair', () {
      auth = _FakeAuth();
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      expect(allocator.getReservedTradeIndices(), isEmpty);
    });

    test('returns empty list when maxAccountIndex < 0', () {
      expect(allocator.getReservedTradeIndices(), isEmpty);
    });

    test('returns [1..maxAccountIndex] when maxAccountIndex >= 1', () async {
      auth = _FakeAuth(
        keyPair: KeyPair('ccdd' * 8, 'aabb' * 8, null, null),
        maxAccountIndex: 3,
      );
      cache = TradeAccountCache(auth: auth, hd: hd, logger: logger);
      allocator = TradeAccountAllocatorImpl(
        auth: auth,
        hd: hd,
        evm: evm,
        orders: orders,
        threads: _FakeThreads(),
        cache: cache,
        logger: logger,
      );

      expect(allocator.getReservedTradeIndices(), [1, 2, 3]);
    });
  });
}
