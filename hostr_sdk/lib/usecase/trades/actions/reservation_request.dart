import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../trade.dart';
import '../trade_state.dart';
import 'trade_action_resolver.dart';

@injectable
class ReservationRequestActions {
  final Trade trade;

  ReservationRequestActions({required this.trade});

  static List<TradeAction> resolve(
    List<Reservation> reservationRequests,
    Listing listing,
    String ourPubkey,
    TradeRole role,
  ) {
    final policy = resolvePolicy(reservationRequests, listing, ourPubkey, role);
    final actions = <TradeAction>[];
    final latestOffer = reservationRequests.isNotEmpty
        ? reservationRequests.last
        : null;
    final latestOfferSentByUs = latestOffer?.pubKey == ourPubkey;
    final latestOfferIsBelowListing =
        latestOffer != null &&
        policy.listingPrice != null &&
        latestOffer.amount != null &&
        latestOffer.amount!.currency == policy.listingPrice!.currency &&
        latestOffer.amount!.value < policy.listingPrice!.value;

    if (role == TradeRole.host &&
        latestOffer != null &&
        !latestOfferSentByUs &&
        latestOfferIsBelowListing) {
      actions.add(TradeAction.accept);
    }
    if (policy.canCounter) actions.add(TradeAction.counter);
    if (policy.canPay) actions.add(TradeAction.pay);

    return actions;
  }

  static NegotiationPolicy resolvePolicy(
    List<Reservation> reservationRequests,
    Listing listing,
    String ourPubkey,
    TradeRole role,
  ) {
    final latestOffer = reservationRequests.isNotEmpty
        ? reservationRequests.last
        : null;
    final lastOfferByUs = _lastOfferByPubkey(reservationRequests, ourPubkey);
    final lastOfferByThem = latestOffer == null
        ? null
        : _lastOfferByOtherPubkey(reservationRequests, ourPubkey);
    final listingPrice = latestOffer != null
        ? listing.cost(latestOffer.start, latestOffer.end)
        : null;
    final latestOfferSentByUs = latestOffer?.pubKey == ourPubkey;
    final latestOfferAcceptsPrevious = _isAcceptedCounterpartOffer(
      latestOffer: latestOffer,
      lastOfferByUs: lastOfferByUs,
      latestOfferSentByUs: latestOfferSentByUs,
      role: role,
    );

    var canPay = false;
    var canCounter = false;
    Amount? counterMin;
    Amount? counterMax;

    if (latestOffer != null &&
        listingPrice != null &&
        latestOffer.amount != null) {
      final latestAmount = latestOffer.amount!;
      final latestMeetsListing = latestAmount.value >= listingPrice.value;

      if (role == TradeRole.guest) {
        canPay = !latestOfferSentByUs || latestMeetsListing;
      }

      if (!latestOfferSentByUs &&
          listing.allowBarter &&
          !latestOfferAcceptsPrevious) {
        canCounter = true;
        switch (role) {
          case TradeRole.host:
            counterMin = _incrementAmount(latestAmount);
            counterMax = listingPrice;
          case TradeRole.guest:
            final lowerBound = _maxAmount([
              latestAmount,
              if (lastOfferByUs?.amount != null) lastOfferByUs!.amount!,
            ]);
            final upperBound = _maxAmount([
              listingPrice,
              if (lastOfferByThem?.amount != null) lastOfferByThem!.amount!,
            ]);
            counterMin = lowerBound != null
                ? _incrementAmount(lowerBound)
                : null;
            counterMax = upperBound;
        }
      }
    }

    if (counterMin != null &&
        counterMax != null &&
        counterMin.currency == counterMax.currency &&
        counterMin.value > counterMax.value) {
      canCounter = false;
    }

    return NegotiationPolicy(
      latestOffer: latestOffer,
      lastOfferByUs: lastOfferByUs,
      lastOfferByThem: lastOfferByThem,
      listingPrice: listingPrice,
      latestOfferSentByUs: latestOfferSentByUs,
      latestOfferAcceptsPrevious: latestOfferAcceptsPrevious,
      canPay: canPay,
      canCounter: canCounter,
      counterMin: canCounter ? counterMin : null,
      counterMax: canCounter ? counterMax : null,
    );
  }

  static Reservation? _lastOfferByPubkey(
    List<Reservation> reservationRequests,
    String pubkey,
  ) {
    for (final request in reservationRequests.reversed) {
      if (request.pubKey == pubkey) return request;
    }
    return null;
  }

  static Reservation? _lastOfferByOtherPubkey(
    List<Reservation> reservationRequests,
    String pubkey,
  ) {
    for (final request in reservationRequests.reversed) {
      if (request.pubKey != pubkey) return request;
    }
    return null;
  }

  static bool _isAcceptedCounterpartOffer({
    required Reservation? latestOffer,
    required Reservation? lastOfferByUs,
    required bool latestOfferSentByUs,
    required TradeRole role,
  }) {
    if (role != TradeRole.guest || latestOffer == null || latestOfferSentByUs) {
      return false;
    }

    final latestAmount = latestOffer.amount;
    final previousOwnAmount = lastOfferByUs?.amount;
    if (latestAmount == null || previousOwnAmount == null) {
      return false;
    }

    return latestAmount.currency == previousOwnAmount.currency &&
        latestAmount.value == previousOwnAmount.value;
  }

  static Amount _incrementAmount(Amount amount) =>
      Amount(value: amount.value + BigInt.one, currency: amount.currency);

  static Amount? _maxAmount(List<Amount> amounts) {
    if (amounts.isEmpty) return null;
    var max = amounts.first;
    for (final amount in amounts.skip(1)) {
      if (amount.currency == max.currency && amount.value > max.value) {
        max = amount;
      }
    }
    return max;
  }

  Future<void> counter() async {
    throw UnimplementedError(
      'Countering reservation requests is not implemented yet',
    );
  }
}
