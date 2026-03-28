/// Shared fake stubs for unit tests.
///
/// These are minimal no-op implementations used across many test files.
/// Import this file instead of duplicating `_Fake*` classes in each test.
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/reservation_transitions/reservation_transitions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;

/// No-op fake for [Messaging].
class FakeMessaging extends Fake implements Messaging {}

/// No-op fake for [Auth].
class FakeAuth extends Fake implements Auth {}

/// No-op fake for [ReservationTransitions].
class FakeTransitions extends Fake implements ReservationTransitions {}

/// In-memory fake relay source for reservation / event subscriptions.
///
/// Supports `subscribe` returning a manually-controlled [StreamWithStatus],
/// and exposes [emit] / [emitStatus] for driving tests.
class FakeRelayRequests extends Fake implements hostr_requests.Requests {
  final StreamWithStatus<Nip01Event> _source = StreamWithStatus<Nip01Event>();

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    final typed = StreamWithStatus<T>();
    _source.stream.listen((event) => typed.add(event as T));
    _source.status.listen(typed.addStatus);
    return typed;
  }

  void emit(Nip01Event event) => _source.add(event);

  void emitStatus(StreamStatus status) => _source.addStatus(status);

  Future<void> close() => _source.close();
}

/// Placeholder fake RPC client shape for escrow validation scenarios.
class FakeEscrowRpc {
  final Map<String, ({BigInt amount, String to, bool ok})> txByHash;

  FakeEscrowRpc(this.txByHash);
}

/// No-op fake for [Listings].
class FakeListings extends Fake implements Listings {}

/// No-op fake for [Ndk].
class FakeNdk extends Fake implements Ndk {}
