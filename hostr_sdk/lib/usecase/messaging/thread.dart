import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Filter, Nip01EventModel;
import 'package:rxdart/rxdart.dart';

@Injectable()
class Thread {
  final CustomLogger logger;
  final Messaging messaging;
  final Auth auth;
  final Reservations reservations;
  final Zaps zaps;
  final Listings listings;
  final EscrowUseCase escrow;
  final MetadataUseCase metadata;
  Thread(
    @factoryParam this.anchor, {
    required this.logger,
    required this.auth,
    required this.messaging,
    required this.zaps,
    required this.reservations,
    required this.listings,
    required this.metadata,
    required this.escrow,
  });

  final String anchor;
  String get tradeId => getDTagFromAnchor(anchor);

  final StreamWithStatus<Message> messages = StreamWithStatus<Message>();
  final PublishSubject<void> _dispose$ = PublishSubject<void>();

  Completer<Listing?>? _listingCompleter;
  Completer<ProfileMetadata?>? _listingProfileCompleter;

  Future<Listing?> get listing => getListing();

  Future<ProfileMetadata?> get listingProfile => getListingProfile();

  StreamWithStatus<Reservation>? _reservationStream;
  StreamWithStatus<Reservation> get reservationStream {
    _reservationStream ??= reservations.subscribe(
      Filter(
        tags: {
          kListingRefTag: [MessagingListings.getThreadListing(thread: this)],
          kThreadRefTag: [anchor],
        },
      ),
    );
    return _reservationStream!;
  }

  StreamWithStatus<SelfSignedProof>? _paymentStream;
  StreamWithStatus<SelfSignedProof> get paymentStream {
    if (_paymentStream == null) {
      _paymentStream = getPaymentProof();
      listenForPaymentProof();
    }
    return _paymentStream!;
  }

  // Awaits fetching of reservations
  // If no reservations exist, listens for the next payment proof and creates a self-signed reservation
  void listenForPaymentProof() async {
    try {
      await reservationStream.status
          .whereType<StreamStatusLive>()
          .takeUntil(_dispose$)
          .first;
      if (reservationStream.list.value.isEmpty) {
        logger.d(
          'No reservations yet, creating self-signed reservation on payment proof when payment is seen',
        );
        final proof = await paymentStream.replay.takeUntil(_dispose$).first;
        logger.d(
          'Payment completed, creating reservation on thread ${proof.escrowProof}, proof: ${proof.zapProof}',
        );

        final reservation = await reservations.createSelfSigned(
          threadId: anchor,
          reservationRequest: lastReservationRequest,
          proof: proof,
        );
        logger.d("Created self-signed reservation: ${reservation.id}");
      }
    } catch (e) {
      logger.d('listenForPaymentProof cancelled: $e');
    }
  }

  Future<Listing?> getListing() {
    if (_listingCompleter != null) {
      return _listingCompleter!.future;
    }

    _listingCompleter = Completer<Listing?>();
    listings
        .getOneByDTag(
          getDTagFromAnchor(MessagingListings.getThreadListing(thread: this)),
        )
        .then(_listingCompleter!.complete)
        .catchError(_listingCompleter!.completeError);
    return _listingCompleter!.future;
  }

  Future<ProfileMetadata?> getListingProfile() {
    if (_listingProfileCompleter != null) {
      return _listingProfileCompleter!.future;
    }

    _listingProfileCompleter = Completer<ProfileMetadata?>();
    getListing()
        .then((listing) async {
          if (listing == null) return null;
          return metadata.getOne(Filter(authors: [listing.pubKey]));
        })
        .then(_listingProfileCompleter!.complete)
        .catchError(_listingProfileCompleter!.completeError);
    return _listingProfileCompleter!.future;
  }

  List<EscrowServiceSelected> get selectedEscrows {
    final items = messages.list.value
        .map((message) => message.child)
        .whereType<EscrowServiceSelected>()
        .toList();

    /// Deduplicate by escrow service ID, keeping the most recent selection for each service
    Map<String, EscrowServiceSelected> mapper = {};
    for (final item in items) {
      final key = item.parsedContent.service.id;
      mapper[key] = item;
    }

    return mapper.values.toList();
  }

  List<Message<Event>> get reservationRequests => messages.list.value
      .where((message) => message.child is ReservationRequest)
      // .map((message) => message as Message<ReservationRequest>)
      .toList();

