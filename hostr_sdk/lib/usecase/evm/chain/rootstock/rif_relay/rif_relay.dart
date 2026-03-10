import 'dart:typed_data';

import 'package:eip712/eip712.dart' as eip712;
import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../../config.dart';
import '../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../datasources/contracts/rif_relay/IForwarder.g.dart';
import '../../../../../datasources/contracts/rif_relay/SmartWalletFactory.g.dart';
import '../../../../../datasources/swagger_generated/rif_relay.swagger.dart'
    as relay_api;
import '../../../../../util/main.dart';

// THIS FILE SHOULD MIRROR JS IMPLEMENTATION: https://github.com/rsksmart/rif-relay-client
// AND https://github.com/BoltzExchange/boltz-web-app/blob/main/src/rif/Signer.ts

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
typedef ClaimArgs = ({
  BigInt amount,
  Uint8List preimage,
  Uint8List r,
  EthereumAddress refundAddress,
  Uint8List s,
  BigInt timelock,
  BigInt v,
});

class RifMetadata {
  String? signature;
  int relayMaxNonce;
  String relayHubAddress;
  RifMetadata({
    this.signature,
    required this.relayMaxNonce,
    required this.relayHubAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      'relayMaxNonce': relayMaxNonce,
      'relayHubAddress': relayHubAddress,
    };
  }
}

class SmartWalletAddressInfo {
  final BigInt nonce;
  final EthereumAddress address;
  const SmartWalletAddressInfo({required this.nonce, required this.address});
}

// ---------------------------------------------------------------------------
// Extended request types – adds fields missing from the swagger spec
// (validUntilTime, index, recoverer).
// ---------------------------------------------------------------------------

/// Relay-path request (smart wallet already deployed).
/// Adds [validUntilTime] on top of the swagger [relay_api.ForwardRequest].
class RelayForwardRequest extends relay_api.ForwardRequest {
  final int validUntilTime;

  const RelayForwardRequest({
    required this.validUntilTime,
    super.relayHub,
    super.from,
    super.to,
    super.tokenContract,
    super.value,
    super.gas,
    super.nonce,
    super.tokenAmount,
    super.tokenGas,
    super.data,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'validUntilTime': validUntilTime,
  };
}

/// Deploy-path request (smart wallet not yet deployed).
/// Adds [validUntilTime], [index], and [recoverer]; omits `gas`.
class DeployForwardRequest extends relay_api.ForwardRequest {
  final int validUntilTime;
  final int index;
  final String recoverer;

  const DeployForwardRequest({
    required this.validUntilTime,
    required this.index,
    required this.recoverer,
    super.relayHub,
    super.from,
    super.to,
    super.tokenContract,
    super.value,
    super.nonce,
    super.tokenAmount,
    super.tokenGas,
    super.data,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.remove('gas'); // deploy path must not include `gas`
    return {
      ...json,
      'validUntilTime': validUntilTime,
      'index': index,
      'recoverer': recoverer,
    };
  }
}

// ---------------------------------------------------------------------------
// Constants – aligned with rsksmart/rif-relay-client TypeScript reference
// ---------------------------------------------------------------------------

const String _zeroAddress = '0x0000000000000000000000000000000000000000';
const int _maxRelayNonceGap = 10;
const int _defaultGasNeededToClaim = 400000;
const int _defaultGasNeededToEscrowClaim = 300000;

/// Observed gas for a deploy-path EtherSwap.claim relay (~243k) + 15% buffer.
const int _estimatedDeployClaimGas = 280000;

/// Observed gas for a relay-path (already deployed) EtherSwap.claim (~180k) + 15% buffer.
const int _estimatedRelayClaimGas = 210000;
const int _validUntilSeconds = 172800;
const int _maxRelayGasRetries = 1;

/// Gas price multiplier (0 = no boost, 20 = +20 %).
/// Mirrors `gasPriceFactorPercent` in the TS client.
const int _gasPriceFactorPercent = 0;

/// Overhead constants from the TS gas estimator (`gasEstimator/utils.ts`).
const int _preRelayGasCost = 74000;
const int _postRelayDeployGasCost = 33500;
const int _postDeployExecution = 1500;
// Storage refund (15_000) can be subtracted when nonce > 0, but we
// conservatively omit it in the fallback to avoid under-estimation.

/// How long to cache `/chain-info` responses (seconds).
const int _chainInfoTtlSeconds = 45;

/// Minimum RBTC balance (in wei) the relay worker should have.
/// ~0.001 RBTC – enough for several relay transactions.
final BigInt _minWorkerBalance = BigInt.from(10).pow(15); // 0.001 RBTC

// ---------------------------------------------------------------------------
// RifRelay
// ---------------------------------------------------------------------------

@Injectable()
class RifRelay {
  final CustomLogger _logger;
  final Web3Client client;
  final HostrConfig config;

