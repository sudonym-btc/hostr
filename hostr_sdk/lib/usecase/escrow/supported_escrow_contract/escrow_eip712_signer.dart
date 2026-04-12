import 'dart:typed_data';

import 'package:eip712/eip712.dart' as eip712;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

/// Produces EIP-712 signatures for the `MultiEscrow` contract.
///
/// The domain matches the Solidity constructor:
/// ```solidity
/// constructor() EIP712("Hostr MultiEscrow", "6") { … }
/// ```
///
/// Four typed-data actions are supported:
///
/// | Action   | Solidity type hash                                     |
/// |----------|--------------------------------------------------------|
/// | Claim    | `Claim(bytes32 tradeId)`                               |
/// | Release  | `Release(bytes32 tradeId,address actor)`               |
/// | Arbitrate| `Arbitrate(bytes32 tradeId,uint256 paymentFactor,uint256 bondFactor)` |
/// | Withdraw | `Withdraw(address token,address destination)`         |
class EscrowEip712Signer {
  static const String _domainName = 'Hostr MultiEscrow';
  static const String _domainVersion = '6';

  final int chainId;
  final EthereumAddress verifyingContract;

  const EscrowEip712Signer({
    required this.chainId,
    required this.verifyingContract,
  });

  // ── Domain definition (shared by all three actions) ──────────────

  List<eip712.MessageTypeProperty> get _domainType => const [
    eip712.MessageTypeProperty(name: 'name', type: 'string'),
    eip712.MessageTypeProperty(name: 'version', type: 'string'),
    eip712.MessageTypeProperty(name: 'chainId', type: 'uint256'),
    eip712.MessageTypeProperty(name: 'verifyingContract', type: 'address'),
  ];

  eip712.EIP712Domain get _domain => eip712.EIP712Domain(
    name: _domainName,
    version: _domainVersion,
    chainId: BigInt.from(chainId),
    verifyingContract: verifyingContract,
    salt: null,
  );

  // ── Claim ────────────────────────────────────────────────────────

  /// Sign a `Claim(bytes32 tradeId)` for the seller.
  Uint8List signClaim({
    required Uint8List tradeId,
    required EthPrivateKey signer,
  }) {
    final typedData = eip712.TypedMessage(
      types: {
        eip712.EIP712Domain.type: _domainType,
        'Claim': const [
          eip712.MessageTypeProperty(name: 'tradeId', type: 'bytes32'),
        ],
      },
      primaryType: 'Claim',
      domain: _domain,
      message: {'tradeId': bytesToHex(tradeId, include0x: true)},
    );
    return _sign(typedData, signer);
  }

  // ── Release ──────────────────────────────────────────────────────

  /// Sign a `Release(bytes32 tradeId, address actor)` for buyer or seller.
  Uint8List signRelease({
    required Uint8List tradeId,
    required EthereumAddress actor,
    required EthPrivateKey signer,
  }) {
    final typedData = eip712.TypedMessage(
      types: {
        eip712.EIP712Domain.type: _domainType,
        'Release': const [
          eip712.MessageTypeProperty(name: 'tradeId', type: 'bytes32'),
          eip712.MessageTypeProperty(name: 'actor', type: 'address'),
        ],
      },
      primaryType: 'Release',
      domain: _domain,
      message: {
        'tradeId': bytesToHex(tradeId, include0x: true),
        'actor': actor.eip55With0x,
      },
    );
    return _sign(typedData, signer);
  }

  // ── Arbitrate ────────────────────────────────────────────────────

  /// Sign an `Arbitrate(bytes32 tradeId, uint256 paymentFactor, uint256 bondFactor)` for the arbiter.
  Uint8List signArbitrate({
    required Uint8List tradeId,
    required BigInt paymentFactor,
    required BigInt bondFactor,
    required EthPrivateKey signer,
  }) {
    final typedData = eip712.TypedMessage(
      types: {
        eip712.EIP712Domain.type: _domainType,
        'Arbitrate': const [
          eip712.MessageTypeProperty(name: 'tradeId', type: 'bytes32'),
          eip712.MessageTypeProperty(name: 'paymentFactor', type: 'uint256'),
          eip712.MessageTypeProperty(name: 'bondFactor', type: 'uint256'),
        ],
      },
      primaryType: 'Arbitrate',
      domain: _domain,
      message: {
        'tradeId': bytesToHex(tradeId, include0x: true),
        'paymentFactor': paymentFactor,
        'bondFactor': bondFactor,
      },
    );
    return _sign(typedData, signer);
  }

  // ── Withdraw ──────────────────────────────────────────────────────

  /// Sign a `Withdraw(address token, address destination)` for a beneficiary
  /// to pull settled funds to any destination address.
  Uint8List signWithdraw({
    required EthereumAddress token,
    required EthereumAddress destination,
    required EthPrivateKey signer,
  }) {
    final typedData = eip712.TypedMessage(
      types: {
        eip712.EIP712Domain.type: _domainType,
        'Withdraw': const [
          eip712.MessageTypeProperty(name: 'token', type: 'address'),
          eip712.MessageTypeProperty(name: 'destination', type: 'address'),
        ],
      },
      primaryType: 'Withdraw',
      domain: _domain,
      message: {
        'token': token.eip55With0x,
        'destination': destination.eip55With0x,
      },
    );
    return _sign(typedData, signer);
  }

  // ── Helpers ──────────────────────────────────────────────────────

  /// Hash, sign, and pack into a 65-byte `r ‖ s ‖ v` signature.
  Uint8List _sign(eip712.TypedMessage typedData, EthPrivateKey signer) {
    final hash = eip712.hashTypedData(
      typedData: typedData,
      version: eip712.TypedDataVersion.v4,
    );
    final sig = sign(hash, signer.privateKey);
    final r = padUint8ListTo32(unsignedIntToBytes(sig.r));
    final s = padUint8ListTo32(unsignedIntToBytes(sig.s));

    // Pack as 65-byte `r (32) ‖ s (32) ‖ v (1)` — the format expected by
    // OpenZeppelin's `ECDSA.tryRecover(bytes32,bytes)`.
    final packed = Uint8List(65);
    packed.setRange(0, 32, r);
    packed.setRange(32, 64, s);
    packed[64] = sig.v;
    return packed;
  }
}
