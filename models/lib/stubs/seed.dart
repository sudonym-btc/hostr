import 'dart:io';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

seed(String relayUrl, {String? contractAddress}) async {
  print("Seeding $relayUrl...");
  if (contractAddress != null) {
    print("Using contract address: $contractAddress");
  }
  Ndk ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relayUrl]));

  final MOCKED_EVENTS = await MOCK_EVENTS(contractAddress: contractAddress);

  // Seed regular events
  for (var x in MOCKED_EVENTS) {
    var broadcastResult =
        await ndk.broadcast.broadcast(nostrEvent: x).broadcastDoneFuture;
    if (!broadcastResult.first.broadcastSuccessful) {
      throw Exception(
          'Failed to broadcast event: ${broadcastResult.first.msg}, ${x.toString()}');
    }
  }

  print('Seeded ${MOCKED_EVENTS.length} events.');
  exit(0);
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Please provide a relay URL.');
    return;
  }

  String relayUrl = arguments[0];
  String? contractAddress = arguments.length > 1 ? arguments[1] : null;
  await seed(relayUrl, contractAddress: contractAddress);
}
