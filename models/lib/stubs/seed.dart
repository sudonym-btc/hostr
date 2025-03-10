import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

seed(String relayUrl) async {
  print("Seeding...");
  Ndk ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: []));

  for (var x in MOCK_EVENTS) {
    await ndk.broadcast.broadcast(nostrEvent: x);
  }

  print('Seeded.');
}

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Please provide a relay URL.');
    return;
  }

  String relayUrl = arguments[0];
  seed(relayUrl);
}