  List<Message> get textMessages =>
      messages.list.value.where((message) => message.child == null).toList();

  List<String> get participantPubkeys {
    final pubkeys = <String>{};
    for (final msg in messages.list.value) {
      pubkeys.add(msg.pubKey);
      if (msg.pTags != null) {
        pubkeys.addAll(msg.pTags);
      }
    }
    return pubkeys.toList();
  }

  List<String> get counterpartyPubkeys {
    return participantPubkeys
        .where((pubkey) => pubkey != auth.activeKeyPair!.publicKey)
        .toList();
  }

  ReservationRequest get lastReservationRequest {
    return messages.list.value
        .where((element) => element.child is ReservationRequest)
        .map((element) => element.child as ReservationRequest)
        .last;
  }

  Message? get getLatestMessage {
    final messagesList = [...reservationRequests, ...textMessages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (messagesList.isEmpty) return null;
    return messagesList.reduce((a, b) => a.createdAt > b.createdAt ? a : b);
  }

  DateTime get getLastDateTime {
    final latest = getLatestMessage;
    return DateTime.fromMillisecondsSinceEpoch(latest!.createdAt * 1000);
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> replyText(String content) {
    return messaging.broadcastText(
      content: content,
      tags: [
        [kThreadRefTag, anchor],
      ],
      recipientPubkeys: counterpartyPubkeys,
    );
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> replyEvent<
    T extends Nip01Event
  >(T event, {List<List<String>> tags = const []}) {
    return messaging.broadcastEvent(
      event: event,
      tags: [
        [kThreadRefTag, anchor],
        ...tags,
      ],
      recipientPubkeys: counterpartyPubkeys,
    );
  }

  bool get isLastMessageOurs {
    final latest = getLatestMessage;
    final ours = auth.activeKeyPair!.publicKey;
    return latest?.pubKey == ours;
  }

  Message getLastMessageOrReservationRequest() {
    final latest = getLatestMessage;
    if (latest != null) return latest;

    final reservationRequests = messages.list.value
        .where((element) => element.child is ReservationRequest)
        .toList();
    if (reservationRequests.isNotEmpty) {
      return reservationRequests.last;
    }

    throw Exception('No messages or reservation requests found in thread');
  }

  StreamWithStatus<SelfSignedProof> getPaymentProof() {
    final response = DynamicCombinedStreamWithStatus<SelfSignedProof>();
    // Set to live in case there are no selected escrows or zaps, so that the stream doesn't get stuck on loading status without emitting anything
    // response.addStatus(StreamStatusLive());
    for (final escrowService in selectedEscrows) {
      response.combine(
        escrow
            .getEscrowProof(escrowService, tradeId)
            .asyncMap(
              (proof) async => SelfSignedProof(
                listing: (await listing)!,
                hoster: (await listingProfile)!,
                escrowProof: proof,
                zapProof: null,
              ),
            ),
      );
    }
    messages.stream
        .where((message) => message.child is EscrowServiceSelected)
        .takeUntil(_dispose$)
        .listen((message) {
          final escrowService = (message.child as EscrowServiceSelected);
          response.combine(
            escrow
                .getEscrowProof(escrowService, tradeId)
                .asyncMap(
                  (proof) async => SelfSignedProof(
                    listing: (await listing)!,
                    hoster: (await listingProfile)!,
                    escrowProof: proof,
                    zapProof: null,
                  ),
                ),
          );
        });

    response.combine(
      zaps
          .subscribeZapReceipts(
            pubkey: counterpartyPubkeys.first,
            addressableId: anchor,
          )
          .map(
            (receipt) => ZapProof(receipt: Nip01EventModel.fromEntity(receipt)),
          )
          .asyncMap(
            (proof) async => SelfSignedProof(
              listing: (await listing)!,
              hoster: (await listingProfile)!,
              zapProof: proof,
              escrowProof: null,
            ),
          ),
    );

    return response;
  }

  Future<void> removeSubscriptions() async {
    await _paymentStream?.close();
    _paymentStream = null;
    await _reservationStream?.close();
    _reservationStream = null;
  }

  Future<void> dispose() async {
    _dispose$.add(null);
    await _dispose$.close();
    await messages.close();
    await removeSubscriptions();
  }
}
