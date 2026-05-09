import 'package:escrow/env_config.dart';
import 'package:test/test.dart';

void main() {
  group('EnvConfig.sdkEnvironment', () {
    test('maps local compose profiles to dev', () {
      expect(EnvConfig.sdkEnvironment('local,seed,ci'), 'dev');
    });

    test('maps compose integration test profiles to dev', () {
      expect(EnvConfig.sdkEnvironment('test,ci'), 'dev');
    });

    test('keeps hosted environments', () {
      expect(EnvConfig.sdkEnvironment('staging'), 'staging');
      expect(EnvConfig.sdkEnvironment('prod'), 'prod');
      expect(EnvConfig.sdkEnvironment('production'), 'prod');
    });

    test('keeps test and mock environments', () {
      expect(EnvConfig.sdkEnvironment('test'), 'test');
      expect(EnvConfig.sdkEnvironment('mock'), 'mock');
    });
  });

  group('EnvConfig.forEnvironment', () {
    test('includes public bootstrap relays for staging legacy DMs', () {
      final config = EnvConfig.forEnvironment('staging');

      expect(config.relayUrl, 'wss://relay.staging.hostr.network');
      expect(config.bootstrapRelays, contains('wss://relay.primal.net'));
      expect(config.bootstrapRelays, contains('wss://relay.damus.io'));
    });

    test('includes public bootstrap relays for production legacy DMs', () {
      final config = EnvConfig.forEnvironment('prod');

      expect(config.relayUrl, 'wss://relay.hostr.network');
      expect(config.bootstrapRelays, contains('wss://relay.primal.net'));
      expect(config.bootstrapRelays, contains('wss://nos.lol'));
    });
  });
}
