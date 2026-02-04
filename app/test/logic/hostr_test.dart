import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/ndk.dart' show Ndk;
import 'package:rxdart/rxdart.dart';

class MockAuth extends Mock implements Auth {}

class MockMessaging extends Mock implements Messaging {}

class MockThreads extends Mock implements Threads {}

class MockReservations extends Mock implements Reservations {}

class MockPayments extends Mock implements Payments {}

class MockNwc extends Mock implements Nwc {}

class MockEvm extends Mock implements Evm {}

class MockRelays extends Mock implements Relays {}

class FakeNdk extends Fake implements Ndk {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BehaviorSubject<AuthState> authState;
  late MockAuth mockAuth;
  late MockMessaging mockMessaging;
  late MockThreads mockThreads;
  late MockReservations mockReservations;
  late MockPayments mockPayments;
  late MockNwc mockNwc;
  late MockEvm mockEvm;
  late MockRelays mockRelays;

  setUp(() async {
    await getIt.reset();

    authState = BehaviorSubject<AuthState>.seeded(LoggedOut());

    mockAuth = MockAuth();
    mockMessaging = MockMessaging();
    mockThreads = MockThreads();
    mockReservations = MockReservations();
    mockPayments = MockPayments();
    mockNwc = MockNwc();
    mockEvm = MockEvm();
    mockRelays = MockRelays();

    when(mockAuth.authState).thenAnswer((_) => authState);
    when(mockAuth.init()).thenAnswer((_) async {});
    when(mockAuth.dispose()).thenAnswer((_) async {});

    when(mockMessaging.threads).thenReturn(mockThreads);
    when(mockThreads.sync()).thenReturn(null);
    when(mockThreads.stop()).thenReturn(null);
    when(mockThreads.close()).thenAnswer((_) async {});

    when(mockReservations.dispose()).thenAnswer((_) async {});
    when(mockPayments.dispose()).thenReturn(null);
    when(mockNwc.dispose()).thenReturn(null);
    when(mockEvm.dispose()).thenAnswer((_) async {});

    getIt.registerSingleton<Auth>(mockAuth);
    getIt.registerSingleton<Messaging>(mockMessaging);
    getIt.registerSingleton<Reservations>(mockReservations);
    getIt.registerSingleton<Payments>(mockPayments);
    getIt.registerSingleton<Nwc>(mockNwc);
    getIt.registerSingleton<Evm>(mockEvm);
    getIt.registerSingleton<Relays>(mockRelays);
  });

  tearDown(() async {
    await authState.close();
    await getIt.reset();
  });

  test('start() syncs threads on login', () async {
    final hostr = ProdHostr(FakeNdk());

    hostr.start();
    authState.add(const LoggedIn());
    await pumpEventQueue();

    verify(mockThreads.sync()).called(1);
  });

  test('start() stops threads on logout', () async {
    final hostr = ProdHostr(FakeNdk());

    hostr.start();
    authState.add(LoggedOut());
    await pumpEventQueue();

    verify(mockThreads.stop()).called(1);
  });

  test('dispose() disposes collaborators', () async {
    final hostr = ProdHostr(FakeNdk());

    hostr.dispose();

    verify(mockThreads.close()).called(1);
    verify(mockReservations.dispose()).called(1);
    verify(mockPayments.dispose()).called(1);
    verify(mockNwc.dispose()).called(1);
    verify(mockEvm.dispose()).called(1);
    verify(mockAuth.dispose()).called(1);
  });
}
