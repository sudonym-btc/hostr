import 'package:models/main.dart';

class BookAndPayInput {
  const BookAndPayInput({
    required this.listingAnchor,
    required this.start,
    required this.end,
    this.amount,
    this.escrowServiceId,
    this.proofTimeout = const Duration(minutes: 5),
  });

  final String listingAnchor;
  final DateTime start;
  final DateTime end;
  final DenominatedAmount? amount;
  final String? escrowServiceId;
  final Duration proofTimeout;
}
