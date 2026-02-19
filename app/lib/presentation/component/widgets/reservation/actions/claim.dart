import 'package:flutter/material.dart';

class ClaimWidget extends StatelessWidget {
  const ClaimWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
    // final escrowService = resolution?.escrowService;
    // final tradeId = context.read<ThreadCubit>().thread.anchor;

    // print(
    //   'building claim button for escrowService: $escrowService, tradeId: $tradeId',
    // );

    // if (escrowService == null || tradeId == null || tradeId.isEmpty) {
    //   return SizedBox.shrink();
    // }

    // final hostr = getIt<Hostr>();
    // final contract = hostr.evm
    //     .getChainForEscrowService(escrowService)
    //     .getSupportedEscrowContract(escrowService);

    // final claimParams = EscrowClaimParams(
    //   tradeId: tradeId,
    //   escrowService: escrowService,
    // );
    // return BlocProvider<ClaimCubit>(
    //   create: (_) => ClaimCubit(),
    //   child: BlocBuilder<ClaimCubit, AsyncState<void, String>>(
    //     builder: (context, state) {
    //       return FutureBuilder<bool>(
    //         future: contract.canClaim(
    //           claimParams.toContractParams(hostr.auth.getActiveEvmKey()),
    //         ),
    //         builder: (context, snapshot) {
    //           print(
    //             'canClaim snapshot: ${snapshot.data}, error: ${snapshot.error}',
    //           );
    //           final canClaim = snapshot.data == true;
    //           final isLoading =
    //               snapshot.connectionState == ConnectionState.waiting;
    //           return FilledButton.tonal(
    //             onPressed: (canClaim && state is Idle)
    //                 ? () => hostr.escrow.claim(claimParams).execute()
    //                 : null,
    //             child: Text(isLoading ? 'Claiming…' : 'Claim'),
    //           );
    //         },
    //       );
    //     },
    //   ),
    // );
  }
}
