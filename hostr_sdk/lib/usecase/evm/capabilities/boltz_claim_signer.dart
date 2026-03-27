import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:eip712/eip712.dart' as eip712;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../util/custom_logger.dart';
import '../../../util/token_amount_ext.dart';
import '../userop/claim_args.dart';
import 'boltz_swap_provider.dart';

/// Builds [ClaimArgs] and handles EIP-712 claim authorization signing.
///
/// Extracted from [EvmSwapInOperation] so the crypto-heavy claim logic
/// lives in its own testable collaborator.
class BoltzClaimSigner {
  final BoltzSwapProvider swaps;
  final int chainId;
  final CustomLogger logger;

  const BoltzClaimSigner({
    required this.swaps,
    required this.chainId,
    required this.logger,
  });

  /// Build [ClaimArgs] from persisted swap data.
  ///
  /// When [destination] is provided, an EIP-712 claim authorization signature
  /// is generated. Otherwise a zero-signature is used (standard claim path).
  Future<ClaimArgs> buildClaimArgs({
    required Uint8List preimage,
    required String preimageHash,
    required int onchainAmountSat,
    required EthereumAddress refundAddress,
    required int timeoutBlockHeight,
    required EthPrivateKey signer,
    String? tokenAddress,
    EthereumAddress? destination,
    EthereumAddress? expectedClaimAddress,
  }) async {
    final isErc20 = tokenAddress != null;
    final amount = rbtcFromSats(BigInt.from(onchainAmountSat)).getInWei;
    final timelock = BigInt.from(timeoutBlockHeight);
    final tokenAddr = isErc20 ? EthereumAddress.fromHex(tokenAddress) : null;

    final signature = destination != null
        ? await _signClaimAuthorization(
            preimage: preimage,
            amount: amount,
            refundAddress: refundAddress,
            timelock: timelock,
            destination: destination,
            isErc20: isErc20,
            tokenAddress: tokenAddr,
            signer: signer,
          )
        : null;

    if (signature != null) {
      final preimageHashBytes = Uint8List.fromList(
        sha256.convert(preimage).bytes,
      );
      final claimAddr = expectedClaimAddress ?? signer.address;
      await _logSwapLookup(
        preimageHashBytes: preimageHashBytes,
        amount: amount,
        claimAddress: claimAddr,
        recoveredAddress: signature.recoveredAddress,
        refundAddress: refundAddress,
        timelock: timelock,
        isErc20: isErc20,
        tokenAddress: tokenAddr,
      );
    }

    return (
      amount: amount,
      preimage: preimage,
      refundAddress: refundAddress,
      timelock: timelock,
      tokenAddress: tokenAddr,
      v: signature?.v ?? BigInt.zero,
      r: signature?.r ?? Uint8List(32),
      s: signature?.s ?? Uint8List(32),
    );
  }

  // ── EIP-712 claim authorization ─────────────────────────────────────

