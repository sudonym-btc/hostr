import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event;

import '../../auth/auth.dart';
import '../../deterministic_keys/account_seed_store.dart';
import '../../escrow/main.dart';
import '../../escrows/escrows.dart';
import '../../evm/evm.dart';
import '../../evm/operations/swap_in/swap_in_state.dart';
import '../../listings/listings.dart';
import '../../messaging/thread.dart';
import '../../messaging/messaging.dart';
import '../../metadata/metadata.dart';
import '../../order_requests/order_requests.dart';
import '../../orders/orders.dart';
import '../../user_subscriptions/user_subscriptions.dart';
import '../../../util/main.dart';
import '../payment_proof_orchestrator.dart';
import 'book_and_pay_models.dart';
import 'book_and_pay_state.dart';

class BookAndPayOperation extends Cubit<BookAndPayState> {
  BookAndPayOperation({
    required AccountSeedStore accountSeedStore,
    required Auth auth,
    required Listings listings,
    required Orders orders,
    required OrderRequests orderRequests,
    required Messaging messaging,
    required EscrowUseCase escrow,
    required Escrows escrows,
    required MetadataUseCase metadata,
    required Evm evm,
    required UserSubscriptions userSubscriptions,
    required PaymentProofOrchestrator paymentProofOrchestrator,
    required CustomLogger logger,
  }) : _accountSeedStore = accountSeedStore,
       _auth = auth,
       _listings = listings,
       _orders = orders,
       _orderRequests = orderRequests,
       _messaging = messaging,
       _escrow = escrow,
       _escrows = escrows,
       _metadata = metadata,
       _evm = evm,
       _userSubscriptions = userSubscriptions,
       _paymentProofOrchestrator = paymentProofOrchestrator,
       _logger = logger.scope('book-and-pay'),
       super(const BookAndPayInitial());

  final AccountSeedStore _accountSeedStore;
  final Auth _auth;
  final Listings _listings;
  final Orders _orders;
  final OrderRequests _orderRequests;
  final Messaging _messaging;
  final EscrowUseCase _escrow;
  final Escrows _escrows;
  final MetadataUseCase _metadata;
  final Evm _evm;
  final UserSubscriptions _userSubscriptions;
  final PaymentProofOrchestrator _paymentProofOrchestrator;
  final CustomLogger _logger;

