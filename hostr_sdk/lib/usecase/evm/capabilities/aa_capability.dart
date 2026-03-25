import 'package:convert/convert.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../util/custom_logger.dart';
import '../call_intent.dart';
import '../config/evm_config.dart';

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

  /// Send one or more contract calls as a single batched UserOperation.
  ///
  /// For a single call, pass a one-element list. For atomic multi-step flows
  /// (e.g. ERC-20 approve + lock), pass multiple intents.
  /// Returns the on-chain transaction hash.
  Future<String> sendUserOp(
    EthPrivateKey signer,
    List<CallIntent> intents,
  ) => _logger.span(
    'AACapability.sendUserOp(${intents.map((i) => i.methodName).join(", ")})',
    () async {
      return _sendCalls(signer, intents);
    },
  );

  /// Estimated gas fee — zero when the paymaster sponsors gas.
  Future<BigInt> estimateGasFee(EthPrivateKey signer) async => BigInt.zero;

  // ── Internals ─────────────────────────────────────────────────────

  Future<String> _sendCalls(
    EthPrivateKey signer,
    List<CallIntent> intents,
  ) async {
    final publicClient = _initPublicClient();
    final bundler = _initPimlicoClient();
    final account = _initSimpleAccount(signer, publicClient: publicClient);
    final smartAccountAddress = await account.getAddress();
    final isDeployed = await publicClient.isDeployed(smartAccountAddress);

    _logger.i(
      'sendUserOp: smartAccount=${smartAccountAddress.hex}, '
      'deployed=$isDeployed, chainId=$_chainId, '
      'calls=[${intents.map((i) => '${i.methodName}→${i.to.hex}').join(', ')}]',
    );

    final client = _initSmartAccountClient(
      signer,
      publicClient: publicClient,
      bundler: bundler,
    );
    final feeQuote = await _getFeeQuote(bundler, publicClient);
    final calls = intents.map(_toPermissionlessCall).toList();

    _logger.d(
      'sendUserOp fee: maxFeePerGas=${feeQuote.maxFeePerGas}, '
      'maxPriorityFeePerGas=${feeQuote.maxPriorityFeePerGas}',
    );

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

  permissionless.Call _toPermissionlessCall(CallIntent intent) =>
      permissionless.Call(
        to: intent.to,
        value: intent.value.getInWei,
        data: '0x${hex.encode(intent.data)}',
      );

  permissionless.SmartAccountClient _initSmartAccountClient(
    EthPrivateKey signer, {
    required permissionless.PublicClient publicClient,
    required permissionless.BundlerClient bundler,
  }) {
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

  permissionless.PimlicoClient _initPimlicoClient() =>
      permissionless.createPimlicoClient(
        url: _aaConfig.bundlerUrl,
        entryPoint: _entryPointAddress,
      );

  Future<({BigInt maxFeePerGas, BigInt maxPriorityFeePerGas})> _getFeeQuote(
    permissionless.PimlicoClient bundler,
    permissionless.PublicClient publicClient,
  ) async {
    // Prefer the bundler's recommended gas price — it reflects the
    // minimum the bundler will accept, which can be higher than the
    // node's eth_gasPrice on L2s like Arbitrum.
    try {
      final gasPrices = await bundler.getUserOperationGasPrice();
      final fast = gasPrices.fast;
      return (
        maxFeePerGas: fast.maxFeePerGas,
        maxPriorityFeePerGas: fast.maxPriorityFeePerGas,
      );
    } catch (e) {
      _logger.w('Bundler gas price unavailable, falling back to node: $e');
    }

    // Fallback: derive from the node's fee data.
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
