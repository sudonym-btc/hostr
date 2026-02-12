import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Filter, Nip01EventModel;

@Injectable()
class Thread {
  final Messaging messaging;
  final Auth auth;
  final Reservations reservations;
  final Zaps zaps;
  final Listings listings;
  final EscrowUseCase escrow;
  final MetadataUseCase metadata;
  Thread(
    @factoryParam this.anchor, {
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

  Completer<Listing?>? _listingCompleter;
  Completer<ProfileMetadata?>? _listingProfileCompleter;

  Future<Listing?> get listing async {
    if (_listingCompleter == null) {
      _listingCompleter = Completer<Listing?>();
      try {
        final listing = await listings.getOneByDTag(
          getDTagFromAnchor(MessagingListings.getThreadListing(thread: this)),
        );
        _listingCompleter!.complete(listing);
      } catch (e) {
        _listingCompleter!.completeError(e);
      }
    }
    return _listingCompleter!.future;
  }

  Future<ProfileMetadata?> get listingProfile async {
    if (_listingProfileCompleter == null) {
      _listingProfileCompleter = Completer<ProfileMetadata?>();
      try {
        final profile = await metadata.getOne(
          Filter(authors: [(await listing)!.pubKey]),
        );
        _listingProfileCompleter!.complete(profile);
      } catch (e) {
        _listingProfileCompleter!.completeError(e);
      }
    }
    return _listingProfileCompleter!.future;
  }

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
      reservationStream.status.listen((status) {
        if (status is StreamStatusLive) {
          if (reservationStream.list.value.isEmpty) {
            print('No reservations yet, creating self-signed reservation');
            _paymentStream!.replay.listen((el) async {
              print('Payment completed, creating reservation on thread');

              final reservation = await reservations.createSelfSigned(
                threadId: anchor,
                reservationRequest:
                    messages.list.value
                            .where(
                              (element) => element.child is ReservationRequest,
                            )
                            .first
                            .child
                        as ReservationRequest,
                proof: el,
              );
              print("CREATED RESERVATION: ${reservation.id}");
            });
          }
        }
      });
    }
    return _paymentStream!;
  }

  Future<Listing?> getListing() {
    _listingCompleter ??= Completer<Listing?>();
    if (!_listingCompleter!.isCompleted) {
      listings
          .getOneByDTag(
            getDTagFromAnchor(MessagingListings.getThreadListing(thread: this)),
          )
          .then(_listingCompleter!.complete)
          .catchError(_listingCompleter!.completeError);
    }
    return _listingCompleter!.future;
  }

  Future<ProfileMetadata?> getListingProfile() {
    _listingProfileCompleter ??= Completer<ProfileMetadata?>();
    if (!_listingProfileCompleter!.isCompleted) {
      getListing()
          .then((listing) async {
            if (listing == null) return null;
            return metadata.getOne(Filter(authors: [listing.pubKey]));
          })
          .then(_listingProfileCompleter!.complete)
          .catchError(_listingProfileCompleter!.completeError);
    }
    return _listingProfileCompleter!.future;
  }

  List<EscrowServiceSelected> get selectedEscrows {
    return messages.list.value
        .where((element) => element.child is EscrowServiceSelected)
        .map((element) => element.child as EscrowServiceSelected)
        .toList();
  }

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

  Message? get getLatestMessage {
    if (messages.list.value.isEmpty) return null;
    return messages.list.value.reduce(
      (a, b) => a.createdAt > b.createdAt ? a : b,
    );
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

  StreamWithStatus<SelfSignedProof> getPaymentProof() {
    final response = DynamicCombinedStreamWithStatus<SelfSignedProof>();
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

    response.combine(
      zaps
          .subscribeZapReceipts(pubkey: counterpartyPubkeys.first)
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

  Future<void> dispose() async {
    await messages.close();
  }
}
