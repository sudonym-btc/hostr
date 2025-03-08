// import 'dart:convert';

// import 'package:hostr/config/main.dart';
// import 'package:hostr/core/main.dart';
// import 'package:http/http.dart';
// import 'package:injectable/injectable.dart';
// import 'package:web3dart/web3dart.dart';

// class RifMetadata {
//   String? signature;
//   int relayMaxNonce;
//   String relayHubAddress;
//   RifMetadata(
//       {this.signature,
//       required this.relayMaxNonce,
//       required this.relayHubAddress});

//   toJson() {
//     return {
//       'signature': signature,
//       'relayMaxNonce': relayMaxNonce,
//       'relayHubAddress': relayHubAddress
//     };
//   }
// }

// class ChainInfo {
//   String relayWorkerAddress;
//   String feesReceiver;
//   String relayManagerAddress;
//   String relayHubAddress;
//   String minGasPrice;
//   String chainId;
//   String networkId;
//   bool ready;
//   String version;
//   ChainInfo(
//       {required this.relayWorkerAddress,
//       required this.feesReceiver,
//       required this.relayManagerAddress,
//       required this.relayHubAddress,
//       required this.minGasPrice,
//       required this.chainId,
//       required this.networkId,
//       required this.ready,
//       required this.version});
// }

// class EstimationResponse {
//   String gasPrice;
//   String estimation;
//   String requiredTokenAmount;
//   String requiredNativeAmount;
//   String exchangeRate;
//   EstimationResponse(
//       {required this.gasPrice,
//       required this.estimation,
//       required this.requiredTokenAmount,
//       required this.requiredNativeAmount,
//       required this.exchangeRate});
// }

// class EnvelopingRequest {
//   late Map<String, dynamic> request;
//   late Map<String, dynamic> relayData;

//   toJson() {
//     return {
//       'request': request,
//       'relayData': relayData,
//     };
//   }
// }

// class RifInfo {}

// @Singleton()
// class RifRelayService {
//   CustomLogger logger = CustomLogger();
//   Web3Client client;
//   Config config;
//   RifRelayService(this.config)
//       : client = Web3Client(config.rootstockRpcUrl, Client());

//   /// Http GET request to the relay server to get the metadata
//   Future<ChainInfo> getInfo() async {
//     final response = await get(Uri.parse('${config.rifRelayUrl}/chain-info'));
//     if (response.statusCode == 200) {
//       var body = jsonDecode(response.body);
//       return ChainInfo(
//           relayWorkerAddress: body['relayWorkerAddress'],
//           feesReceiver: body['feesReceiver'],
//           relayManagerAddress: body['relayManagerAddress'],
//           relayHubAddress: body['relayHubAddress'],
//           minGasPrice: body['minGasPrice'],
//           chainId: body['chainId'],
//           networkId: body['networkId'],
//           ready: body['ready'],
//           version: body['version']);
//     } else {
//       throw Exception('Failed to load info');
//     }
//   }

//   Future<EstimationResponse> estimate(
//       EnvelopingRequest relay, RifMetadata metadata) {
//     return post(Uri.parse('${config.rifRelayUrl}/estimate'), body: {
//       'metadata': metadata.toJson(),
//       'relayRequest': relay.toJson(),
//     }).then((response) {
//       if (response.statusCode == 200) {
//         var body = jsonDecode(response.body);
//         return EstimationResponse(
//             gasPrice: body['gasPrice'],
//             estimation: body['estimation'],
//             requiredTokenAmount: body['requiredTokenAmount'],
//             requiredNativeAmount: body['requiredNativeAmount'],
//             exchangeRate: body['exchangeRate']);
//       } else {
//         throw Exception('Failed to load info');
//       }
//     });
//   }

//   Future<String> relayClaimTransaction(
//       Signer signer,
//       EtherSwap etherSwap,
//       String preimage,
//       int amount,
//       String refundAddress,
//       int timeoutBlockHeight) async {
//     final callData = etherSwap.interface.encodeFunctionData(
//       "claim(bytes32,uint256,address,uint256)",
//       [
//         prefix0x(preimage),
//         satoshiToWei(amount),
//         refundAddress,
//         timeoutBlockHeight,
//       ],
//     );

//     final results = await Future.wait([
//       getChainInfo(),
//       getSmartWalletAddress(signer),
//       signer.provider.getFeeData(),
//       signer.getAddress(),
//       etherSwap.getAddress(),
//     ]);

//     final chainInfo = results[0] as ChainInfo;
//     final smartWalletAddress = results[1] as Map<String, dynamic>;
//     final feeData = results[2];
//     final signerAddress = results[3] as String;
//     final etherSwapAddress = results[4] as String;

//     final smartWalletExists = (await signer.provider.getCode(smartWalletAddress['address'])) != "0x";
//     logger.info("RIF smart wallet exists: $smartWalletExists");

//     final smartWalletFactory = getSmartWalletFactory(signer);

//     final envelopingRequest = EnvelopingRequest()
//       ..request = {
//         'value': "0",
//         'data': callData,
//         'tokenAmount': "0",
//         'tokenGas': "20000",
//         'from': signerAddress,
//         'to': etherSwapAddress,
//         'tokenContract': ZeroAddress,
//         'relayHub': chainInfo.relayHubAddress,
//         'validUntilTime': getValidUntilTime(),
//       }
//       ..relayData = {
//         'feesReceiver': chainInfo.feesReceiver,
//         'callVerifier': config.assets[RBTC].contracts.deployVerifier,
//         'gasPrice': calculateGasPrice(feeData.gasPrice, chainInfo.minGasPrice).toString(),
//       };

//     if (!smartWalletExists) {
//       envelopingRequest.request['recoverer'] = ZeroAddress;
//       envelopingRequest.request['index'] = smartWalletAddress['nonce'];
//       envelopingRequest.request['nonce'] = (await smartWalletFactory.nonce(signerAddress)).toString();
//       envelopingRequest.relayData['callForwarder'] = await smartWalletFactory.getAddress();
//     } else {
//       envelopingRequest.request['gas'] = GasNeededToClaim.toString();
//       envelopingRequest.request['nonce'] = (await getForwarder(signer, smartWalletAddress['address']).nonce()).toString();
//       envelopingRequest.relayData['callForwarder'] = smartWalletAddress['address'];
//     }

//     final metadata = RifMetadata(
//       signature: "SERVER_SIGNATURE_REQUIRED",
//       relayHubAddress: chainInfo.relayHubAddress,
//       relayMaxNonce: (await signer.provider.getTransactionCount(chainInfo.relayWorkerAddress)) + MaxRelayNonceGap,
//     );

//     final estimateRes = await estimate(envelopingRequest, metadata);
//     logger.debug("RIF gas estimation response: $estimateRes");

//     envelopingRequest.request['tokenGas'] = estimateRes.estimation;
//     envelopingRequest.request['tokenAmount'] = estimateRes.requiredTokenAmount;
//     metadata.signature = await sign(signer, envelopingRequest);

//     final relayRes = await relay(envelopingRequest, metadata);
//     return relayRes.txHash;
//   }

//   Future<Map<String, dynamic>> getSmartWalletAddress(Signer signer) async {
//     final factory = getSmartWalletFactory(signer);
//     final nonce = await factory.nonce(await signer.getAddress());
//     final smartWalletAddress = await factory.getSmartWalletAddress(await signer.getAddress(), ZeroAddress, nonce);
//     logger.debug("RIF smart wallet address $smartWalletAddress with nonce $nonce");
//     return {
//       'nonce': nonce,
//       'address': smartWalletAddress,
//     };
//   }
// }
