import 'package:bloc_test/bloc_test.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/data/sources/local/secure_storage.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/auth.cubit.dart';

void main() {
  NostrKeyPairs keyPair = Nostr.instance.keysService.generateKeyPair();

  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [LoggedOut] when checkKeyLoggedIn().',
      build: () => AuthCubit(),
      act: (bloc) {
        return bloc.checkKeyLoggedIn();
      },
      expect: () => <AuthState>[LoggedOut()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [LoggedIn] when checkKeyLoggedIn().',
      build: () => AuthCubit(),
      setUp: () {
        getIt<SecureStorage>().set('keys', [keyPair]);
      },
      act: (bloc) {
        return bloc.checkKeyLoggedIn();
      },
      expect: () => <AuthState>[LoggedIn()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [InProgress] when login called().',
      build: () => AuthCubit(),
      act: (bloc) {
        return bloc.login();
      },
      expect: () => [LoggedOut(), isA<Progress>()],
    );
  });
}
