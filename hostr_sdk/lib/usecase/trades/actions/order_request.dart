import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';

import '../trade.dart';
import '../trade_state.dart';
import 'trade_action_resolver.dart';

@injectable
class OrderRequestActions {
  final Trade trade;

  OrderRequestActions({required this.trade});

  static List<TradeAction> resolve(
    List<Order> orderRequests,
    Listing listing,
    String ourPubkey,
    TradeRole role,
  ) {
    final policy = resolvePolicy(orderRequests, listing, ourPubkey, role);
    final actions = <TradeAction>[];
    final latestOffer = orderRequests.isNotEmpty ? orderRequests.last : null;
    if (latestOffer == null || latestOffer.stage == OrderStage.cancel) {
      return actions;
    }

    actions.add(TradeAction.cancel);

    final latestOfferSentByUs = latestOffer.pubKey == ourPubkey;
    final latestOfferIsBelowListing =
        policy.listingPrice != null &&
        latestOffer.amount != null &&
        latestOffer.amount!.denomination == policy.listingPrice!.denomination &&
        latestOffer.amount!.value < policy.listingPrice!.value;

    if (role == TradeRole.host &&
        !latestOfferSentByUs &&
        latestOfferIsBelowListing) {
      actions.add(TradeAction.accept);
    }
    if (policy.canCounter) actions.add(TradeAction.counter);
    if (policy.canPay) actions.add(TradeAction.pay);

    return actions;
  }

  static NegotiationPolicy resolvePolicy(
    List<Order> orderRequests,
    Listing listing,
    String ourPubkey,
    TradeRole role,
  ) {
    final latestOffer = orderRequests.isNotEmpty ? orderRequests.last : null;
    if (latestOffer?.stage == OrderStage.cancel) {
      return NegotiationPolicy(
        latestOffer: latestOffer,
        lastOfferByUs: null,
        lastOfferByThem: null,
        listingPrice: null,
        latestOfferSentByUs: latestOffer?.pubKey == ourPubkey,
        latestOfferAcceptsPrevious: false,
        canPay: false,
        canCounter: false,
        counterMin: null,
        counterMax: null,
      );
    }

    final lastOfferByUs = _lastOfferByPubkey(orderRequests, ourPubkey);
    final lastOfferByThem = latestOffer == null
        ? null
        : _lastOfferByOtherPubkey(orderRequests, ourPubkey);
    final listingPrice = latestOffer != null
        ? listing.cost(
            start: latestOffer.start,
            end: latestOffer.end,
            quantity: latestOffer.quantity,
          )
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
    DenominatedAmount? counterMin;
    DenominatedAmount? counterMax;

    if (latestOffer != null &&
        listingPrice != null &&
        latestOffer.amount != null) {
      final latestAmount = latestOffer.amount!;
      final latestMeetsListing = latestAmount.value >= listingPrice.value;

      if (role == TradeRole.guest) {
        canPay = !latestOfferSentByUs || latestMeetsListing;
      }

      if (!latestOfferSentByUs &&
          listing.negotiable &&
          !latestOfferAcceptsPrevious) {
        switch (role) {
          case TradeRole.host:
            // Host can only decrease their asking price: min stays just above
            // the guest's latest offer; max is the host's own previous offer
            // (or listing price if this is their first counter).
            canCounter = true;
            counterMin = _incrementAmount(latestAmount);
            counterMax = lastOfferByUs?.amount ?? listingPrice;
          case TradeRole.guest:
            // Guest can only increase their offer toward the host's offer.
            // If the host is already at listing price there is nothing to
            // negotiate — the guest can only pay or walk.
            if (!latestMeetsListing) {
              canCounter = true;
              counterMin = lastOfferByUs != null
                  ? _incrementAmount(lastOfferByUs.amount!)
                  : null;
              counterMax = latestAmount;
            }
        }
      }
    }

    if (counterMin != null &&
        counterMax != null &&
        counterMin.denomination == counterMax.denomination &&
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

  static Order? _lastOfferByPubkey(List<Order> orderRequests, String pubkey) {
    for (final request in orderRequests.reversed) {
      if (request.pubKey == pubkey) return request;
    }
    return null;
  }

  static Order? _lastOfferByOtherPubkey(
    List<Order> orderRequests,
    String pubkey,
  ) {
    for (final request in orderRequests.reversed) {
      if (request.pubKey != pubkey) return request;
    }
    return null;
  }

  static bool _isAcceptedCounterpartOffer({
    required Order? latestOffer,
    required Order? lastOfferByUs,
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

    return latestAmount.denomination == previousOwnAmount.denomination &&
        latestAmount.value == previousOwnAmount.value;
  }

  static DenominatedAmount _incrementAmount(DenominatedAmount amount) =>
      DenominatedAmount(
        value: amount.value + BigInt.one,
        denomination: amount.denomination,
        decimals: amount.decimals,
      );

  Future<void> counter() async {
    throw UnimplementedError(
      'Countering order requests is not implemented yet',
    );
  }
}
