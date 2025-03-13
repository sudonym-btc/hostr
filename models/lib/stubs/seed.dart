import 'dart:io';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

seed(String relayUrl) async {
  print("Seeding $relayUrl...");
  Ndk ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relayUrl]));

  for (var x in MOCK_EVENTS) {
    await ndk.broadcast.broadcast(nostrEvent: x);
  }

  print('Seeded.');
  exit(0);
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Please provide a relay URL.');
    return;
  }

  String relayUrl = arguments[0];
  await seed(relayUrl);
}