  /// Generated Chopper API client for the RIF Relay server.
  final relay_api.RifRelay _api;

  /// Cached chain info and its fetch timestamp.
  relay_api.PingResponse? _chainInfoCache;
  DateTime? _chainInfoCacheTime;

  RifRelay(this.config, @factoryParam this.client, CustomLogger logger)
    : _logger = logger.scope('rif-relay'),
      _api = relay_api.RifRelay.create(
        baseUrl: Uri.parse(config.rootstockConfig.boltz.rifRelayUrl),
      );

  // -------------------------------------------------------------------------
  // Chain info (cached)
  // -------------------------------------------------------------------------

  /// Returns cached [PingResponse] if still fresh, otherwise fetches anew.
  Future<relay_api.PingResponse> _getCachedChainInfo() =>
      _logger.span('_getCachedChainInfo', () async {
        final now = DateTime.now();
        if (_chainInfoCache != null &&
            _chainInfoCacheTime != null &&
            now.difference(_chainInfoCacheTime!).inSeconds <
                _chainInfoTtlSeconds) {
          return _chainInfoCache!;
        }
        final info = await getChainInfo();
        _chainInfoCache = info;
        _chainInfoCacheTime = now;
        return info;
      });

  /// Http GET request to the relay server to get the metadata.
  /// Uses the generated Chopper API client for transport.
  Future<relay_api.PingResponse> getChainInfo() =>
      _logger.span('getChainInfo', () async {
        final response = await _api.chainInfoGet();
        return response.bodyOrThrow;
      });

  // -------------------------------------------------------------------------
  // HTTP: /estimate and /relay
  // -------------------------------------------------------------------------

  Future<relay_api.EstimatePost$Response> estimateClaim(
    relay_api.RelayTransactionRequest request,
  ) => _logger.span('estimateClaim', () async {
    _logger.d('RIF relay /estimateClaim request: $request');

    final response = await _api.estimatePost(body: request.toJson());
    if (response.bodyString.contains('error')) {
      throw response.bodyString;
    }
    _logger.d('RIF relay /estimateClaim response: ${response.bodyString}');

    return response.bodyOrThrow;
  });

