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
}
