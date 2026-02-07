import 'dart:convert';
import 'dart:typed_data';

import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/data/sources/rif_relay/contracts/BaseSmartWallet.g.dart';
import 'package:hostr/data/sources/rif_relay/contracts/IForwarder.g.dart';
import 'package:hostr/data/sources/rif_relay/contracts/SmartWalletFactory.g.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

// THIS FILE SHOULD MIRROR JS IMPLEMENTATION: https://github.com/BoltzExchange/boltz-web-app/tree/162ecc350f61460d6f8b888cd873bd5d90e02e29/src/rif
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

class ChainInfo {
  String relayWorkerAddress;
  String feesReceiver;
  String relayManagerAddress;
  String relayHubAddress;
  String minGasPrice;
  String chainId;
  String networkId;
  bool ready;
  String version;
  ChainInfo({
    required this.relayWorkerAddress,
    required this.feesReceiver,
    required this.relayManagerAddress,
    required this.relayHubAddress,
    required this.minGasPrice,
    required this.chainId,
    required this.networkId,
    required this.ready,
    required this.version,
  });
}

class EstimationResponse {
  String gasPrice;
  String estimation;
  String requiredTokenAmount;
  String requiredNativeAmount;
  String exchangeRate;
  EstimationResponse({
    required this.gasPrice,
    required this.estimation,
    required this.requiredTokenAmount,
    required this.requiredNativeAmount,
    required this.exchangeRate,
  });
}

class RelayResponse {
  final String txHash;
  RelayResponse({required this.txHash});
}

class EnvelopingRequest {
  late Map<String, dynamic> request;
  late Map<String, dynamic> relayData;

  Map<String, dynamic> toJson() {
    return {'request': request, 'relayData': relayData};
  }
}

class RifInfo {}

class SmartWalletAddressInfo {
  final BigInt nonce;
  final EthereumAddress address;
  const SmartWalletAddressInfo({required this.nonce, required this.address});
}

const String _zeroAddress = '0x0000000000000000000000000000000000000000';
const int _maxRelayNonceGap = 3;
const int _defaultGasNeededToClaim = 250000;
const int _validUntilSeconds = 24 * 60 * 60;

@Injectable()
class RifRelay {
  final CustomLogger logger = CustomLogger();
  final Web3Client client;
  final Config config;

  RifRelay(this.config, @factoryParam this.client);

  /// Http GET request to the relay server to get the metadata
  Future<ChainInfo> getChainInfo() async {
    final response = await http.get(
      Uri.parse('${config.rootstock.boltz.rifRelayUrl}/chain-info'),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ChainInfo(
        relayWorkerAddress: body['relayWorkerAddress'],
        feesReceiver: body['feesReceiver'],
        relayManagerAddress: body['relayManagerAddress'],
        relayHubAddress: body['relayHubAddress'],
        minGasPrice: body['minGasPrice'],
        chainId: body['chainId'],
        networkId: body['networkId'],
        ready: body['ready'],
        version: body['version'],
      );
    }
    throw Exception('Failed to load relay chain info: ${response.body}');
  }

