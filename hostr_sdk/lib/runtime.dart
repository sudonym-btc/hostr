import 'dart:async';

import 'config.dart';
import 'datasources/storage.dart';
import 'hostr.dart';
import 'injection.dart' show Env;
import 'usecase/main.dart';

class PrefixedKeyValueStorage implements KeyValueStorage {
  final KeyValueStorage _inner;
  final String _prefix;

  PrefixedKeyValueStorage(this._inner, String prefix)
    : _prefix = prefix.endsWith('/') ? prefix : '$prefix/';

  String _key(String key) => '$_prefix$key';

  @override
  Future<void> delete(String key) => _inner.delete(_key(key));

  @override
  Future<dynamic> read(String key) => _inner.read(_key(key));

  @override
  Future<void> write(String key, dynamic value) =>
      _inner.write(_key(key), value);
}

class HostrRuntime {
  final HostrConfig config;
  final String environment;
  final Map<String, HostrSession> _sessions = {};
  HostrSession? _foregroundSession;

  HostrRuntime({required this.config, this.environment = Env.prod});

  Future<HostrSession> foregroundSession() async {
    return _foregroundSession ??= HostrSession._(
      runtime: this,
      pubkey: null,
      hostr: Hostr(config: config, environment: environment),
    );
  }

  HostrSession session(String pubkey) {
    final normalized = pubkey.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(pubkey, 'pubkey', 'must not be empty');
    }

    return _sessions.putIfAbsent(normalized, () {
      final sessionConfig = config.copyWith(
        storage: PrefixedKeyValueStorage(
          config.keyValueStorage,
          'hostr-session/$normalized',
        ),
      );
      return HostrSession._(
        runtime: this,
        pubkey: normalized,
        hostr: Hostr(config: sessionConfig, environment: environment),
      );
    });
  }

  Future<void> dispose() async {
    final sessions = [?_foregroundSession, ..._sessions.values];
    _foregroundSession = null;
    _sessions.clear();
    await Future.wait(sessions.map((session) => session.dispose()));
  }
}

class HostrSession {
  final HostrRuntime runtime;
  final String? pubkey;
  final Hostr hostr;
  Future<void>? _initialization;

  HostrSession._({
    required this.runtime,
    required this.pubkey,
    required this.hostr,
  });

  Auth get auth => hostr.auth;
  Requests get requests => hostr.requests;
  MetadataUseCase get metadata => hostr.metadata;
  Nwc get nwc => hostr.nwc;
  Zaps get zaps => hostr.zaps;
  Listings get listings => hostr.listings;
  LnurlUseCase get lnurl => hostr.lnurl;
  Location get location => hostr.location;
  Reservations get orderWorkflows => hostr.orderWorkflows;
  OrderGroupVerification get orderGroupVerification =>
      hostr.orderGroupVerification;
  GiftWraps get giftWraps => hostr.giftWraps;
  DmRelays get dmRelays => hostr.dmRelays;
  EscrowUseCase get escrow => hostr.escrow;
  Escrows get escrows => hostr.escrows;
  EscrowMethods get escrowMethods => hostr.escrowMethods;
  BadgeDefinitions get badgeDefinitions => hostr.badgeDefinitions;
  BadgeAwards get badgeAwards => hostr.badgeAwards;
  Messaging get messaging => hostr.messaging;
  ReservationRequests get reservationRequests => hostr.reservationRequests;
  Payments get payments => hostr.payments;
  Reviews get reviews => hostr.reviews;
  TradeAccountAllocator get tradeAccountAllocator =>
      hostr.tradeAccountAllocator;
  TradeAudit get tradeAudit => hostr.tradeAudit;
  Evm get evm => hostr.evm;
  Relays get relays => hostr.relays;
  Verification get verification => hostr.verification;
  BlossomUseCase get blossom => hostr.blossom;
  UserConfigStore get userConfig => hostr.userConfig;
  FundsMonitorService get fundsMonitor => hostr.fundsMonitor;
  OperationStateStore get operationStateStore => hostr.operationStateStore;
  SwapInTracker get swapInTracker => hostr.swapInTracker;
  SwapOutTracker get swapOutTracker => hostr.swapOutTracker;
  BackgroundWorker get backgroundWorker => hostr.backgroundWorker;
  Heartbeats get heartbeats => hostr.heartbeats;
  IdentityClaimsUseCase get identityClaims => hostr.identityClaims;
  UserSubscriptions get userSubscriptions => hostr.userSubscriptions;
  EscrowDaemon get escrowDaemon => hostr.escrowDaemon;
  AccountSeedStore get accountSeedStore => hostr.accountSeedStore;
  PaymentProofOrchestrator get paymentProofOrchestrator =>
      hostr.paymentProofOrchestrator;
  Calendar get calendar => hostr.calendar;
  StartupCoordinator get startup => hostr.startup;

  Future<void> ensureInitialized() {
    return _initialization ??= hostr.initAuth();
  }

  Trade trade(String tradeId, Iterable<String> participants) {
    return hostr.trade(tradeId, participants);
  }

  Future<void> dispose() => hostr.dispose();
}
