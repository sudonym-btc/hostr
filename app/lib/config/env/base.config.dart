import 'dart:math';

abstract class Config {
  List<String> get relays;
  List<String> get blossom;
  String get hostrRelay => 'wss://relay.hostr.network';
  String get rootstockRpcUrl => 'https://public-node.testnet.rsk.co';
  String get boltzUrl => 'https://api.testnet.boltz.exchange/v2';
  String get googleMapsApiKey => 'AIzaSyBjcePUwkKwD-iMmHpjXVDV0MaiYH1dnGo';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();
}
