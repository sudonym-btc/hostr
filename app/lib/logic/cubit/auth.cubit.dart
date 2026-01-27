import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/services/main.dart';

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

/// Cubit managing authentication state.
/// Business processes (signup/signin flows) delegated to AuthWorkflow.
/// This cubit only manages state transitions and UI decisions.
class AuthCubit extends Cubit<AuthState> {
  CustomLogger logger = CustomLogger();
  final KeyStorage keyStorage;
  final SecureStorage secureStorage;
  final AuthService _authService;

  AuthCubit({
    required this.keyStorage,
    required this.secureStorage,
    required AuthService authService,
    AuthState? initialState,
  }) : _authService = authService,
       super(initialState ?? AuthInitial());

  /// Executes signup: delegates to workflow, updates state.
  Future<void> signup() async {
    emit(LoggedOut()); // Start from logged-out during signup
    try {
      await _authService.signup();
      emit(LoggedIn());
    } catch (e) {
      logger.e('Signup failed: $e');
      emit(LoggedOut());
      rethrow;
    }
  }

  /// Checks authentication status: delegates to workflow, updates state.
  Future<bool> get() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated) {
      emit(LoggedIn());
      return true;
    }
    emit(LoggedOut());
    return false;
  }

  /// Executes logout: delegates to workflow, updates state.
  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(LoggedOut());
    } catch (e) {
      logger.e('Logout failed: $e');
      rethrow;
    }
  }

  /// Executes signin: delegates to workflow, updates state.
  Future<void> signin(String input) async {
    try {
      await _authService.signin(input);
      emit(LoggedIn());
    } catch (e) {
      logger.e('Signin failed: $e');
      emit(LoggedOut());
      rethrow;
    }
  }
}
