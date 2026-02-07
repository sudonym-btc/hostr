import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:injectable/injectable.dart';

import 'swap_in_models.dart';
import 'swap_in_state.dart';

abstract class SwapInOperation {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final SwapInParams params;

  SwapInOperation({required this.auth, @factoryParam required this.params});

  Future<BitcoinAmount> estimateFees();
  Stream<SwapInState> execute();
}