  Future<relay_api.RelayTransactionRequest> _buildRelayTransactionRequest(
    EtherSwap etherSwap,
    EthPrivateKey signer,
    ClaimArgs args,
  ) => _logger.span('_buildRelayTransactionRequest', () async {
    // Encode EtherSwap.claim(preimage, amount, refundAddress, timelock) calldata
    // — 4-param overload (selector 0xc3c37fbc), msg.sender = smart wallet = claimAddress.
    final claimFunction = etherSwap.self.abi.functions.firstWhere(
      (f) => f.name == 'claim' && f.parameters.length == 4,
    );
    final claimCalldata = bytesToHex(
      claimFunction.encodeCall([
        args.preimage,
        args.amount,
        args.refundAddress,
        args.timelock,
      ]),
      include0x: true,
    );
    _logger.d('Claim calldata: $claimCalldata');

    final info = await _getCachedChainInfo();
    final smartWalletInfo = await getSmartWalletAddress(signer);

    // Determine deploy vs relay by checking on-chain bytecode at the
    // computed smart-wallet address.  Matches Boltz TS:
    //   const smartWalletExists = (await getCode(address)) !== "0x";
    // With the walletIndex=factoryNonce fix, this should always be deploy
    // (new wallet for each claim), but the check keeps the relay path
    // available if a wallet at that index somehow already exists.
    final codeAtWallet = await client.getCode(smartWalletInfo.address);
    final isDeploy = codeAtWallet.isEmpty;

    // For the relay path (wallet already deployed), the ForwardRequest nonce
    // must be the smart wallet's internal IForwarder anti-replay nonce — NOT
    // the factory nonce.  The factory nonce counts deployments; IForwarder
    // nonce counts relayed calls.  Mirrors TS:
    //   deploy → IWalletFactory.nonce(from)
    //   relay  → IForwarder(callForwarder).nonce()
    final BigInt forwardRequestNonce;
    if (isDeploy) {
      forwardRequestNonce = smartWalletInfo.nonce;
    } else {
      final forwarder = getForwarder(smartWalletInfo.address);
      forwardRequestNonce = await forwarder.nonce();
      _logger.d(
        'IForwarder nonce for ${smartWalletInfo.address.eip55With0x}: '
        '$forwardRequestNonce (factory nonce: ${smartWalletInfo.nonce})',
      );
    }

    // Effective gas price (floor to relay minGasPrice).
    // PingResponse.minGasPrice is typed String? but the server may return an
    // int, so we toString() it before parsing.
    final gasPrice = await client.getGasPrice();
    final minGasPrice =
        BigInt.tryParse(info.minGasPrice?.toString() ?? '') ?? BigInt.zero;
    final effectiveGasPrice = gasPrice.getInWei > minGasPrice
        ? gasPrice.getInWei
        : minGasPrice;

    // Relay worker nonce for metadata.relayMaxNonce.
    final workerAddress = info.relayWorkerAddress.toString();
    final workerNonce = await client.getTransactionCount(
      EthereumAddress.fromHex(workerAddress),
    );

    // validUntilTime (48h from now).
    final validUntilTime =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + _validUntilSeconds;

    final relayHubAddr = info.relayHubAddress.toString();

    // --- Build typed parts using swagger types ---
    final metadata = relay_api.RelayMetadata(
      relayHubAddress: relayHubAddr,
      relayMaxNonce: (workerNonce + _maxRelayNonceGap).toDouble(),
      signature: 'SERVER_SIGNATURE_REQUIRED',
    );

    // feesReceiver = relay worker address (PingResponse lacks the field, but
    // the server's /chain-info returns feesReceiver == relayWorkerAddress).
    //
    // callVerifier: The Boltz web-app always uses the deployVerifier for both
    // deploy and relay paths. The relay server's verifier contract must match
    // what was registered on-chain.
    final relayData = relay_api.RelayData(
      gasPrice: effectiveGasPrice.toString(),
      feesReceiver: workerAddress,
      callForwarder: isDeploy
          ? config.rootstockConfig.boltz.rifSmartWalletFactoryAddress
          : smartWalletInfo.address.eip55With0x,
      callVerifier: config.rootstockConfig.boltz.rifRelayDeployVerifier,
    );

    final relay_api.ForwardRequest request;
    if (isDeploy) {
      request = DeployForwardRequest(
        validUntilTime: validUntilTime,
        index: smartWalletInfo.nonce.toInt(),
        recoverer: _zeroAddress,
        relayHub: relayHubAddr,
        from: signer.address.eip55With0x,
        to: etherSwap.self.address.eip55With0x,
        tokenContract: _zeroAddress,
        value: '0',
        nonce: forwardRequestNonce.toString(),
        tokenAmount: '0',
        tokenGas: '0',
        data: claimCalldata,
      );
    } else {
      request = RelayForwardRequest(
        validUntilTime: validUntilTime,
        relayHub: relayHubAddr,
        from: signer.address.eip55With0x,
        to: etherSwap.self.address.eip55With0x,
        tokenContract: _zeroAddress,
        value: '0',
        gas: _defaultGasNeededToClaim.toString(),
        nonce: forwardRequestNonce.toString(),
        tokenAmount: '0',
        tokenGas: '0',
        data: claimCalldata,
      );
    }

    return relay_api.RelayTransactionRequest(
      metadata: metadata,
      relayRequest: relay_api.RelayRequest(
        request: request,
        relayData: relayData,
      ),
    );
  });

