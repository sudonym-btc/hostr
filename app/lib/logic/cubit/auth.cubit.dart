import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Cubit managing authentication state.
/// Business processes (signup/signin flows) delegated to AuthWorkflow.
/// This cubit only manages state transitions and UI decisions.
class AuthCubit extends Cubit<AuthState> {
  CustomLogger logger = CustomLogger();

  AuthCubit({AuthState? initialState}) : super(initialState ?? AuthInitial());

  /// Executes signup: delegates to workflow, updates state.
  Future<void> signup() async {
    emit(LoggedOut()); // Start from logged-out during signup
    try {
      await getIt<Hostr>().auth.signup();
      emit(LoggedIn());
    } catch (e) {
      logger.e('Signup failed: $e');
      emit(LoggedOut());
      rethrow;
    }
  }

  /// Checks authentication status: delegates to workflow, updates state.
  Future<bool> get() async {
    final isAuthenticated = await getIt<Hostr>().auth.isAuthenticated();
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
      await getIt<Hostr>().auth.logout();
      emit(LoggedOut());
    } catch (e) {
      logger.e('Logout failed: $e');
      rethrow;
    }
  }

  /// Executes signin: delegates to workflow, updates state.
  Future<void> signin(String input) async {
    try {
      await getIt<Hostr>().auth.signin(input);
      emit(LoggedIn());
    } catch (e) {
      logger.e('Signin failed: $e');
      emit(LoggedOut());
      rethrow;
    }
  }
}
