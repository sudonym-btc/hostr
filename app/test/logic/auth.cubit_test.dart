import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:models/bip340.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() {
  KeyPair keyPair = Bip340.generatePrivateKey();

  setUp(() async {
    // Reset the GetIt instance to its initial state before each test
    await GetIt.I.reset(dispose: true);
    getIt.allowReassignment = true;

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [LoggedOut] when get called().',
      build: () => AuthCubit(
        keyStorage: getIt(),
        secureStorage: getIt(),
        authService: getIt(),
      ),
      act: (bloc) {
        return bloc.get();
      },
      expect: () => <AuthState>[LoggedOut()],
      verify: (_) {
        final ndk = getIt<Ndk>();
        // Basic check: at least one account exists
        expect(ndk.accounts.accounts.isEmpty, true);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [LoggedIn] when get called().',
      build: () => AuthCubit(
        keyStorage: getIt(),
        secureStorage: getIt(),
        authService: getIt(),
      ),
      setUp: () {
        getIt<SecureStorage>().set('keys', [keyPair.privateKey]);
      },
      act: (bloc) {
        return bloc.get();
      },
      expect: () => <AuthState>[LoggedIn()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [LoggedIn] when login called().',
      build: () => AuthCubit(
        keyStorage: getIt(),
        secureStorage: getIt(),
        authService: getIt(),
      ),
      act: (bloc) {
        return bloc.signup();
      },
      expect: () => [LoggedOut(), isA<LoggedIn>()],
      verify: (_) {
        final ndk = getIt<Ndk>();
        // Basic check: at least one account exists
        expect(ndk.accounts.accounts.isNotEmpty, true);

        // Stronger check: it contains the current pubkey
        final kp = getIt<KeyStorage>().getActiveKeyPairSync()!;
        expect(ndk.accounts.hasAccount(kp.publicKey), true);
      },
    );
  });
}
