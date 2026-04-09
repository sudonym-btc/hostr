import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../chain/evm_chain.dart';

/// One sweepable balance entry — either a plain EOA/smart-wallet balance
/// or funds locked inside an escrow contract awaiting `withdraw()`.
///
/// Every item carries a [keypair] (the key controlling [address]) and an
/// [accountIndex] so the consumer can sign transactions or create swap-out
/// operations directly.
///
/// For escrow-locked funds, [contract] is non-null. The swap-out operation
/// must include `contract.withdraw(...)` as a pre-lock call so that the
/// withdrawal and lockup happen atomically.
class FundsItem {
  /// The EVM address that holds the funds.
  ///
  /// For EOA items this is the HD-derived address.
  /// For escrow items this is the address recorded as beneficiary in the
  /// contract (also HD-derived).
  final EthereumAddress address;

  /// The HD private key that controls [address].
  final EthPrivateKey keypair;

  /// The HD account index used to derive [keypair].
  final int accountIndex;

  final Token token;
  final TokenAmount balance;
  final EvmChain chain;
  final int blockNumber;

  /// Non-null only when the funds are locked inside an escrow contract.
  ///
  /// When set, call `contract.withdraw(WithdrawArgs(...))` as a pre-lock
  /// call in the swap-out operation.
  final SupportedEscrowContract? contract;

  /// Whether this item represents escrow-locked funds.
  bool get isEscrowLocked => contract != null;

  const FundsItem({
    required this.address,
    required this.keypair,
    required this.accountIndex,
    required this.token,
    required this.balance,
    required this.chain,
    required this.blockNumber,
    this.contract,
  });

  /// Cache key — unique per (address, token, contract address).
  (String, String, String) get cacheKey => (
    address.eip55With0x.toLowerCase(),
    token.address.toLowerCase(),
    contract?.address.eip55With0x.toLowerCase() ?? '',
  );

  @override
  String toString() =>
      'FundsItem(addr=${address.eip55With0x}, token=${token.address}, '
      'balance=${balance.value}, escrow=${contract != null})';
}
