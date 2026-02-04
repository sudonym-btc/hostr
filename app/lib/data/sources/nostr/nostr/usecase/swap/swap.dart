import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/evm_chain.dart';
import 'package:injectable/injectable.dart';

import '../auth/auth.dart';

@Singleton()
class Swap {
  final CustomLogger logger = CustomLogger();
  final Auth auth;

  Swap({required this.auth});

  Stream<SwapState> swapIn({
    required int amountSats,
    required EvmChain evmChain,
  }) {
    return evmChain.swapIn(key: auth.activeKeyPair!, amountSats: amountSats);
  }
}
