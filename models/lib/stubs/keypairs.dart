import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class MockKeys {
  static final KeyPair nwc = Bip340.fromPrivateKey(
      'a4006daa118c9898abaac3f9a49c9012fe8bb82d360c38abd99fe708561b56a4');
  static final KeyPair nwcSecret = Bip340.fromPrivateKey(
      '76d39017936462023a8ac45e45ff769e1007b0726f9163c857a4669f23b88766');
  static final KeyPair hoster = Bip340.fromPrivateKey(
      '556f19cc663fa7ff6840e6b6dc4ab244e8e952161f116b06d04c76cba659b980');
  static final KeyPair guest = Bip340.fromPrivateKey(
      '1714ff69753ae70a91d6e1989cb1ee859b10e98239c61d28bcb0577d8d626b74');
  static final KeyPair escrow = Bip340.fromPrivateKey(
      'a9cbe715ebaeb852bf7cc3d35f4a81b9a58f16705e4bb8434aa453093e612206');
  static final KeyPair reviewer = Bip340.fromPrivateKey(
      '5d12e1c259280034770db6dfe14609fca9c10b97c7ce79f0a32cd80b118ce9c3');
}

final List<KeyPair> mockKeys = List.generate(100, (int) {
  return Bip340.fromPrivateKey(faker.crypto.privateKey());
});

void main() {
  KeyPair keys = Bip340.generatePrivateKey();
  print(keys.privateKey);
}