  /// Relays an EtherSwap.claim via the RIF Relay server.
  ///
  /// Mirrors the Boltz web-app `relayClaimTransaction` flow:
  /// 1. Builds the relay request with placeholder tokenGas/tokenAmount.
  /// 2. POSTs to `/estimate` (unsigned — `SERVER_SIGNATURE_REQUIRED`).
  /// 3. Updates the request with the server's `estimation` → `tokenGas`
  ///    and `requiredTokenAmount` → `tokenAmount`.
  /// 4. Signs the *updated* request with EIP-712.
  /// 5. POSTs to `/relay`.
  Future<relay_api.RelayPost$Response> relayClaim(
    EtherSwap etherSwap,
    EthPrivateKey signer,
    ClaimArgs args,
  ) => _logger.span('relayClaim', () async {
    _logger.d('RIF relay /relayClaim');

    final relayTransactionRequest = await _buildRelayTransactionRequest(
      etherSwap,
      signer,
      args,
    );
    final relayRequest = relayTransactionRequest.relayRequest!;
    final originalRequest = relayRequest.request!;
    final relayData = relayRequest.relayData!;
    final isDeploy = originalRequest is DeployForwardRequest;

    // -- 1. Estimate (unsigned) --
    relay_api.EstimatePost$Response? estimateResponse;

    // Do not estimate on deploy, since smart wallet does not yet exist so we cannot estimate reliably
    if (!isDeploy) {
      estimateResponse = await estimateClaim(relayTransactionRequest);
      _logger.d(
        'RIF estimate response: '
        'gasPrice=${estimateResponse.gasPrice}, '
        'estimation=${estimateResponse.estimation}, '
        'requiredTokenAmount=${estimateResponse.requiredTokenAmount}',
      );
    }

    final updatedTokenGas = estimateResponse?.estimation ?? '0';
    final updatedTokenAmount = estimateResponse?.requiredTokenAmount ?? '0';
    // -- 2. Update request with estimate results --
    // Mirrors TS: request.tokenGas = estimateRes.estimation
    //             request.tokenAmount = estimateRes.requiredTokenAmount

    final relay_api.ForwardRequest updatedRequest;
    if (isDeploy) {
      final deploy = originalRequest;
      updatedRequest = DeployForwardRequest(
        validUntilTime: deploy.validUntilTime,
        index: deploy.index,
        recoverer: deploy.recoverer,
        relayHub: deploy.relayHub,
        from: deploy.from,
        to: deploy.to,
        tokenContract: deploy.tokenContract,
        value: deploy.value,
        nonce: deploy.nonce,
        tokenAmount: updatedTokenAmount,
        tokenGas: updatedTokenGas,
        data: deploy.data,
      );
    } else {
      final rel = originalRequest as RelayForwardRequest;
      updatedRequest = RelayForwardRequest(
        validUntilTime: rel.validUntilTime,
        relayHub: rel.relayHub,
        from: rel.from,
        to: rel.to,
        tokenContract: rel.tokenContract,
        value: rel.value,
        gas: rel.gas,
        nonce: rel.nonce,
        tokenAmount: updatedTokenAmount,
        tokenGas: updatedTokenGas,
        data: rel.data,
      );
    }

    final updatedRelayRequest = relay_api.RelayRequest(
      request: updatedRequest,
      relayData: relayData,
    );

    // -- 3. EIP-712 signature (over the updated request) --
    final verifyingContract = relayData.callForwarder! as String;

    final signature = _signRelayRequest(
      signer: signer,
      request: updatedRequest,
      relayData: relayData,
      chainId: config.rootstockConfig.chainId,
      verifyingContract: verifyingContract,
      isDeploy: isDeploy,
    );

    // Replace the placeholder metadata signature with the real one.
    final signed = relay_api.RelayTransactionRequest(
      metadata: relayTransactionRequest.metadata!.copyWith(
        signature: signature,
      ),
      relayRequest: updatedRelayRequest,
    );

    // -- 4. Relay (signed) --
    final requestJson = signed.toJson();
    _logger.d('Relay request JSON: $requestJson');

    final response = await _api.relayPost(body: requestJson);

    // The relay server may return HTTP 200 with an error body instead of
    // signedTx/txHash.  Detect this before returning a response with null
    // fields that would cascade into an "invalid string length" RPCError.
    final bodyStr = response.bodyString;
    if (bodyStr.contains('"error"')) {
      throw Exception('RIF relay server returned an error: $bodyStr');
    }

    final relayResponse = response.bodyOrThrow;
    if (relayResponse.signedTx == null && relayResponse.txHash == null) {
      throw Exception(
        'RIF relay server returned empty response '
        '(no signedTx or txHash): $bodyStr',
      );
    }

    return relayResponse;
  });

