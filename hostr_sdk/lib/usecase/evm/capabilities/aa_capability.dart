import 'package:convert/convert.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../util/custom_logger.dart';
import '../config/evm_config.dart';
import '../contract_call_intent.dart';

/// Per-chain ERC-4337 Account Abstraction capability.
///
/// Absorbed from the old singleton [UserOpService]. Each [ConfiguredEvmChain]
/// with AA support holds its own [AACapability] instance parameterized by
/// the chain-specific [AAConfig].
class AACapability {
  final AAConfig _aaConfig;
  final int _chainId;
  final String _nodeRpcUrl;
  final CustomLogger _logger;

  AACapability({
    required AAConfig aaConfig,
    required int chainId,
    required String nodeRpcUrl,
    required CustomLogger logger,
  }) : _aaConfig = aaConfig,
       _chainId = chainId,
       _nodeRpcUrl = nodeRpcUrl,
       _logger = logger;

  // ── Public API ──────────────────────────────────────────────────────

  /// Counterfactual Simple account address derived from [signer].
  Future<EthereumAddress> getSmartAccountAddress(EthPrivateKey signer) =>
      _logger.span('AACapability.getSmartAccountAddress', () async {
        final publicClient = _initPublicClient();
        final account = _initSimpleAccount(signer, publicClient: publicClient);
        return account.getAddress();
      });

  /// Send a single contract call as a bundled UserOperation.
  ///
  /// Returns the on-chain transaction hash after the operation is included
  /// in a block.
  Future<String> sendUserOp(EthPrivateKey signer, ContractCallIntent intent) =>
      _logger.span('AACapability.sendUserOp(${intent.methodName})', () async {
        return _sendCalls(signer, [intent]);
      });

  /// Send multiple contract calls as a single batched UserOperation.
  ///
  /// This is useful for atomic multi-step flows such as ERC-20 approve + lock.
  /// Returns the on-chain transaction hash.
  Future<String> sendBatchUserOps(
    EthPrivateKey signer,
    List<ContractCallIntent> intents,
  ) => _logger.span(
    'AACapability.sendBatchUserOps(${intents.map((i) => i.methodName).join(", ")})',
    () async {
      return _sendCalls(signer, intents);
    },
  );

  /// Estimated gas fee — zero when the paymaster sponsors gas.
  Future<BigInt> estimateGasFee(EthPrivateKey signer) async => BigInt.zero;

  // ── Internals ─────────────────────────────────────────────────────

  Future<String> _sendCalls(
    EthPrivateKey signer,
    List<ContractCallIntent> intents,
  ) async {
    final publicClient = _initPublicClient();
    final client = _initSmartAccountClient(signer, publicClient: publicClient);
    final feeQuote = await _getFeeQuote(publicClient);
    final calls = intents.map(_toPermissionlessCall).toList();

    try {
      final receipt = await client.sendUserOperationAndWait(
        calls: calls,
        maxFeePerGas: feeQuote.maxFeePerGas,
        maxPriorityFeePerGas: feeQuote.maxPriorityFeePerGas,
      );

      final txHash = receipt?.receipt?.transactionHash;
      if (txHash == null || txHash.isEmpty) {
        throw StateError('UserOperation confirmed without a transaction hash');
      }

      _logger.i('UserOp confirmed in tx: $txHash');
      return txHash;
    } finally {
      client.close();
    }
  }

  permissionless.Call _toPermissionlessCall(ContractCallIntent intent) =>
      permissionless.Call(
        to: intent.to,
        value: intent.value.getInWei,
        data: '0x${hex.encode(intent.data)}',
      );

  permissionless.SmartAccountClient _initSmartAccountClient(
    EthPrivateKey signer, {
    required permissionless.PublicClient publicClient,
  }) {
    final bundler = permissionless.createBundlerClient(
      url: _aaConfig.bundlerUrl,
      entryPoint: _entryPointAddress,
    );

    final paymaster = _aaConfig.paymasterAddress.isNotEmpty
        ? permissionless.createPaymasterClient(url: _aaConfig.bundlerUrl)
        : null;

    return permissionless.createSmartAccountClient(
      account: _initSimpleAccount(signer, publicClient: publicClient),
      bundler: bundler,
      publicClient: publicClient,
      paymaster: paymaster,
    );
  }

  permissionless.SimpleSmartAccount _initSimpleAccount(
    EthPrivateKey signer, {
    required permissionless.PublicClient publicClient,
  }) => permissionless.createSimpleSmartAccount(
    owner: permissionless.PrivateKeyOwner(_privateKeyHex(signer)),
    chainId: BigInt.from(_chainId),
    entryPointVersion: _entryPointVersion,
    customFactoryAddress: EthereumAddress.fromHex(
      _aaConfig.accountFactoryAddress,
    ),
    publicClient: publicClient,
  );

  permissionless.PublicClient _initPublicClient() =>
      permissionless.createPublicClient(url: _nodeRpcUrl);

  Future<({BigInt maxFeePerGas, BigInt maxPriorityFeePerGas})> _getFeeQuote(
    permissionless.PublicClient publicClient,
  ) async {
    final feeData = await publicClient.getFeeData();
    final maxPriorityFeePerGas =
        feeData.maxPriorityFeePerGas ?? feeData.gasPrice;
    final maxFeePerGas = feeData.gasPrice > maxPriorityFeePerGas
        ? feeData.gasPrice
        : maxPriorityFeePerGas;

    return (
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  permissionless.EntryPointVersion get _entryPointVersion {
    final entryPoint = _entryPointAddress.with0x.toLowerCase();
    if (entryPoint ==
        permissionless.EntryPointAddresses.v06.with0x.toLowerCase()) {
      return permissionless.EntryPointVersion.v06;
    }
    if (entryPoint ==
        permissionless.EntryPointAddresses.v07.with0x.toLowerCase()) {
      return permissionless.EntryPointVersion.v07;
    }
    if (entryPoint ==
        permissionless.EntryPointAddresses.v08.with0x.toLowerCase()) {
      return permissionless.EntryPointVersion.v08;
    }

    throw UnsupportedError(
      'permissionless only supports standard EntryPoint addresses. '
      'Unsupported entry point: ${_aaConfig.entryPointAddress}',
    );
  }

  EthereumAddress get _entryPointAddress =>
      EthereumAddress.fromHex(_aaConfig.entryPointAddress);

  String _privateKeyHex(EthPrivateKey signer) =>
      '0x${hex.encode(signer.privateKey)}';
}
