@Tags(['integration', 'docker'])
library;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/contracts/boltz/TestERC20.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../support/evm_test_helpers.dart';
import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;
  late Web3Client web3;

  setUpAll(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_fund_erc20_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.warning,
      cleanHydratedStorage: true,
    );
    web3 = Web3Client(IntegrationTestHarness.anvilRpc, http.Client());
  });

  tearDownAll(() {
    web3.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'escrow fund with ERC20 (USDT) deposits token into MultiEscrow',
    () async {
      final hostr = harness.hostr;
      final anvil = harness.anvil;

      // ── 1. Create trade fixtures ──────────────────────────────────────
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await hostr.auth.signin(trade.guest.privateKey);

      // ── 2. Resolve escrow contract + service ──────────────────────────
      final escrowAddress = EthereumAddress.fromHex(
        env.evmConfig.chains.first.escrowContractAddress!,
      );
      final escrowService = (await harness.seeds.factory.buildEscrowServices(
        contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
      )).first;

      final chain = hostr.evm.getChainForEscrowService(escrowService);
      final contract = chain.escrow.getSupportedEscrowContract(escrowService);

      // ── 3. Deploy a TestERC20 (USDT) token on Anvil ────────────────────
      final deployerKey = EthPrivateKey.fromHex(
        // Anvil default account #0
        'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      );
      final usdtAddress = await deployTestERC20(
        web3,
        deployerKey,
        name: 'Test USDT',
        symbol: 'USDT',
        decimals: 18,
        initialSupply: BigInt.from(10).pow(24), // 1 000 000 USDT
      );

      // ── 4. Query token decimals and build Token / TokenAmount ─────────
      final tokenContract = TestERC20(address: usdtAddress, client: web3);
      final decimals = (await tokenContract.tokenDecimals()).toInt();

      final usdtToken = Token(
        chainId: 412346,
        address: usdtAddress.with0x,
        decimals: decimals,
      );
      expect(usdtToken.isERC20, isTrue);

      // 5 USDT (in smallest unit)
      final tradeAmount = BigInt.from(5) * BigInt.from(10).pow(decimals);
      final usdtAmount = TokenAmount(value: tradeAmount, token: usdtToken);

      // escrow fee: mirrors EscrowServiceContent.escrowFee but in BigInt
      final feePercent = escrowService.feePercent;
      final escrowFee =
          (usdtAmount.value * BigInt.from((feePercent * 100).round())) ~/
          BigInt.from(10000);
      final totalTokenCost = tradeAmount + escrowFee;

      // ── 5. Get buyer's EVM key ────────────────────────────────────────
      final buyerKey = await hostr.auth.hd.getActiveEvmKey();
      final buyerAddress = buyerKey.address;

      // ── 6. Transfer USDT from deployer to buyer ─────────────────────
      // Fund deployer with RBTC for gas first.
      await anvil.setBalance(
        address: deployerKey.address.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
      );

      final transferTxHash = await tokenContract.transfer((
        to: buyerAddress,
        value: totalTokenCost * BigInt.two,
      ), credentials: deployerKey);
      await waitForReceipt(web3, transferTxHash);

      // Verify balance was set
      final buyerBalance = await tokenContract.balanceOf((
        account: buyerAddress,
      ));
      expect(
        buyerBalance,
        greaterThanOrEqualTo(totalTokenCost),
        reason: 'Buyer should hold enough USDT',
      );

      // ── 8. Approve MultiEscrow to spend buyer's USDT ──────────────────
      // First fund buyer with RBTC for gas
      await anvil.setBalance(
        address: buyerAddress.eip55With0x,
        amountWei: BigInt.from(2) * BigInt.from(10).pow(18),
      );

      final approveTxHash = await tokenContract.approve((
        spender: escrowAddress,
        value: totalTokenCost * BigInt.two,
      ), credentials: buyerKey);
      await waitForReceipt(web3, approveTxHash);

      // ── 9. Build FundArgs and get ContractCallIntent ──────────────────
      final negotiation = trade.negotiateOrder;

      final fundArgs = FundArgs(
        tradeId: negotiation.getDtag()!,
        amount: usdtAmount,
        sellerEvmAddress: trade.sellerEvmAddress,
        arbiterEvmAddress: escrowService.evmAddress,
        unlockAt: negotiation.end!.millisecondsSinceEpoch ~/ 1000,
        escrowFee: TokenAmount(value: escrowFee, token: usdtToken),
        ethKey: buyerKey,
        token: usdtToken,
      );

      final intent = contract.fund(fundArgs);

      // ERC-20 fund must be zero-value (tokens pulled via transferFrom)
      expect(
        intent.value == BigInt.zero,
        isTrue,
        reason: 'ERC-20 createTrade should send 0 native value',
      );

      // ── 10. Broadcast directly from buyer EOA ─────────────────────────
      final chainId = chain.config.chainId;
      final txHash = await web3.sendTransaction(
        buyerKey,
        Transaction(
          to: intent.to,
          data: Uint8List.fromList(hex.decode(intent.data.substring(2))),
          value: EtherAmount.fromBigInt(EtherUnit.wei, intent.value),
        ),
        chainId: chainId,
      );

      expect(txHash, isNotEmpty);

      // ── 11. Wait for receipt ──────────────────────────────────────────
      TransactionReceipt? receipt;
      for (int i = 0; i < 15; i++) {
        receipt = await web3.getTransactionReceipt(txHash);
        if (receipt != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }

      expect(receipt, isNotNull, reason: 'Tx should be mined');
      expect(receipt!.status, isTrue, reason: 'createTrade should succeed');

      // ── 12. Verify on-chain trade ─────────────────────────────────────
      final tradeId = negotiation.getDtag()!;
      final onChainTrade = await contract.getTrade(tradeId);

      expect(onChainTrade, isNotNull, reason: 'Trade should exist in escrow');
      expect(onChainTrade!.isActive, isTrue);
      expect(
        onChainTrade.token,
        equals(usdtAddress),
        reason: 'Trade token must be USDT',
      );
      expect(
        onChainTrade.paymentAmount,
        equals(tradeAmount),
        reason: 'Trade payment amount must match',
      );

      // ── 13. Wei-perfect: escrow received exactly paymentAmount ─────────
      // The escrow fee is transferred to the fee recipient on createTrade,
      // so the contract's token balance equals paymentAmount only.
      final escrowBalance = await tokenContract.balanceOf((
        account: escrowAddress,
      ));
      expect(
        escrowBalance,
        equals(tradeAmount),
        reason:
            'Escrow contract must hold exactly paymentAmount '
            '($tradeAmount), got $escrowBalance',
      );

      // ── 14. Wei-perfect: buyer has correct residual balance ────────────
      final buyerBalanceAfter = await tokenContract.balanceOf((
        account: buyerAddress,
      ));
      // The buyer was funded with totalTokenCost * 2.
      // createTrade pulls only paymentAmount + bondAmount = tradeAmount + 0,
      // because the escrowFee is carved from paymentAmount at settlement, not
      // pulled as a separate transfer.
      // Remaining = totalTokenCost * 2 − tradeAmount.
      final expectedRemaining = totalTokenCost * BigInt.two - tradeAmount;
      expect(
        buyerBalanceAfter,
        equals(expectedRemaining),
        reason:
            'Buyer USDT balance must be exactly '
            '$expectedRemaining after escrow fund, got $buyerBalanceAfter',
      );
    },
  );
}
