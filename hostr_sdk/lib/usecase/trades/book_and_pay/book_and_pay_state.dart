import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01EventModel;

import '../../evm/operations/swap_in/swap_in_state.dart';

sealed class BookAndPayState {
  const BookAndPayState();

  String get stateName;
  bool get isTerminal => false;

  Map<String, Object?> toJson();
}

class BookAndPayInitial extends BookAndPayState {
  const BookAndPayInitial();

  @override
  String get stateName => 'initialised';

  @override
  Map<String, Object?> toJson() => {'state': stateName, 'isTerminal': false};
}

class BookAndPayValidating extends BookAndPayState {
  const BookAndPayValidating({required this.listingAnchor});

  final String listingAnchor;

  @override
  String get stateName => 'validating';

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': false,
    'listingAnchor': listingAnchor,
  };
}

class BookAndPayOfferPublished extends BookAndPayState {
  const BookAndPayOfferPublished({
    required this.tradeId,
    required this.listing,
    required this.order,
    required this.relayResponses,
  });

  final String tradeId;
  final Listing listing;
  final Order order;
  final List<Map<String, Object?>> relayResponses;

  @override
  String get stateName => 'offerPublished';

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': false,
    'tradeId': tradeId,
    'listing': _listingJson(listing),
    'order': _eventJson(order),
    'relayResponses': relayResponses,
  };
}

class BookAndPayEscrowSelected extends BookAndPayState {
  const BookAndPayEscrowSelected({
    required this.tradeId,
    required this.selectedEscrow,
    required this.relayResponses,
  });

  final String tradeId;
  final EscrowServiceSelected selectedEscrow;
  final List<Map<String, Object?>> relayResponses;

  @override
  String get stateName => 'escrowSelected';

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': false,
    'tradeId': tradeId,
    'selectedEscrow': _eventJson(selectedEscrow),
    'relayResponses': relayResponses,
  };
}

class BookAndPaySwapState extends BookAndPayState {
  const BookAndPaySwapState({required this.tradeId, required this.swapState});

  final String tradeId;
  final SwapInState swapState;

  @override
  String get stateName => 'swap.${swapState.stateName}';

  @override
  bool get isTerminal => swapState.isTerminal;

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': swapState.isTerminal,
    'tradeId': tradeId,
    'swapState': swapState.toJson(),
    if (swapState.data?.boltzId != null) 'swapId': swapState.data!.boltzId,
  };
}

class BookAndPayAwaitingOrderProof extends BookAndPayState {
  const BookAndPayAwaitingOrderProof({
    required this.tradeId,
    required this.swapId,
    required this.claimTxHash,
  });

  final String tradeId;
  final String swapId;
  final String claimTxHash;

  @override
  String get stateName => 'awaitingOrderProof';

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': false,
    'tradeId': tradeId,
    'swapId': swapId,
    'claimTxHash': claimTxHash,
  };
}

class BookAndPayCompleted extends BookAndPayState {
  const BookAndPayCompleted({
    required this.tradeId,
    required this.swapId,
    required this.order,
  });

  final String tradeId;
  final String swapId;
  final Order order;

  @override
  String get stateName => 'completed';

  @override
  bool get isTerminal => true;

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': true,
    'tradeId': tradeId,
    'swapId': swapId,
    'order': _eventJson(order),
  };
}

class BookAndPayFailed extends BookAndPayState {
  const BookAndPayFailed(this.error, {this.details});

  final String error;
  final Map<String, Object?>? details;

  @override
  String get stateName => 'failed';

  @override
  bool get isTerminal => true;

  @override
  Map<String, Object?> toJson() => {
    'state': stateName,
    'isTerminal': true,
    'error': error,
    if (details != null) 'details': details,
  };
}

Map<String, Object?> _eventJson(Nip01Event event) =>
    Nip01EventModel.fromEntity(event).toJson();

Map<String, Object?> _amountJson(DenominatedAmount amount) => {
  'value': amount.toDecimalString(),
  'smallestUnitValue': amount.value.toString(),
  'denomination': amount.denomination,
  'decimals': amount.decimals,
};

Map<String, Object?> _listingJson(Listing listing) => {
  'id': listing.id,
  'anchor': listing.anchor,
  'pubkey': listing.pubKey,
  'title': listing.title,
  'description': listing.description,
  'active': listing.active,
  'autoAccept': listing.autoAccept,
  'type': listing.listingType.name,
  'images': listing.images,
  'prices': listing.prices
      .map(
        (price) => {
          'amount': _amountJson(price.amount),
          if (price.frequency != null) 'frequency': price.frequency!.name,
        },
      )
      .toList(),
};