  Future<void> execute(BookAndPayInput input) => _logger.span(
    'execute',
    () async {
      try {
        emit(BookAndPayValidating(listingAnchor: input.listingAnchor));

        await _userSubscriptions.start(validateOrderGroups: false);
        await _paymentProofOrchestrator.start();
        await _accountSeedStore.ensureReady();
        await _evm.init();

        final listing = await _requireListing(input.listingAnchor);
        _assertAutoAcceptEligible(listing);
        _assertNotOwnListing(listing);
        await _assertAvailable(listing, input);

        final requiredAmount = listing.cost(start: input.start, end: input.end);
        final offerAmount = input.amount ?? requiredAmount;
        _assertAmountCoversListing(offerAmount, requiredAmount);

        final order = await _orderRequests.createOrderRequest(
          listing: listing,
          startDate: input.start,
          endDate: input.end,
          amount: offerAmount,
        );
        final tradeId = order.getDtag()!;
        _userSubscriptions.trackTradeId(tradeId);

        final offerResponses = await _replyOrderInTradeThread(
          order,
          participants: [listing.pubKey],
        );
        emit(
          BookAndPayOfferPublished(
            tradeId: tradeId,
            listing: listing,
            order: order,
            relayResponses: offerResponses,
          ),
        );

        final plan = await _buildEscrowFundingPlan(
          order: order,
          listing: listing,
          escrowServiceId: input.escrowServiceId,
        );
        final selectionThread = _ensureTradeThread(
          tradeId: tradeId,
          participants: [listing.pubKey],
        );
        final selectionResponses = await _replyOnThread(
          selectionThread,
          plan.selectedEscrow,
        );
        emit(
          BookAndPayEscrowSelected(
            tradeId: tradeId,
            selectedEscrow: plan.selectedEscrow,
            relayResponses: selectionResponses,
          ),
        );

        final swapParams = await plan.preparer.prepare();
        final swap = plan.preparer.configuredChain.swapIn(params: swapParams);
        final swapSub = swap.stream.listen((swapState) {
          if (!isClosed) {
            emit(BookAndPaySwapState(tradeId: tradeId, swapState: swapState));
          }
        });
        try {
          await swap.init();
          await swap.execute();
        } finally {
          await swapSub.cancel();
        }

        final swapState = swap.state;
        emit(BookAndPaySwapState(tradeId: tradeId, swapState: swapState));
        if (swapState is! SwapInCompleted ||
            swapState.data.claimTxHash == null ||
            swapState.data.claimTxHash!.isEmpty) {
          throw StateError('Swap did not complete with an escrow claim proof.');
        }

        emit(
          BookAndPayAwaitingOrderProof(
            tradeId: tradeId,
            swapId: swapState.data.boltzId,
            claimTxHash: swapState.data.claimTxHash!,
          ),
        );
        await _paymentProofOrchestrator.publishEscrowProofForCompletedSwap(
          tradeId: tradeId,
          participants: [_auth.getActiveKey().publicKey, listing.pubKey],
          transactionHash: swapState.data.claimTxHash!,
          escrowService: plan.selectedEscrow,
        );

        final committed = await _waitForMyCommittedOrder(
          tradeId: tradeId,
          sellerPubkey: listing.pubKey,
          timeout: input.proofTimeout,
        );
        emit(
          BookAndPayCompleted(
            tradeId: tradeId,
            swapId: swapState.data.boltzId,
            order: committed,
          ),
        );
      } catch (error, stackTrace) {
        _logger.e('Book and pay failed: $error');
        _logger.d('$stackTrace');
        if (!isClosed) emit(BookAndPayFailed(error.toString()));
      }
    },
  );

  Future<List<Map<String, Object?>>> _replyOrderInTradeThread(
    Order order, {
    required Iterable<String> participants,
  }) {
    final thread = _ensureTradeThread(
      tradeId: order.getDtag()!,
      participants: participants,
    );
    return _replyOnThread(thread, order);
  }

  Thread _ensureTradeThread({
    required String tradeId,
    required Iterable<String> participants,
  }) {
    final activePubkey = _auth.getActiveKey().publicKey;
    return _messaging.threads.ensureTradeConversation(
      tradeId: tradeId,
      participants: {activePubkey, ...participants},
    );
  }

  Future<List<Map<String, Object?>>> _replyOnThread(
    Thread thread,
    Nip01Event event,
  ) async {
    final futures = await thread.replyEvent(event);
    final nested = await Future.wait(futures);
    return nested
        .expand((responses) => responses)
        .map(
          (response) => {
            'relayUrl': response.relayUrl,
            'okReceived': response.okReceived,
            'broadcastSuccessful': response.broadcastSuccessful,
            'message': response.msg,
          },
        )
        .toList();
  }

  Future<Listing> _requireListing(String anchor) async {
    final listing = await _listings.getOneByAnchor(anchor);
    if (listing == null) {
      throw StateError('Listing not found: $anchor');
    }
    return listing;
  }

  void _assertAutoAcceptEligible(Listing listing) {
    if (!listing.active) {
      throw StateError('Listing is not active.');
    }
    if (!listing.autoAccept) {
      throw StateError('Listing does not allow auto-accept.');
    }
  }

  void _assertNotOwnListing(Listing listing) {
    final activePubkey = _auth.getActiveKey().publicKey;
    if (listing.pubKey == activePubkey ||
        getPubKeyFromAnchor(listing.anchor!) == activePubkey) {
      throw StateError(
        'The active account is the host for this listing and cannot book it as a guest.',
      );
    }
  }

