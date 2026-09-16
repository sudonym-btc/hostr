import 'package:injectable/injectable.dart' hide Order;

import 'package:marketplace_evm/usecase/evm/evm.dart';
import '../relays/relays.dart';

@Singleton()
class StartupCore {
  final Relays _relays;
  final Evm _evm;
  Future<void>? _relayReady;
  Future<void>? _evmReady;

  StartupCore({required this._relays, required this._evm});

  Future<void> ensureRelaysReady({
    // Keep this comfortably above the relay reconnect backoff so one unlucky
    // initial miss does not surface a startup error just before the next
    // reconnect attempt would succeed.
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _relayReady ??= _startRelays(timeout).catchError((Object error) {
      _relayReady = null;
      throw error;
    });
  }

  Future<void> _startRelays(Duration timeout) async {
    await _relays.startSeedRelays();
    await _relays.awaitCoreRelay(timeout: timeout);
  }

  Future<void> ensureEvmReady() {
    return _evmReady ??= _evm.init().catchError((Object error) {
      _evmReady = null;
      throw error;
    });
  }

  void resetForRetry() {
    _relayReady = null;
    _evmReady = null;
  }
}