  Future<
    ({BigInt v, Uint8List r, Uint8List s, EthereumAddress recoveredAddress})
  >
  _signClaimAuthorization({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress refundAddress,
    required BigInt timelock,
    required EthereumAddress destination,
    required bool isErc20,
    required EthPrivateKey signer,
    EthereumAddress? tokenAddress,
  }) async {
    final String contractName;
    final BigInt contractVersion;
    final EthereumAddress contractAddress;

    if (isErc20) {
      final erc20Swap = swaps.getERC20SwapContract();
      contractName = 'ERC20Swap';
      contractVersion = await erc20Swap.version();
      contractAddress = erc20Swap.self.address;
    } else {
      final etherSwap = swaps.getEtherSwapContract();
      contractName = 'EtherSwap';
      contractVersion = await etherSwap.version();
      contractAddress = etherSwap.self.address;
    }

    logger.i(
      '$contractName contract version: $contractVersion '
      'at ${contractAddress.eip55With0x}',
    );

    final claimTypeFields = <eip712.MessageTypeProperty>[
      const eip712.MessageTypeProperty(name: 'preimage', type: 'bytes32'),
      const eip712.MessageTypeProperty(name: 'amount', type: 'uint256'),
      if (isErc20)
        const eip712.MessageTypeProperty(name: 'tokenAddress', type: 'address'),
      const eip712.MessageTypeProperty(name: 'refundAddress', type: 'address'),
      const eip712.MessageTypeProperty(name: 'timelock', type: 'uint256'),
      const eip712.MessageTypeProperty(name: 'destination', type: 'address'),
    ];

    final message = <String, dynamic>{
      'preimage': bytesToHex(preimage, include0x: true),
      'amount': amount,
      if (isErc20) 'tokenAddress': tokenAddress!.eip55With0x,
      'refundAddress': refundAddress.eip55With0x,
      'timelock': timelock,
      'destination': destination.eip55With0x,
    };

    final typedData = eip712.TypedMessage(
      types: {
        eip712.EIP712Domain.type: [
          const eip712.MessageTypeProperty(name: 'name', type: 'string'),
          const eip712.MessageTypeProperty(name: 'version', type: 'string'),
          const eip712.MessageTypeProperty(name: 'chainId', type: 'uint256'),
          const eip712.MessageTypeProperty(
            name: 'verifyingContract',
            type: 'address',
          ),
        ],
        'Claim': claimTypeFields,
      },
      primaryType: 'Claim',
      domain: eip712.EIP712Domain(
        name: contractName,
        version: '$contractVersion',
        chainId: BigInt.from(chainId),
        verifyingContract: contractAddress,
        salt: null,
      ),
      message: message,
    );

    final hash = eip712.hashTypedData(
      typedData: typedData,
      version: eip712.TypedDataVersion.v4,
    );
    final sig = sign(hash, signer.privateKey);
    final r = padUint8ListTo32(unsignedIntToBytes(sig.r));
    final s = padUint8ListTo32(unsignedIntToBytes(sig.s));
    final recoveredPubKey = ecRecover(hash, MsgSignature(sig.r, sig.s, sig.v));
    final recoveredAddress = EthereumAddress(
      publicKeyToAddress(recoveredPubKey),
    );

    logger.i(
      'Prepared $contractName claim signature from ${signer.address.eip55With0x} '
      'to destination ${destination.eip55With0x} '
      '(recovered=${recoveredAddress.eip55With0x})',
    );

    return (
      v: BigInt.from(sig.v),
      r: r,
      s: s,
      recoveredAddress: recoveredAddress,
    );
  }

  // ── Swap-key verification logging ──────────────────────────────────

  Future<void> _logSwapLookup({
    required Uint8List preimageHashBytes,
    required BigInt amount,
    required EthereumAddress claimAddress,
    required EthereumAddress recoveredAddress,
    required EthereumAddress refundAddress,
    required BigInt timelock,
    required bool isErc20,
    EthereumAddress? tokenAddress,
  }) async {
    if (isErc20) {
      final erc20Swap = swaps.getERC20SwapContract();
      final expectedSwapKey = await erc20Swap.hashValues((
        preimageHash: preimageHashBytes,
        amount: amount,
        tokenAddress: tokenAddress!,
        claimAddress: claimAddress,
        refundAddress: refundAddress,
        timelock: timelock,
      ));
      final expectedExists = await erc20Swap.swaps(($param94: expectedSwapKey));

      final recoveredSwapKey = await erc20Swap.hashValues((
        preimageHash: preimageHashBytes,
        amount: amount,
        tokenAddress: tokenAddress,
        claimAddress: recoveredAddress,
        refundAddress: refundAddress,
        timelock: timelock,
      ));
      final recoveredExists = await erc20Swap.swaps((
        $param94: recoveredSwapKey,
      ));

      logger.i(
        'ERC20Swap lockup lookup: '
        'expectedClaimAddress=${claimAddress.eip55With0x} '
        'exists=$expectedExists, '
        'recoveredClaimAddress=${recoveredAddress.eip55With0x} '
        'exists=$recoveredExists, '
        'preimageHash=${bytesToHex(preimageHashBytes, include0x: true)}',
      );
    } else {
      final etherSwap = swaps.getEtherSwapContract();
      final expectedSwapKey = await etherSwap.hashValues((
        preimageHash: preimageHashBytes,
        amount: amount,
        claimAddress: claimAddress,
        refundAddress: refundAddress,
        timelock: timelock,
      ));
      final expectedExists = await etherSwap.swaps(($param77: expectedSwapKey));

      final recoveredSwapKey = await etherSwap.hashValues((
        preimageHash: preimageHashBytes,
        amount: amount,
        claimAddress: recoveredAddress,
        refundAddress: refundAddress,
        timelock: timelock,
      ));
      final recoveredExists = await etherSwap.swaps((
        $param77: recoveredSwapKey,
      ));

      logger.i(
        'EtherSwap lockup lookup: '
        'expectedClaimAddress=${claimAddress.eip55With0x} '
        'exists=$expectedExists, '
        'recoveredClaimAddress=${recoveredAddress.eip55With0x} '
        'exists=$recoveredExists, '
        'preimageHash=${bytesToHex(preimageHashBytes, include0x: true)}',
      );
    }
  }
}
