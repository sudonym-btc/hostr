import 'package:faker/faker.dart';
import 'package:models/stubs/badge.dart';
import 'package:models/stubs/blossom.dart';
import 'package:models/stubs/escrow_method.dart';
import 'package:models/stubs/escrow_service.dart';
import 'package:models/stubs/gift_wrap.dart';
import 'package:models/stubs/listing.dart';
import 'package:models/stubs/profile.dart';
import 'package:models/stubs/reservation.dart';
import 'package:models/stubs/review.dart';
import 'package:models/stubs/zap_receipt.dart';
import 'package:ndk/ndk.dart';

import 'escrow_trust.dart';

export 'badge.dart';
export 'blossom.dart';
export 'escrow_method.dart';
export 'escrow_service.dart';
export 'escrow_trust.dart';
export 'gift_wrap.dart';
export 'keypairs.dart';
export 'listing.dart';
export 'mocks/reservations/reservation_scenario.dart';
export 'mocks/reservations/reservation_scenarios.dart';
export 'mocks/threads/thread_scenario.dart';
export 'mocks/threads/thread_scenarios.dart';
export 'profile.dart';
export 'reservation.dart';
export 'reservation_request.dart';
export 'review.dart';
export 'zap_receipt.dart';

final faker = Faker(seed: 1);

Future<List<Nip01Event>> MOCK_EVENTS(
    {String? contractAddress, String? byteCodeHash}) async {
  return [
    ...await MOCK_ESCROW_TRUSTS(),
    ...MOCK_ESCROWS(
        contractAddress: contractAddress, byteCodeHash: byteCodeHash),
    ...await MOCK_ESCROW_METHODS(),
    ...MOCK_LISTINGS,
    ...FAKED_LISTINGS,
    ...MOCK_RESERVATIONS,
    ...FAKED_RESERVATIONS,
    ...await MOCK_GIFT_WRAPS(),
    ...MOCK_PROFILES,
    ...FAKED_PROFILES,
    ...MOCK_REVIEWS,
    ...MOCK_ZAP_RECEIPTS,
    ...MOCK_BLOSSOM_SERVER_LISTS,
    ...MOCK_BADGE_DEFINITIONS,
    ...MOCK_BADGE_AWARDS,
  ];
}
