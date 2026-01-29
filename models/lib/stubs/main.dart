import 'package:models/stubs/badge.dart';
import 'package:models/stubs/blossom.dart';
import 'package:models/stubs/escrow.dart';
import 'package:models/stubs/escrow_method.dart';
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
export 'escrow.dart';
export 'escrow_method.dart';
export 'escrow_trust.dart';
export 'gift_wrap.dart';
export 'keypairs.dart';
export 'listing.dart';
export 'profile.dart';
export 'reservation.dart';
export 'reservation_request.dart';
export 'review.dart';
export 'thread/main.dart';
export 'zap_receipt.dart';

Future<List<Nip01Event>> MOCK_EVENTS({String? contractAddress}) async {
  return [
    ...await MOCK_ESCROW_TRUSTS(),
    ...MOCK_ESCROWS(contractAddress: contractAddress),
    ...await MOCK_ESCROW_METHODS(),
    ...MOCK_LISTINGS,
    ...MOCK_RESERVATIONS,
    ...await MOCK_GIFT_WRAPS(),
    ...MOCK_PROFILES,
    ...MOCK_REVIEWS,
    ...MOCK_ZAP_RECEIPTS,
    ...MOCK_BLOSSOM_SERVER_LISTS,
    ...MOCK_BADGE_DEFINITIONS,
    ...MOCK_BADGE_AWARDS,
  ];
}
