import 'package:models/stubs/escrow.dart';
import 'package:models/stubs/escrow_trust.dart';
import 'package:models/stubs/gift_wrap.dart';
import 'package:models/stubs/listing.dart';
import 'package:models/stubs/profile.dart';
import 'package:models/stubs/reservation.dart';
import 'package:models/stubs/review.dart';

export 'escrow.dart';
export 'escrow_trust.dart';
export 'gift_wrap.dart';
export 'keypairs.dart';
export 'listing.dart';
export 'profile.dart';
export 'reservation.dart';
export 'reservation_request.dart';
export 'review.dart';
export 'thread/main.dart';

var MOCK_EVENTS = [
  ...MOCK_ESCROW_TRUSTS.map((i) => i.nip01Event),
  ...MOCK_ESCROWS.map((i) => i.nip01Event),
  ...MOCK_LISTINGS.map((i) => i.nip01Event),
  ...MOCK_RESERVATIONS.map((i) => i.nip01Event),
  ...MOCK_GIFT_WRAPS.map((i) => i.nip01Event),
  ...MOCK_PROFILES,
  ...MOCK_REVIEWS.map((i) => i.nip01Event)
];
