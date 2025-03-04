import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/core/util/custom_logger.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class ThreadCubit extends Cubit<ThreadCubitState> {
  CustomLogger logger = CustomLogger();
  ThreadCubit(super.initialState);

  Stream<ListCubitState<Reservation>> loadBookingState() {
    print('Loading reservations with ${getAnchor()}');
    var x = ListCubit<Reservation>(
        kinds: [NOSTR_KIND_RESERVATION], filter: Filter(aTags: [getAnchor()]));
    x.sync();
    return x.stream;
  }

  addMessage(Message message) {
    final messages = state.messages;
    messages.add(message);
    emit(ThreadCubitState(id: state.id, messages: messages));
  }

  String getCounterpartyPubkey() {
    logger.i('Getting counterparty pubkey');
    KeyPair ours = getIt<KeyStorage>().getActiveKeyPairSync()!;
    var keys = state.messages.expand((e) {
      var keys = [...e.nip01Event.pTags];
      if (e.child != null) {
        keys.add(e.child!.nip01Event.pubKey);
      }
      return keys;
    }).toList();

    return keys.firstWhere(
      (element) => element != ours.publicKey,
    );
  }

  String getListingAnchor() {
    logger.i('Getting listing anchor');
    return state.messages
        .where((element) {
          return element.child is ReservationRequest;
        })
        .map((e) => e.child!.anchor)
        .first;
  }

  String getAnchor() {
    logger.i('Getting anchor');
    Message lastMessage = state.messages.last;
    return lastMessage.anchor;
  }

  /// Get the latest state of the thread
  LatestThreadState? getLatestState() {
    logger.i('Getting latest state');

    KeyPair ours = (getIt<KeyStorage>().getActiveKeyPairSync())!;

    for (Message m in state.messages.reversed) {
      Event? content = m.child;
      if (content is ReservationRequest) {
        if (m.nip01Event.pubKey == ours.publicKey) {
          return LatestThreadState.RESERVATION_REQUEST_SENT;
        }
        return LatestThreadState.RESERVATION_REQUEST_RECEIVED;
      } else {
        if (m.nip01Event.pubKey == ours.publicKey) {
          return LatestThreadState.MESSAGE_SENT;
        }
        return LatestThreadState.MESSAGE_RECEIVED;
      }
    }
    // Return a default state if no matching type is found
    logger.i('No matching state found');
    return null;
  }

  getReadStatus() {}

  DateTime getLastDateTime() {
    // Return most recent dateTime of messages
    return state.messages
        .map((message) => DateTime.fromMillisecondsSinceEpoch(
            message.nip01Event.createdAt * 1000))
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

enum LatestThreadState {
  RESERVATION_REQUEST_RECEIVED,
  RESERVATION_REQUEST_SENT,
  MESSAGE_SENT,
  MESSAGE_RECEIVED,
  CONFIRMED,
  CANCELLED
}

class ThreadCubitState {
  final String id;
  final List<Message> messages;

  ThreadCubitState({required this.id, required this.messages});
}