  // -------------------------------------------------------------------------
  // EIP-712 signing
  // -------------------------------------------------------------------------

  /// Signs a relay/deploy request using EIP-712 typed data v4.
  ///
  /// Mirrors the TS `getLocalEip712Signature` / `getLocalEip712DeploySignature`
  /// from `rif-relay-contracts/test/utils/EIP712Utils.ts`.
  String _signRelayRequest({
    required EthPrivateKey signer,
    required relay_api.ForwardRequest request,
    required relay_api.RelayData relayData,
    required int chainId,
    required String verifyingContract,
    required bool isDeploy,
  }) => _logger.spanSync('_signRelayRequest', () {
    // EIP-712 type definitions – must match the Solidity structs exactly.
    final relayDataType = [
      const eip712.MessageTypeProperty(name: 'gasPrice', type: 'uint256'),
      const eip712.MessageTypeProperty(name: 'feesReceiver', type: 'address'),
      const eip712.MessageTypeProperty(name: 'callForwarder', type: 'address'),
      const eip712.MessageTypeProperty(name: 'callVerifier', type: 'address'),
    ];

    final List<eip712.MessageTypeProperty> requestFieldTypes;
    if (isDeploy) {
      requestFieldTypes = [
        const eip712.MessageTypeProperty(name: 'relayHub', type: 'address'),
        const eip712.MessageTypeProperty(name: 'from', type: 'address'),
        const eip712.MessageTypeProperty(name: 'to', type: 'address'),
        const eip712.MessageTypeProperty(
          name: 'tokenContract',
          type: 'address',
        ),
        const eip712.MessageTypeProperty(name: 'recoverer', type: 'address'),
        const eip712.MessageTypeProperty(name: 'value', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'nonce', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'tokenAmount', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'tokenGas', type: 'uint256'),
        const eip712.MessageTypeProperty(
          name: 'validUntilTime',
          type: 'uint256',
        ),
        const eip712.MessageTypeProperty(name: 'index', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'data', type: 'bytes'),
        const eip712.MessageTypeProperty(name: 'relayData', type: 'RelayData'),
      ];
    } else {
      requestFieldTypes = [
        const eip712.MessageTypeProperty(name: 'relayHub', type: 'address'),
        const eip712.MessageTypeProperty(name: 'from', type: 'address'),
        const eip712.MessageTypeProperty(name: 'to', type: 'address'),
        const eip712.MessageTypeProperty(
          name: 'tokenContract',
          type: 'address',
        ),
        const eip712.MessageTypeProperty(name: 'value', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'gas', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'nonce', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'tokenAmount', type: 'uint256'),
        const eip712.MessageTypeProperty(name: 'tokenGas', type: 'uint256'),
        const eip712.MessageTypeProperty(
          name: 'validUntilTime',
          type: 'uint256',
        ),
        const eip712.MessageTypeProperty(name: 'data', type: 'bytes'),
        const eip712.MessageTypeProperty(name: 'relayData', type: 'RelayData'),
      ];
    }

    // Flatten request fields + nested relayData into the EIP-712 message,
    // matching the TS: `{ ...relayRequest.request, relayData: relayRequest.relayData }`
    final requestJson = request.toJson();
    final relayDataJson = relayData.toJson();
    final message = <String, dynamic>{
      ...requestJson,
      'relayData': relayDataJson,
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
        'RelayRequest': requestFieldTypes,
        'RelayData': relayDataType,
      },
      primaryType: 'RelayRequest',
      domain: eip712.EIP712Domain(
        name: 'RSK Enveloping Transaction',
        version: '2',
        chainId: BigInt.from(chainId),
        verifyingContract: EthereumAddress.fromHex(verifyingContract),
        salt: null,
      ),
      message: message,
    );

    // Hash according to EIP-712.
    final hash = eip712.hashTypedData(
      typedData: typedData,
      version: eip712.TypedDataVersion.v4,
    );

    // Sign the hash directly (web3dart's `sign` takes a pre-hashed message).
    final sig = sign(hash, signer.privateKey);

    // Pack into 65-byte hex: r (32) + s (32) + v (1)
    final r = padUint8ListTo32(unsignedIntToBytes(sig.r));
    final s = padUint8ListTo32(unsignedIntToBytes(sig.s));
    final v = Uint8List.fromList([sig.v]);

    final packed = Uint8List(65);
    packed.setRange(0, 32, r);
    packed.setRange(32, 64, s);
    packed.setRange(64, 65, v);

    return bytesToHex(packed, include0x: true);
  });

