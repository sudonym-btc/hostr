import 'package:faker/faker.dart';
import 'package:models/stubs/escrow_service.dart';
import 'package:ndk/ndk.dart';

export 'escrow_service.dart';
export 'keypairs.dart';

final faker = Faker(seed: 1);

Future<List<Nip01Event>> MOCK_EVENTS(
    {required String contractAddress, String? byteCodeHash}) async {
  return [
    ...MOCK_ESCROWS(
        contractAddress: contractAddress, byteCodeHash: byteCodeHash),
  ];
}
