import 'dart:math';

abstract class Config {
  List<String> get relays;
  List<String> get blossom;
  String get hostrRelay => 'wss://relay.hostr.network';
  String get rootstockRpcUrl => 'https://public-node.testnet.rsk.co';
  String get rifRelayUrl => 'http://localhost:8090';
  String get rifRelayCallVerifier =>
      '0x3Aa5ebB10DC797CAC828524e59A333d0A371443c';
  String get rifSmartWalletFactoryAddress =>
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';
  String get boltzUrl => 'https://api.testnet.boltz.exchange/v2';
  String get googleMapsApiKey => 'AIzaSyBjcePUwkKwD-iMmHpjXVDV0MaiYH1dnGo';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();
}