  Future<EstimationResponse> estimate(
    EnvelopingRequest relay,
    RifMetadata metadata,
  ) async {
    final response = await http.post(
      Uri.parse('${config.rootstock.boltz.rifRelayUrl}/estimate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'metadata': metadata.toJson(),
        'relayRequest': relay.toJson(),
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final estimation = _stringFrom(body, 'estimation');
      final requiredTokenAmount = _stringFrom(body, 'requiredTokenAmount');
      final requiredNativeAmount = _stringFrom(body, 'requiredNativeAmount');
      final gasPrice = _stringFrom(body, 'gasPrice');
      final exchangeRate = _stringFrom(body, 'exchangeRate');
      return EstimationResponse(
        gasPrice: gasPrice,
        estimation: estimation,
        requiredTokenAmount: requiredTokenAmount,
        requiredNativeAmount: requiredNativeAmount,
        exchangeRate: exchangeRate,
      );
    }
    throw Exception('Failed to estimate relay gas: ${response.body}');
  }

  Future<RelayResponse> relay(
    EnvelopingRequest relay,
    RifMetadata metadata,
  ) async {
    final response = await http.post(
      Uri.parse('${config.rootstock.boltz.rifRelayUrl}/relay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'metadata': metadata.toJson(),
        'relayRequest': relay.toJson(),
      }),
    );

    print(response.body);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return RelayResponse(txHash: body['txHash'] ?? body['transactionHash']);
    }
    throw Exception('Failed to relay transaction: ${response.body}');
  }

  Future<String> relayClaimTransaction({
    required EthPrivateKey signer,
    required EtherSwap etherSwap,
    required Uint8List preimage,
    required BigInt amountWei,
    required EthereumAddress refundAddress,
    required BigInt timeoutBlockHeight,
  }) async {
    final callData = _encodeClaimCalldata(
      etherSwap: etherSwap,
      preimage: preimage,
      amountWei: amountWei,
      refundAddress: refundAddress,
      timeoutBlockHeight: timeoutBlockHeight,
    );

    final chainInfo = await getChainInfo();
    final smartWalletInfo = await getSmartWalletAddress(signer);
    final gasPrice = await client.getGasPrice();

    final signerAddress = signer.address;
    final etherSwapAddress = etherSwap.self.address;

    final smartWalletExists = await _isContractDeployed(
      smartWalletInfo.address,
    );
    logger.i('RIF smart wallet exists: $smartWalletExists');

    final envelopingRequest = EnvelopingRequest()
      ..request = {
        'value': '0',
        'data': callData,
        'tokenAmount': '0',
        'tokenGas': '20000',
        'from': signerAddress.eip55With0x,
        'to': etherSwapAddress.eip55With0x,
        'tokenContract': _zeroAddress,
        'relayHub': chainInfo.relayHubAddress,
        'validUntilTime': _validUntilTime(),
      }
      ..relayData = {
        'feesReceiver': chainInfo.feesReceiver,
        'gasPrice': _calculateGasPrice(
          gasPrice,
          chainInfo.minGasPrice,
        ).toString(),
      };

    if (!smartWalletExists) {
      if (config.rootstock.boltz.rifRelayDeployVerifier.isEmpty) {
        throw StateError('Missing rifRelayDeployVerifier in Config.');
      }
      if (config.rootstock.boltz.rifSmartWalletFactoryAddress.isEmpty) {
        throw StateError(
          'Missing rifSmartWalletFactoryAddress in Config for relay deploy.',
        );
      }
      envelopingRequest.relayData['callVerifier'] =
          config.rootstock.boltz.rifRelayDeployVerifier;
      envelopingRequest.request['recoverer'] = _zeroAddress;
      envelopingRequest.request['index'] = smartWalletInfo.nonce.toInt();
      envelopingRequest.request['nonce'] =
          (await _getSmartWalletFactory().nonce((
            from: signerAddress,
          ))).toString();
      envelopingRequest.relayData['callForwarder'] =
          config.rootstock.boltz.rifSmartWalletFactoryAddress;
    } else {
      envelopingRequest.relayData['callVerifier'] =
          config.rootstock.boltz.rifRelayCallVerifier;
      envelopingRequest.request['gas'] = _defaultGasNeededToClaim;
      envelopingRequest.request['nonce'] = (await getForwarder(
        smartWalletInfo.address,
      ).nonce()).toString();
      envelopingRequest.relayData['callForwarder'] =
          smartWalletInfo.address.eip55With0x;
    }

    final relayWorkerAddress = EthereumAddress.fromHex(
      chainInfo.relayWorkerAddress,
    );

    final metadata = RifMetadata(
      signature: 'SERVER_SIGNATURE_REQUIRED',
      relayHubAddress: chainInfo.relayHubAddress,
      relayMaxNonce:
          (await client.getTransactionCount(relayWorkerAddress)) +
          _maxRelayNonceGap,
    );

    // final estimateRes = await estimate(envelopingRequest, metadata);
    // logger.d('RIF gas estimation response: $estimateRes');
    // envelopingRequest.request['tokenGas'] =
    //     int.tryParse(estimateRes.estimation) ?? 0;
    // envelopingRequest.request['tokenAmount'] = estimateRes.requiredTokenAmount;
    // Skip estimate and use dummy values
    envelopingRequest.request['tokenGas'] = '20000';
    envelopingRequest.request['tokenAmount'] = '0';
    metadata.signature = await signRelayRequest(signer, envelopingRequest);

    final relayRes = await relay(envelopingRequest, metadata);
    return relayRes.txHash;
  }

  Future<SmartWalletAddressInfo> getSmartWalletAddress(
    EthPrivateKey signer,
  ) async {
    final factory = _getSmartWalletFactory();
    final nonce = await factory.nonce((from: signer.address));
    final smartWalletAddress = await factory.getSmartWalletAddress((
      owner: signer.address,
      recoverer: EthereumAddress.fromHex(_zeroAddress),
      index: nonce,
    ));
    logger.d('RIF smart wallet address $smartWalletAddress with nonce $nonce');
    return SmartWalletAddressInfo(nonce: nonce, address: smartWalletAddress);
  }

  SmartWalletFactory _getSmartWalletFactory() {
    final factoryAddress = config.rootstock.boltz.rifSmartWalletFactoryAddress;
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

  Future<String> signRelayRequest(
    EthPrivateKey signer,
    EnvelopingRequest relay,
  ) async {
    final callForwarder = EthereumAddress.fromHex(
      relay.relayData['callForwarder'],
    );
    final isDeploy = _isDeployRequest(relay.request);
    final domainSeparator = await _getDomainSeparator(
      callForwarder,
      isDeploy: isDeploy,
    );
    final relayRequestHash = _hashRelayRequest(relay);
    final preimage = Uint8List.fromList(
      [0x19, 0x01] + domainSeparator + relayRequestHash,
    );

    final sig = signer.signToEcSignature(preimage);
    var v = sig.v;
    if (v < 27) {
      v += 27;
    }
    final r = padUint8ListTo32(unsignedIntToBytes(sig.r));
    final s = padUint8ListTo32(unsignedIntToBytes(sig.s));
    final vBytes = unsignedIntToBytes(BigInt.from(v));
    final signature = uint8ListFromList(r + s + vBytes);
    return bytesToHex(signature, include0x: true);
  }

  String _encodeClaimCalldata({
    required EtherSwap etherSwap,
    required Uint8List preimage,
    required BigInt amountWei,
    required EthereumAddress refundAddress,
    required BigInt timeoutBlockHeight,
  }) {
    final claimFunction = etherSwap.self.abi.functions.firstWhere(
      (f) => f.name == 'claim' && f.parameters.length == 4,
    );
    final data = claimFunction.encodeCall([
      preimage,
      amountWei,
      refundAddress,
      timeoutBlockHeight,
    ]);
    return bytesToHex(data, include0x: true);
  }

  Future<bool> _isContractDeployed(EthereumAddress address) async {
    final code = await client.getCode(address);
    return code.isNotEmpty;
  }

  BigInt _calculateGasPrice(EtherAmount gasPrice, String minGasPrice) {
    final minPrice = BigInt.tryParse(minGasPrice) ?? BigInt.zero;
    final current = gasPrice.getInWei;
    return current > minPrice ? current : minPrice;
  }

  int _validUntilTime() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now + _validUntilSeconds;
  }

  Uint8List _hashRelayRequest(EnvelopingRequest relay) {
    final request = relay.request;
    if (_isDeployRequest(request)) {
      return _hashDeployRelayRequest(relay);
    }
    return _hashForwardRelayRequest(relay);
  }

  Uint8List _hashForwardRelayRequest(EnvelopingRequest relay) {
    final request = relay.request;
    final relayData = relay.relayData;

    final relayRequestType =
        'RelayRequest(address relayHub,address from,address to,address tokenContract,uint256 value,uint256 gas,uint256 nonce,uint256 tokenAmount,uint256 tokenGas,uint256 validUntilTime,bytes data,RelayData relayData)'
        'RelayData(uint256 gasPrice,address feesReceiver,address callForwarder,address callVerifier)';

    final relayRequestTypeHash = keccakUtf8(relayRequestType);
    final relayDataHash = _hashRelayData(relayData);

    return keccak256(
      _concat([
        relayRequestTypeHash,
        _concat([
          _encodeAddress(request['relayHub']),
          _encodeAddress(request['from']),
          _encodeAddress(request['to']),
          _encodeAddress(request['tokenContract']),
          _encodeUint(request['value']),
          _encodeUint(request['gas']),
          _encodeUint(request['nonce']),
          _encodeUint(request['tokenAmount']),
          _encodeUint(request['tokenGas']),
          _encodeUint(request['validUntilTime']),
          _encodeBytes32(keccak256(hexToBytes(_with0x(request['data'])))),
        ]),
        _encodeBytes32(relayDataHash),
      ]),
    );
  }

  Uint8List _hashDeployRelayRequest(EnvelopingRequest relay) {
    final request = relay.request;
    final relayData = relay.relayData;

    final relayRequestType =
        'RelayRequest(address relayHub,address from,address to,address tokenContract,address recoverer,uint256 value,uint256 nonce,uint256 tokenAmount,uint256 tokenGas,uint256 validUntilTime,uint256 index,bytes data,RelayData relayData)'
        'RelayData(uint256 gasPrice,address feesReceiver,address callForwarder,address callVerifier)';

    final relayRequestTypeHash = keccakUtf8(relayRequestType);
    final relayDataHash = _hashRelayData(relayData);

    return keccak256(
      _concat([
        relayRequestTypeHash,
        _concat([
          _encodeAddress(request['relayHub']),
          _encodeAddress(request['from']),
          _encodeAddress(request['to']),
          _encodeAddress(request['tokenContract']),
          _encodeAddress(request['recoverer']),
          _encodeUint(request['value']),
          _encodeUint(request['nonce']),
          _encodeUint(request['tokenAmount']),
          _encodeUint(request['tokenGas']),
          _encodeUint(request['validUntilTime']),
          _encodeUint(request['index']),
          _encodeBytes32(keccak256(hexToBytes(_with0x(request['data'])))),
        ]),
        _encodeBytes32(relayDataHash),
      ]),
    );
  }

  bool _isDeployRequest(Map<String, dynamic> request) {
    return request.containsKey('recoverer') && !request.containsKey('gas');
  }

  Future<Uint8List> _getDomainSeparator(
    EthereumAddress callForwarder, {
    required bool isDeploy,
  }) async {
    if (isDeploy) {
      final contract = SmartWalletFactory(
        address: callForwarder,
        client: client,
      );
      return contract.domainSeparator();
    }
    final contract = BaseSmartWallet(address: callForwarder, client: client);
    return contract.domainSeparator();
  }

  Uint8List _hashRelayData(Map<String, dynamic> relayData) {
    final relayDataType =
        'RelayData(uint256 gasPrice,address feesReceiver,address callForwarder,address callVerifier)';
    final relayDataTypeHash = keccakUtf8(relayDataType);
    return keccak256(
      _concat([
        relayDataTypeHash,
        _encodeUint(relayData['gasPrice']),
        _encodeAddress(relayData['feesReceiver']),
        _encodeAddress(relayData['callForwarder']),
        _encodeAddress(relayData['callVerifier']),
      ]),
    );
  }

  Uint8List _encodeAddress(String addressHex) {
    final address = EthereumAddress.fromHex(addressHex);
    return padUint8ListTo32(address.value);
  }

  Uint8List _encodeUint(dynamic value) {
    final parsed = value is BigInt
        ? value
        : (value is int ? BigInt.from(value) : BigInt.parse(value.toString()));
    return padUint8ListTo32(unsignedIntToBytes(parsed));
  }

  Uint8List _encodeBytes32(Uint8List value) {
    return padUint8ListTo32(value);
  }

  Uint8List _concat(List<Uint8List> parts) {
    final buffer = BytesBuilder(copy: false);
    for (final part in parts) {
      buffer.add(part);
    }
    return buffer.toBytes();
  }

  String _with0x(String value) {
    if (value.startsWith('0x')) {
      return value;
    }
    return '0x$value';
  }

  String _stringFrom(Map<String, dynamic> body, String key) {
    final value = body[key];
    if (value == null) {
      throw StateError('Relay estimate missing "$key": ${jsonEncode(body)}');
    }
    return value.toString();
  }
}
