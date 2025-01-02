import 'package:dart_nostr/dart_nostr.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/main.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

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
class Progress extends AuthState {
  Stream<DelegationProgress> progress;
  Progress(this.progress);
}

/// State representing a logged-in user.
class LoggedIn extends AuthState {
  const LoggedIn();
}

/// Cubit class to manage authentication state.
@injectable
class AuthCubit extends Cubit<AuthState> {
  SecureStorage secureStorage = getIt<SecureStorage>();

  AuthCubit() : super(AuthInitial());

  /// Logs in the user by generating a key pair and requesting delegation.
  Future<void> login() async {
    await logout();
    NostrKeyPairs keyPair = Nostr.instance.keysService.generateKeyPair();
    await secureStorage.set('keys', [keyPair]);
    emit(Progress(
        getIt<RequestDelegation>().requestDelegation(keyPair).doOnDone(() {
      emit(LoggedIn());
    })));
  }

  /// Checks if the user is logged in by verifying stored keys.
  Future<bool> checkKeyLoggedIn() async {
    if ((await secureStorage.readAll()).keys.isNotEmpty) {
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
}