  // -------------------------------------------------------------------------
  // Smart wallet helpers
  // -------------------------------------------------------------------------

  /// Returns the smart wallet address for [signer].
  ///
  /// Matches Boltz web-app behavior: every claim deploys a NEW smart wallet.
  /// The wallet index = current factory nonce, so the address is always for a
  /// wallet that hasn't been deployed yet.  After deployCall succeeds the
  /// factory nonce increments and the next call returns a fresh address.
  ///
  /// The returned [SmartWalletAddressInfo.nonce] is the current factory nonce
  /// and doubles as both the deploy-request `index` and `nonce` fields.
  Future<SmartWalletAddressInfo> getSmartWalletAddress(EthPrivateKey signer) =>
      _logger.span('getSmartWalletAddress', () async {
        final factory = _getSmartWalletFactory();
        final factoryNonce = await factory.nonce((from: signer.address));

        // Use factoryNonce as the wallet index — this always points to the NEXT
        // wallet that hasn't been deployed yet, matching the Boltz TS:
        //   const smartWalletAddress = await factory.getSmartWalletAddress(
        //       signerAddress, ZeroAddress, nonce);
        final walletIndex = factoryNonce;

        final smartWalletAddress = await factory.getSmartWalletAddress((
          owner: signer.address,
          recoverer: EthereumAddress.fromHex(_zeroAddress),
          index: walletIndex,
        ));
        _logger.d(
          'RIF smart wallet address $smartWalletAddress '
          '(factory nonce $factoryNonce, wallet index $walletIndex)',
        );
        return SmartWalletAddressInfo(
          nonce: factoryNonce,
          address: smartWalletAddress,
        );
      });

  SmartWalletFactory _getSmartWalletFactory() {
    final factoryAddress =
        config.rootstockConfig.boltz.rifSmartWalletFactoryAddress;
    if (factoryAddress.isEmpty) {
      throw StateError('Missing rifSmartWalletFactoryAddress in Config.');
    }
    return SmartWalletFactory(
      address: EthereumAddress.fromHex(factoryAddress),
      client: client,
    );
  }

  IForwarder getForwarder(EthereumAddress forwarderAddress) {
    return IForwarder(address: forwarderAddress, client: client);
  }

  /// Lock-independent estimate using gas constants × current gas price.
  ///
  /// Returns the estimated relay fee in wei. This does NOT call the relay
  /// server's `/estimate` endpoint (which requires the swap to exist on-chain)
  /// — instead it uses a conservative gas constant derived from observed
  /// deploy/relay claim transactions.
  ///
  /// Only [signer] is needed to determine the deploy-vs-relay path.
  Future<BigInt> estimateClaimBeforeLock(EthPrivateKey evmKey) => _logger.span(
    'estimateClaimBeforeLock',
    () async {
      // Boltz subsidizes these claim relays
      return BitcoinAmount.zero().getInWei;
      // final info = await _getCachedChainInfo();
      // final smartWalletInfo = await getSmartWalletAddress(evmKey);
      // final isDeploy = smartWalletInfo.nonce == BigInt.zero;

      // final gasPrice = await client.getGasPrice();
      // final minGasPrice =
      //     BigInt.tryParse(info.minGasPrice?.toString() ?? '') ?? BigInt.zero;
      // final effectiveGasPrice = gasPrice.getInWei > minGasPrice
      //     ? gasPrice.getInWei
      //     : minGasPrice;

      // final gasEstimate = BigInt.from(
      //   isDeploy ? _estimatedDeployClaimGas : _estimatedRelayClaimGas,
      // );

      // final fee = effectiveGasPrice * gasEstimate;
      // _logger.d(
      //   'estimateClaimBeforeLock: isDeploy=$isDeploy, '
      //   'gasPrice=$effectiveGasPrice, gas=$gasEstimate, fee=$fee wei',
      // );
      // return fee;
    },
  );
}
