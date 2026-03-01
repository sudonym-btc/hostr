import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../../config.dart';
import '../../../../../datasources/anvil/anvil.dart';
import '../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../util/custom_logger.dart';
import 'rif_relay.dart';

// ---------------------------------------------------------------------------
// Local dev config – matches docker-compose defaults
// ---------------------------------------------------------------------------

class _DevRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;

  @override
  String get rpcUrl => 'http://localhost:8545';

  @override
  BoltzConfig get boltz => _DevBoltzConfig();
}

class _DevBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'http://localhost:9001/v2';

  @override
  String get rifRelayUrl => 'http://localhost:8090';

  @override
  String get rifRelayCallVerifier =>
      '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';

  @override
  String get rifRelayDeployVerifier =>
      '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';

  @override
  String get rifSmartWalletFactoryAddress =>
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';
}

// ---------------------------------------------------------------------------
// Hardcoded contract address from docker-compose / boltz regtest
// ---------------------------------------------------------------------------

const _etherSwapAddress = '0x8464135c8F25Da09e49BC8782676a84730C318bC';

// ---------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------

Future<void> main() async {
  final logger = CustomLogger();
  final config = HostrConfig(
    bootstrapRelays: ['wss://relay.hostr.development'],
    bootstrapBlossom: ['https://blossom.hostr.development'],
    hostrRelay: 'wss://relay.hostr.development',
    rootstockConfig: _DevRootstockConfig(),
    logs: logger,
  );

  final web3 = Web3Client(config.rootstockConfig.rpcUrl, http.Client());
  final anvil = AnvilClient(rpcUri: Uri.parse(config.rootstockConfig.rpcUrl));

  // Enable automine so every tx is mined instantly.
  await anvil.setAutomine(true);

  final rif = RifRelay(config, web3, logger);

  // -- 1. Generate a random signer key --
  final rng = Random.secure();
  final signerKey = EthPrivateKey.createRandom(rng);
  final signerAddress = signerKey.address;
  print('Signer:  ${signerAddress.eip55With0x}');

  // -- 2. Fund the signer via Anvil (10 RBTC) --
  final fundAmount = BigInt.from(10) * BigInt.from(10).pow(18); // 10 ETH
  final funded = await anvil.setBalance(
    address: signerAddress.eip55With0x,
    amountWei: fundAmount,
  );
  print('Funded signer with 10 RBTC: $funded');

  // -- 3. Create a random preimage and compute its SHA-256 hash --
  final preimage = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    preimage[i] = rng.nextInt(256);
  }
  final preimageHash = Uint8List.fromList(sha256.convert(preimage).bytes);
  print('Preimage:     ${bytesToHex(preimage, include0x: true)}');
  print('PreimageHash: ${bytesToHex(preimageHash, include0x: true)}');

  // -- 4. Lock ETH in the EtherSwap contract --
  final etherSwap = EtherSwap(
    address: EthereumAddress.fromHex(_etherSwapAddress),
    client: web3,
  );

  // The claim address will be the signer's smart wallet once deployed,
  // but for now just use the signer's EOA so the lock succeeds.
  final smartWalletInfo = await rif.getSmartWalletAddress(signerKey);
  final claimAddress = smartWalletInfo.address;
  print(
    'Smart wallet: ${claimAddress.eip55With0x} '
    '(nonce: ${smartWalletInfo.nonce})',
  );

  // Fund the (not-yet-deployed) smart wallet so the relay server's internal
  // eth_estimateGas from that address doesn't fail with "allowance: 0".
  final swFunded = await anvil.setBalance(
    address: claimAddress.eip55With0x,
    amountWei: BigInt.from(10).pow(17), // 0.1 RBTC — enough for gas sim
  );
  print('Funded smart wallet for estimation: $swFunded');

  // Timelock far in the future so it doesn't expire.
  final currentBlock = await web3.getBlockNumber();
  final timelock = BigInt.from(currentBlock + 10000);

  final lockAmount = BigInt.from(10).pow(16); // 0.01 ETH
  print('Locking ${lockAmount} wei in EtherSwap...');

  final lockTxHash = await etherSwap.lock(
    (
      preimageHash: preimageHash,
      claimAddress: claimAddress,
      timelock: timelock,
    ),
    credentials: signerKey,
    transaction: Transaction(value: EtherAmount.inWei(lockAmount)),
  );
  print('Lock tx: $lockTxHash');

  // Wait for receipt and verify success.
  TransactionReceipt? receipt;
  for (var i = 0; i < 10; i++) {
    receipt = await web3.getTransactionReceipt(lockTxHash);
    if (receipt != null) break;
    await Future.delayed(const Duration(milliseconds: 500));
  }
  if (receipt == null) {
    print('ERROR: Lock tx receipt not found after waiting');
    return;
  }
  print('Lock receipt status: ${receipt.status} (1 = success)');
  if (receipt.status != true) {
    print('ERROR: Lock tx reverted!');
    // Try to get revert reason via eth_call
    final lockFn =
        etherSwap.self.abi.functions[13]; // lock(bytes32,address,uint256)
    final lockData = bytesToHex(
      lockFn.encodeCall([preimageHash, claimAddress, timelock]),
      include0x: true,
    );
    try {
      final callResult = await http.post(
        Uri.parse(config.rootstockConfig.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_call',
          'params': [
            {
              'from': signerAddress.eip55With0x,
              'to': _etherSwapAddress,
              'data': lockData,
              'value': '0x${lockAmount.toRadixString(16)}',
            },
            'latest',
          ],
          'id': 1,
        }),
      );
      print('Lock eth_call result: ${callResult.body}');
    } catch (e) {
      print('Lock eth_call error: $e');
    }
    return;
  }
  print('Lock logs: ${receipt.logs.length} events emitted');

  // Verify the swap exists on-chain.
  final swapHash = await etherSwap.hashValues((
    preimageHash: preimageHash,
    amount: lockAmount,
    claimAddress: claimAddress,
    refundAddress: signerAddress,
    timelock: timelock,
  ));
  print('Expected swap hash: ${bytesToHex(swapHash, include0x: true)}');
  final swapExists = await etherSwap.swaps(($param77: swapHash));
  print('Swap exists on-chain: $swapExists');

  if (!swapExists) {
    // Debug: check the balance at the EtherSwap contract.
    final contractBalance = await web3.getBalance(
      EthereumAddress.fromHex(_etherSwapAddress),
    );
    print('EtherSwap contract balance: ${contractBalance.getInWei} wei');

    // Also try hashValues with different refundAddress combos for debugging.
    final altHash1 = await etherSwap.hashValues((
      preimageHash: preimageHash,
      amount: lockAmount,
      claimAddress: signerAddress, // swapped - maybe lock used signer as claim?
      refundAddress: claimAddress,
      timelock: timelock,
    ));
    final altExists1 = await etherSwap.swaps(($param77: altHash1));
    print('Alt hash (claim=signer, refund=wallet): $altExists1');
  }

  // -- 5. Chain info (raw, to get feesReceiver not in PingResponse) --
  print('\n--- getChainInfo ---');
  final chainInfoRaw = await http.get(
    Uri.parse('${config.rootstockConfig.boltz.rifRelayUrl}/chain-info'),
  );
  final chainInfo = jsonDecode(chainInfoRaw.body) as Map<String, dynamic>;
  print(chainInfo);

  final relayHubAddress = chainInfo['relayHubAddress'] as String;
  final feesReceiver = chainInfo['feesReceiver'] as String? ?? relayHubAddress;
  final relayWorkerAddress = chainInfo['relayWorkerAddress'] as String;
  final minGasPriceStr = chainInfo['minGasPrice'] as String;

  // -- 6. Ready for estimate / relay testing --
  print('\n=== Setup complete ===');
  print('EtherSwap:    $_etherSwapAddress');
  print('Signer PK:    ${bytesToHex(signerKey.privateKey, include0x: true)}');
  print('Signer addr:  ${signerAddress.eip55With0x}');
  print('Smart wallet: ${claimAddress.eip55With0x}');
  print('Preimage:     ${bytesToHex(preimage, include0x: true)}');
  print('PreimageHash: ${bytesToHex(preimageHash, include0x: true)}');
  print('Amount:       $lockAmount wei');
  print('Timelock:     $timelock');

  final claimArgs = (
    amount: lockAmount,
    preimage: preimage,
    r: Uint8List(32), // dummy
    s: Uint8List(32), // dummy
    v: BigInt.zero, // dummy
    refundAddress: signerAddress,
    timelock: timelock,
  );
  // -- Estimate --
  print('\n--- estimate ---');

  final estimateResponse = await rif.estimateClaim(
    etherSwap,
    signerKey,
    claimArgs,
  );

  print("Estimate response: $estimateResponse");

  // Snapshot balances before relay
  final swBalanceBefore = await web3.getBalance(claimAddress);
  final signerBalanceBefore = await web3.getBalance(signerAddress);
  print('\n--- balances before relay ---');
  print('Smart wallet: ${swBalanceBefore.getInWei} wei');
  print('Signer EOA:   ${signerBalanceBefore.getInWei} wei');

  print('\n--- relay ---');
  final relayRes = await rif.relayClaim(etherSwap, signerKey, claimArgs);
  print(
    'Relay response: signedTx=${relayRes.signedTx}, txHash=${relayRes.transactionHash}',
  );

  // -- 7. Verify funds arrived --
  print('\n--- verification ---');

  // The relay server broadcasts the tx itself and returns signedTx + txHash.
  // (The server's HttpServer.ts sends { signedTx, txHash } — not transactionHash.)
  String? relayTxHash = relayRes.transactionHash as String?;
  final signedTx = relayRes.signedTx as String?;

  if ((relayTxHash == null || relayTxHash.isEmpty) &&
      signedTx != null &&
      signedTx.isNotEmpty) {
    // Fallback: compute tx hash = keccak256(rlp-encoded signed tx)
    final rawBytes = hexToBytes(signedTx);
    final hash = keccak256(rawBytes);
    relayTxHash = bytesToHex(hash, include0x: true);
    print('Computed tx hash from signedTx: $relayTxHash');
  }

  if (relayTxHash != null && relayTxHash.isNotEmpty) {
    TransactionReceipt? relayReceipt;
    for (var i = 0; i < 20; i++) {
      relayReceipt = await web3.getTransactionReceipt(relayTxHash);
      if (relayReceipt != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (relayReceipt == null) {
      print('WARNING: Relay tx receipt not found after waiting');
    } else {
      print('Relay tx status: ${relayReceipt.status} (true = success)');
      print('Relay tx gas used: ${relayReceipt.gasUsed}');
      if (relayReceipt.status != true) {
        print('ERROR: Relay tx reverted!');
      }
    }
  } else {
    print('WARNING: Could not determine relay transaction hash');
  }

  // Check that the swap was consumed on-chain.
  final swapExistsAfter = await etherSwap.swaps(($param77: swapHash));
  print('Swap still exists on-chain: $swapExistsAfter (should be false)');

  // Snapshot balances after relay
  final swBalanceAfter = await web3.getBalance(claimAddress);
  final signerBalanceAfter = await web3.getBalance(signerAddress);
  print('\n--- balances after relay ---');
  print('Smart wallet: ${swBalanceAfter.getInWei} wei');
  print('Signer EOA:   ${signerBalanceAfter.getInWei} wei');

  final swDelta = swBalanceAfter.getInWei - swBalanceBefore.getInWei;
  final signerDelta =
      signerBalanceAfter.getInWei - signerBalanceBefore.getInWei;
  print('\nSmart wallet delta: $swDelta wei');
  print('Signer EOA delta:   $signerDelta wei');

  // The claim sends lockAmount to the smart wallet (which then forwards to
  // the EOA, or keeps it — depends on the relay forwarder logic). Either way,
  // the combined balance should have increased by ~lockAmount minus gas fees.
  final totalDelta = swDelta + signerDelta;
  print('Combined delta:     $totalDelta wei');
  print('Expected (lock):    $lockAmount wei');

  if (totalDelta > BigInt.zero) {
    print('\n✅ SUCCESS — funds received ($totalDelta wei)');
  } else {
    print('\n❌ FAILURE — no funds received (delta: $totalDelta wei)');
  }

  anvil.close();
  web3.dispose();
}
