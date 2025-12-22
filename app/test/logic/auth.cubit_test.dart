import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/data/sources/local/secure_storage.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/auth.cubit.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() {
  KeyPair keyPair = Bip340.generatePrivateKey();

  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [LoggedOut] when get called().',
      build: () => AuthCubit(
        keyStorage: getIt(),
        secureStorage: getIt(),
        ndk: getIt(),
        workflow: getIt(),
      ),
      act: (bloc) {
        return bloc.get();
      },
      expect: () => <AuthState>[LoggedOut()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [LoggedIn] when get called().',
      build: () => AuthCubit(
        keyStorage: getIt(),
        secureStorage: getIt(),
        ndk: getIt(),
        workflow: getIt(),
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
        ndk: getIt(),
        workflow: getIt(),
      ),
      act: (bloc) {
        return bloc.signup();
      },
      expect: () => [LoggedOut(), isA<LoggedIn>()],
    );
  });
}
