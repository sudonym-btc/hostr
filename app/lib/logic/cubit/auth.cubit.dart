import 'package:bip39/bip39.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

/// Abstract class representing the state of authentication.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

/// Initial state of authentication.
class AuthInitial extends AuthState {}

/// State representing a logged-out user.
class LoggedOut extends AuthState {}

/// State representing a progress in authentication.
// class Progress extends AuthState {
//   Stream<DelegationProgress> progress;
//   Progress(this.progress);
// }

/// State representing a logged-in user.
class LoggedIn extends AuthState {
  const LoggedIn();
}

/// Cubit class to manage authentication state.
class AuthCubit extends Cubit<AuthState> {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  SecureStorage secureStorage = getIt<SecureStorage>();

  AuthCubit({AuthState? initialState}) : super(initialState ?? AuthInitial());

  /// Logs in the user by generating a key pair and requesting delegation.
  Future<void> signup() async {
    await logout();
    await keyStorage.create();
    // emit(Progress(
    //     getIt<RequestDelegation>().requestDelegation(keyPair).doOnDone(() {
    // })));

    emit(LoggedIn());
  }

  /// Checks if the user is logged in by verifying stored keys.
  Future<bool> get() async {
    if ((await keyStorage.getActiveKeyPair()) != null) {
      emit(LoggedIn());
      return true;
    }
    emit(LoggedOut());
    return false;
  }

  /// Logs out the user by wiping stored keys.
  Future<void> logout() async {
    await secureStorage.wipe();
    emit(LoggedOut());
  }

  signin(String private) async {
    String? entropy;
    if (NostrKeyPairs.isValidPrivateKey(private)) {
      entropy = private;
    } else {
      try {
        entropy = mnemonicToEntropy(private);
      } catch (e) {
        logger.i('Invalid mnemonic');
      }
    }

    /// TODO Check nsec
    // try {
    //   entropy =
    // } catch (e) {
    //   logger.i('Invalid mnemonic');
    // }
    // }
    if (entropy != null) {
      await keyStorage.set(entropy);
      emit(LoggedIn());
    } else {
      logger.i('Key invalid');
    }
  }
}
