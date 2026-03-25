import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

class SwapOutParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  final TokenAmount? amount;

  SwapOutParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
  });
}
