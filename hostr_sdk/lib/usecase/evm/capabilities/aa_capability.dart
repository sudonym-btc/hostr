import 'package:convert/convert.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../util/custom_logger.dart';
import '../config/evm_config.dart';
import '../evm_call.dart';

/// Per-chain ERC-4337 Account Abstraction capability.
///
/// Absorbed from the old singleton [UserOpService]. Each [EvmChain]
/// with AA support holds its own [AACapability] instance parameterized by
/// the chain-specific [AAConfig].
class AACapability {
  final AAConfig _aaConfig;
  final int _chainId;
  final String _nodeRpcUrl;
  final CustomLogger _logger;

  /// Cache of EOA address → counterfactual smart-account address.
  ///
  /// The smart-account address is fully deterministic (CREATE2 from owner +
  /// factory + chainId + entryPoint — all fixed per [AACapability] instance)
  /// so it is safe to cache indefinitely per signer.
  final Map<String, EthereumAddress> _addressCache = {};

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
  ///
  /// Memoised per signer — the CREATE2 address is deterministic for a fixed
  /// (owner, factory, chainId, entryPoint) tuple, so the RPC round-trip only
  /// happens once per signer per [AACapability] lifetime.
  Future<EthereumAddress> getSmartAccountAddress(EthPrivateKey signer) async {
    final cacheKey = signer.address.hex;
    final cached = _addressCache[cacheKey];
    if (cached != null) return cached;
    return _logger.span('AACapability.getSmartAccountAddress', () async {
      final publicClient = _initPublicClient();
      final account = _initSimpleAccount(signer, publicClient: publicClient);
      final address = await account.getAddress();
      _addressCache[cacheKey] = address;
      return address;
    });
  }

  /// Send one or more contract calls as a single batched UserOperation.
  ///
  /// For a single call, pass a one-element map. For atomic multi-step flows
  /// (e.g. ERC-20 approve + lock), pass multiple entries.
  /// Returns the on-chain transaction hash.
  Future<String> sendUserOp(EthPrivateKey signer, Map<String, Call> calls) =>
      _logger.span(
        'AACapability.sendUserOp(${calls.keys.join(", ")})',
        () async {
          return _sendCalls(signer, calls);
        },
      );

  /// Estimate the gas fee for a set of [intents] as a single batched
  /// UserOperation.
  ///
  /// Returns a record containing:
  /// - `gasCostWei`: the maximum gas cost in the chain's native token (wei).
  /// - `gasSponsored`: `true` when a paymaster is configured.
  ///
  /// Even when gas is sponsored, the real cost is returned so the UI can
  /// show it for transparency.
  ///
  /// When [intents] is omitted, a no-op dummy call is used. This gives a
  /// baseline UserOp overhead estimate (verification + pre-verification gas)
  /// which is suitable for operations where the exact calldata isn't known
  /// yet (e.g. swap claim before lockup).
  Future<({BigInt gasCostWei, bool gasSponsored})> estimateGasFee(
    EthPrivateKey signer, {
    required Map<String, Call> calls,
    List<permissionless.StateOverride>? stateOverride,
  }) => _logger.span('AACapability.estimateGasFee', () async {
    final publicClient = _initPublicClient();
    final bundler = _initPimlicoClient();
    final client = _initSmartAccountClient(
      signer,
      publicClient: publicClient,
      bundler: bundler,
    );

    final feeQuote = await _getFeeQuote(bundler, publicClient);
    final callList = calls.values.toList();

    final userOp = await client.prepareUserOperation(
      calls: callList,
      maxFeePerGas: feeQuote.maxFeePerGas,
      maxPriorityFeePerGas: feeQuote.maxPriorityFeePerGas,
      stateOverride: stateOverride,
    );

    final gasCostWei = permissionless.getRequiredPrefund(userOp);

    _logger.d(
      'estimateGasFee: prefund=$gasCostWei wei, '
      'maxFeePerGas=${feeQuote.maxFeePerGas}',
    );
    client.close();

    return (
      gasCostWei: gasCostWei,
      gasSponsored: _aaConfig.paymasterAddress.isNotEmpty,
    );
  });

  // ── Internals ─────────────────────────────────────────────────────

  Future<String> _sendCalls(
    EthPrivateKey signer,
    Map<String, Call> namedCalls,
  ) async {
    final publicClient = _initPublicClient();
    final bundler = _initPimlicoClient();
    final account = _initSimpleAccount(signer, publicClient: publicClient);
    final smartAccountAddress = await account.getAddress();
    final isDeployed = await publicClient.isDeployed(smartAccountAddress);

    _logger.i(
      'sendUserOp: smartAccount=${smartAccountAddress.hex}, '
      'deployed=$isDeployed, chainId=$_chainId, '
      'calls=[${namedCalls.entries.map((e) => '${e.key}→${e.value.to.hex}').join(', ')}]',
    );

    final client = _initSmartAccountClient(
      signer,
      publicClient: publicClient,
      bundler: bundler,
    );
    final feeQuote = await _getFeeQuote(bundler, publicClient);
    final calls = namedCalls.values.toList();

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