  Future<void> _assertAvailable(Listing listing, BookAndPayInput input) async {
    final groups = await _orders.queryOrderGroups(listing: listing);
    if (!Listing.isAvailable(input.start, input.end, groups.values.toList())) {
      throw StateError('Listing is not available for those dates.');
    }
  }

  void _assertAmountCoversListing(
    DenominatedAmount offerAmount,
    DenominatedAmount requiredAmount,
  ) {
    try {
      if (offerAmount < requiredAmount) {
        throw StateError(
          'Offer amount is below the listing price for those dates.',
        );
      }
    } on ArgumentError catch (error) {
      throw StateError(
        'Offer amount is not comparable to listing price: $error',
      );
    }
  }

  Future<_EscrowFundingPlan> _buildEscrowFundingPlan({
    required Order order,
    required Listing listing,
    String? escrowServiceId,
  }) async {
    final sellerPubkey = listing.pubKey;
    final sellerProfile = await _metadata.loadMetadata(sellerPubkey);
    if (sellerProfile == null) {
      throw StateError('Seller profile metadata was not found.');
    }

    final mutual = await _escrows.determineMutualEscrow(
      _auth.getActiveKey().publicKey,
      sellerPubkey,
    );
    if (mutual.compatibleServices.isEmpty || mutual.sellerMethod == null) {
      throw StateError('No compatible escrow service was found.');
    }
    final sellerEvmAddress = mutual.sellerMethod!.evmAddress;
    if (sellerEvmAddress == null || sellerEvmAddress.isEmpty) {
      throw StateError('Seller EVM address was not found on escrow method.');
    }

    EscrowService? service;
    if (escrowServiceId == null || escrowServiceId.isEmpty) {
      service = mutual.compatibleServices.first;
    } else {
      for (final candidate in mutual.compatibleServices) {
        if (candidate.id == escrowServiceId ||
            candidate.pubKey == escrowServiceId ||
            candidate.escrowPubkey == escrowServiceId ||
            candidate.contractAddress.toLowerCase() ==
                escrowServiceId.toLowerCase()) {
          service = candidate;
          break;
        }
      }
    }
    if (service == null) {
      throw StateError('Requested escrow service is not compatible.');
    }

    final selectedEscrow = EscrowServiceSelected(
      pubKey: _auth.getActiveKey().publicKey,
      tags: EscrowServiceSelectedTags([
        ['d', order.getDtag()!],
        [kListingRefTag, order.parsedTags.listingAnchor],
        ['p', sellerProfile.pubKey],
      ]),
      content: EscrowServiceSelectedContent(
        service: service,
        sellerMethods: mutual.sellerMethod!,
      ),
    );

    final preparer = _escrow.fund(
      EscrowFundParams(
        escrowService: service,
        negotiateOrder: order,
        sellerProfile: sellerProfile,
        sellerEvmAddress: sellerEvmAddress,
        amount: order.amount!,
        sellerEscrowMethod: mutual.sellerMethod,
        securityDeposit: listing.securityDeposit,
        listingName: listing.title,
      ),
    );

    return _EscrowFundingPlan(
      selectedEscrow: selectedEscrow,
      preparer: preparer,
    );
  }

  Future<Order> _waitForMyCommittedOrder({
    required String tradeId,
    required String sellerPubkey,
    required Duration timeout,
  }) async {
    bool matches(Order order) {
      return order.getDtag() == tradeId &&
          order.isCommit &&
          order.pubKey != sellerPubkey;
    }

    for (final order in _userSubscriptions.allMyOrders$.stream.items) {
      if (matches(order)) return order;
    }

    return _userSubscriptions.allMyOrders$.stream.stream
        .firstWhere(matches)
        .timeout(timeout);
  }
}

class _EscrowFundingPlan {
  const _EscrowFundingPlan({
    required this.selectedEscrow,
    required this.preparer,
  });

  final EscrowServiceSelected selectedEscrow;
  final EscrowFundPreparer preparer;
}
