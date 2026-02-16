import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

@injectable
class EscrowClaimOperation extends Cubit<EscrowClaimState> {
  final CustomLogger logger;
  final Auth auth;
  final Evm evm;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;
  final EscrowClaimParams params;
  late final ContractClaimEscrowParams contractParams;
  final Rootstock rootstock;

  //@todo: this is tying generic escrow claim operation to a specific chain implementation, need to abstract this out properly
  late final RifRelay rifRelay = getIt<RifRelay>(param1: rootstock.client);

  EscrowClaimOperation(
    this.auth,
    this.evm,
    this.logger,
    this.rootstock,
    @factoryParam this.params,
  ) : super(EscrowClaimInitialised()) {
    chain = evm.getChainForEscrowService(params.escrowService);
    contract = chain.getSupportedEscrowContract(params.escrowService);
    contractParams = params.toContractParams(auth.getActiveEvmKey());
  }

  Future<EscrowClaimFees> estimateFees() async {
    final estimatedGasFees = await contract.estimateClaimFee(contractParams);
    final estimatedRelayFees = await rifRelay.estimateEscrowClaimRelayFees(
      signer: contractParams.ethKey,
      escrowContractAddress: contract.address,
      tradeId: contractParams.tradeId,
    );
    return EscrowClaimFees(
      estimatedGasFees: estimatedGasFees,
      estimatedRelayFees: estimatedRelayFees,
    );
  }

  Future<void> execute() async {
    try {
      logger.i(
        'Creating escrow for ${params.tradeId} at ${params.escrowService.parsedContent.contractAddress}',
      );

      final canClaim = await contract.canClaim(contractParams);
      if (!canClaim) {
        throw StateError(
          'Claim is not available yet. Trade must still be active and current time must be after unlockAt.',
        );
      }

      final estimatedGasFees = await contract.estimateClaimFee(contractParams);
      final balance = await chain.getBalance(contractParams.ethKey.address);

      final shouldRelay = balance < estimatedGasFees;

      late final TransactionInformation tx;
      if (shouldRelay) {
        logger.i(
          'Escrow claim will be relayed due to low balance. Have: $balance, need: $estimatedGasFees',
        );
        final txHash = await rifRelay.relayEscrowClaimTransaction(
          signer: contractParams.ethKey,
          escrowContractAddress: contract.address,
          tradeId: contractParams.tradeId,
        );
        tx = await chain.awaitTransaction(txHash);
      } else {
        tx = await contract.claim(contractParams);
      }

      emit(EscrowClaimCompleted(transactionInformation: tx));
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowClaimFailed(error, stackTrace);
      emit(e);
      throw e;
    }
  }
}
