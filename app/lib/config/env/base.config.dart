import 'dart:math';

abstract class Config {
  List<String> get relays;
  List<String> get blossom;
  String get hostrRelay => 'wss://relay.hostr.network';
  RootstockConfig get rootstock;
  String get googleMapsApiKey => 'AIzaSyBjcePUwkKwD-iMmHpjXVDV0MaiYH1dnGo';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();
}

abstract class EvmConfig {
  int get chainId;
  String get rpcUrl;
}

abstract class RootstockConfig extends EvmConfig {
  BoltzConfig get boltz;
}

abstract class BoltzConfig {
  String get apiUrl;
  String get wsUrl => '${apiUrl.replaceFirst('http', 'ws')}/ws';

  String get rifRelayUrl;
  String get rifRelayCallVerifier;
  String get rifRelayDeployVerifier;
  String get rifSmartWalletFactoryAddress;
}
