import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../config.dart';
import '../../../util/custom_logger.dart';
import '../contract_call_intent.dart';

/// ERC-4337 Account Abstraction service powered by
/// [permissionless](https://pub.dev/packages/permissionless).
///
/// Wraps a permissionless Simple smart account and client stack to send
/// gas-sponsored ERC-4337 UserOperations through the configured bundler and
/// paymaster.
@injectable
class UserOpService {
  final CustomLogger _logger;
  final int _chainId;
  final String _nodeRpcUrl;
  final AccountAbstractionConfig _aaConfig;

  UserOpService(HostrConfig config, CustomLogger logger)
    : _chainId = config.rootstockConfig.chainId,
      _nodeRpcUrl = config.rootstockConfig.rpcUrl,
      _aaConfig = config.rootstockConfig.accountAbstraction,
      _logger = logger;

  // ── Public API ──────────────────────────────────────────────────────

  /// Counterfactual Simple account address derived from [signer].
  Future<EthereumAddress> getSmartAccountAddress(EthPrivateKey signer) =>
      _logger.span('UserOpService.getSmartAccountAddress', () async {
        final publicClient = _initPublicClient();
        final account = _initSimpleAccount(signer, publicClient: publicClient);
        return account.getAddress();
      });

  /// Send a single contract call as a bundled UserOperation.
  ///
  /// Returns the on-chain transaction hash after the operation is included
  /// in a block.
  Future<String> sendUserOp(EthPrivateKey signer, ContractCallIntent intent) =>
      _logger.span('UserOpService.sendUserOp(${intent.methodName})', () async {
        return _sendCalls(signer, [intent]);
      });

  /// Send multiple calls as a single batched UserOperation.
  ///
  /// All [intents] are executed atomically inside one on-chain transaction.
  Future<String> sendUserOpBatch(
    EthPrivateKey signer,
    List<ContractCallIntent> intents,
  ) => _logger.span('UserOpService.sendUserOpBatch', () async {
    return _sendCalls(signer, intents);
  });

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
