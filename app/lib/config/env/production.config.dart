import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.prod])
class ProductionConfig extends Config {
  /// Hostr escrow daemon's Nostr pubkey.
  /// Derived from the ESCROW_PRIVATE_KEY in production Secret Manager.
  /// TODO: run ./scripts/escrow-pubkey.sh hostr-production-d3ba05b4
  static const _hostrEscrowPubkey =
      ''; // Set after enabling Secret Manager API on production

  @override
  List<String> get bootstrapEscrowPubkeys => [
    if (_hostrEscrowPubkey.isNotEmpty) _hostrEscrowPubkey,
  ];
  @override
  List<String> relays = ['wss://relay.damus.io'];
  @override
  String get hostrBlossom => 'https://blossom.hostr.network';
  @override
  String get hostrRelay => 'wss://relay.hostr.network';
  @override
  RootstockConfig rootstock = ProductionRootstockConfig();
  @override
  String get googleMapsApiKey => ''; // TODO: deploy production maps infra and set key
}

class ProductionRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 30;
  @override
  String get rpcUrl => 'https://public-node.rsk.co';

  @override
  BoltzConfig get boltz => ProductionBoltzConfig();
}

class ProductionBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://api.boltz.exchange/v2';

  @override
  String get rifRelayUrl => 'https://boltz.mainnet.relay.rifcomputing.net';

  @override
  String get rifRelayCallVerifier =>
      '0xe221608F3FaBbeDfFb7537F8a9001e80654f55C8';

  @override
  String get rifRelayDeployVerifier =>
      '0xc0F5bEF6b20Be41174F826684c663a8635c6A081';

  @override
  String get rifSmartWalletFactoryAddress =>
      '0x44944a80861120B58cc48B066d57cDAf5eC213dd';
}
