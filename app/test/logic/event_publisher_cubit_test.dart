// import 'package:bloc_test/bloc_test.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hostr/data/sources/nostr/nostr/nostr.service.dart';
// import 'package:hostr/logic/cubit/event_publisher.cubit.dart';
// import 'package:hostr/logic/progress/progress.dart';
// import 'package:mockito/mockito.dart';
// import 'package:ndk/ndk.dart';

// class MockNostrService extends Mock implements NostrService {}

// class MockNip01Event extends Mock implements Nip01Event {}

// class FakeNip01Event extends Fake implements Nip01Event {}

// void main() {
//   group('EventPublisherCubit', () {
//     late MockNostrService nostrService;
//     late Nip01Event eventA;
//     late Nip01Event eventB;

//     setUpAll(() {
//       registerFallbackValue(FakeNip01Event());
//     });

//     setUp(() {
//       nostrService = MockNostrService();
//       eventA = MockNip01Event();
//       eventB = MockNip01Event();

//       when(
//         nostrService.broadcast(
//           event: any<Nip01Event>(named: 'event'),
//           relays: anyNamed('relays'),
//         ),
//       ).thenAnswer((_) async => <RelayBroadcastResponse>[]);
//     });

//     blocTest<EventPublisherCubit, EventPublisherState>(
//       'emits progress snapshots then success',
//       build: () => EventPublisherCubit(nostrService: nostrService),
//       act: (cubit) => cubit.publishEvents([eventA, eventB]),
//       expect: () => [
//         EventPublisherState(
//           progress: ProgressSnapshot.inProgress(
//             operation: 'publish_events',
//             message: 'Publishing 2 event(s)',
//             fraction: 0,
//           ),
//           total: 2,
//           sent: 0,
//         ),
//         EventPublisherState(
//           progress: ProgressSnapshot.inProgress(
//             operation: 'publish_events',
//             message: 'Publishing 1 of 2',
//             fraction: 0.5,
//             context: {'sent': 1, 'total': 2},
//           ),
//           total: 2,
//           sent: 1,
//         ),
//         EventPublisherState(
//           progress: ProgressSnapshot.inProgress(
//             operation: 'publish_events',
//             message: 'Publishing 2 of 2',
//             fraction: 1,
//             context: {'sent': 2, 'total': 2},
//           ),
//           total: 2,
//           sent: 2,
//         ),
//         EventPublisherState(
//           progress: ProgressSnapshot.success(
//             operation: 'publish_events',
//             message: 'Published 2 event(s)',
//             context: {'sent': 2, 'total': 2},
//           ),
//           total: 2,
//           sent: 2,
//         ),
//       ],
//       verify: (_) {
//         verify(nostrService.broadcast(event: eventA)).called(1);
//         verify(nostrService.broadcast(event: eventB)).called(1);
//       },
//     );

//     blocTest<EventPublisherCubit, EventPublisherState>(
//       'reports failure when broadcast throws',
//       build: () {
//         when(
//           nostrService.broadcast(
//             event: any<Nip01Event>(named: 'event'),
//             relays: anyNamed('relays'),
//           ),
//         ).thenThrow(Exception('network error'));
//         return EventPublisherCubit(nostrService: nostrService);
//       },
//       act: (cubit) => cubit.publishEvents([eventA]),
//       expect: () => [
//         EventPublisherState(
//           progress: ProgressSnapshot.inProgress(
//             operation: 'publish_events',
//             message: 'Publishing 1 event(s)',
//             fraction: 0,
//           ),
//           total: 1,
//           sent: 0,
//         ),
//         isA<EventPublisherState>().having(
//           (state) => state.progress.status,
//           'status',
//           ProgressStatus.failure,
//         ),
//       ],
//       verify: (_) {
//         verify(nostrService.broadcast(event: eventA)).called(1);
//       },
//     );
//   });
// }
