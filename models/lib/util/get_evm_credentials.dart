import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';

EthPrivateKey getEvmCredentials(String nostrPrivateKey) {
  return EthPrivateKey.fromHex(hex.encode(hex.decode(nostrPrivateKey)));
}
