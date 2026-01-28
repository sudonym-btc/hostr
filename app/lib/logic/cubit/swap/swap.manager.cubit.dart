// import 'dart:async';

// import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
// import 'package:hostr/logic/cubit/payment/payment.manager.cubit.dart';
// import 'package:hostr/logic/main.dart';
// import 'package:hostr/logic/workflows/swap_workflow.dart';
// import 'package:hydrated_bloc/hydrated_bloc.dart';
// import 'package:models/main.dart';

// // SwapType, SwapStatusSnapshot, SwapRecord moved to swap_workflow.dart

// class SwapsState {
//   final List<SwapRecord> swaps;

//   const SwapsState({required this.swaps});

//   SwapsState copyWith({List<SwapRecord>? swaps}) {
//     return SwapsState(swaps: swaps ?? this.swaps);
//   }

//   Map<String, dynamic> toJson() => {
//     'swaps': swaps.map((s) => s.toJson()).toList(),
//   };

//   static SwapsState fromJson(Map<String, dynamic> json) {
//     final list = (json['swaps'] as List<dynamic>? ?? [])
//         .map((e) => SwapRecord.fromJson(e as Map<String, dynamic>))
//         .toList();
//     return SwapsState(swaps: list);
//   }

//   static SwapsState initial() => const SwapsState(swaps: []);
// }

// /// Manager cubit coordinating multiple swap operations.
// /// Business logic (state sync, validation, record management) delegated to SwapWorkflow.
// /// This cubit manages lifecycle of multiple swap cubits and persists state.
// class SwapManager extends HydratedCubit<SwapsState> {
//   final PaymentsManager paymentsManager;
//   final SwapWorkflow _workflow;
//   StreamSubscription? _paymentSub;

//   SwapManager({required this.paymentsManager, required SwapWorkflow workflow})
//     : _workflow = workflow,
//       super(SwapsState.initial()) {
//     _paymentSub = paymentsManager.stream.listen(_syncPaymentsIntoSwaps);
//   }

//   Future<void> swapIn(int amountSats) async {
//     // Validate params via workflow
//     _workflow.validateSwapInParams(amountSats: amountSats);

//     // Create swap record via workflow
//     final id = _workflow.generateSwapId();
//     final record = _workflow.createSwapRecord(
//       id: id,
//       type: SwapType.swapIn,
//       params: {'amountSats': amountSats},
//     );
//     _addOrUpdate(record);

//     // Execute swap via service and map progress to status
//     try {
//       // await swapService.swapIn(
//       //   amountSats,
//       //   onProgress: (p) {
//       //     final status = _workflow.mapProgressToStatus(p);
//       //     _updateSwap(id, status: status);
//       //   },
//       //   onPaymentCreated: (paymentId) {
//       //     _updateSwap(
//       //       id,
//       //       status: SwapStatusSnapshot.paymentCreated,
//       //       paymentId: paymentId,
//       //     );
//       //   },
//       // );
//     } catch (e) {
//       // Update to failed status on error
//       _updateSwap(id, status: SwapStatusSnapshot.failed, error: e.toString());
//     }
//   }

//   void _syncPaymentsIntoSwaps(PaymentsState paymentsState) {
//     // Delegate sync logic to workflow
//     final updated = _workflow.syncPaymentsIntoSwaps(
//       swaps: state.swaps,
//       payments: paymentsState.payments,
//     );
//     emit(state.copyWith(swaps: updated));
//   }

//   void _updateSwap(
//     String id, {
//     SwapStatusSnapshot? status,
//     String? error,
//     String? paymentId,
//   }) {
//     final swap = _swapFor(id);
//     if (swap == null) return;

//     PaymentRecord? payment = swap.payment;
//     if (paymentId != null) {
//       try {
//         payment = paymentsManager.state.payments.firstWhere(
//           (p) => p.id == paymentId,
//         );
//       } catch (_) {
//         // keep previous payment if not found
//       }
//     }

//     // Delegate update logic to workflow
//     final updated = _workflow.updateSwapRecord(
//       swap: swap,
//       status: status,
//       error: error,
//       payment: payment,
//     );
//     _addOrUpdate(updated);
//   }

//   SwapRecord? _swapFor(String id) {
//     for (final s in state.swaps) {
//       if (s.id == id) return s;
//     }
//     return null;
//   }

//   void _addOrUpdate(SwapRecord record) {
//     final others = state.swaps.where((s) => s.id != record.id).toList();
//     emit(state.copyWith(swaps: [...others, record]));
//   }

//   @override
//   SwapsState? fromJson(Map<String, dynamic> json) => SwapsState.fromJson(json);

//   @override
//   Map<String, dynamic>? toJson(SwapsState state) => state.toJson();

//   @override
//   Future<void> close() {
//     _paymentSub?.cancel();
//     return super.close();
//   }

//   // Stream<TradeCreated> checkEscrowStatus(String reservationRequestId) {
//   //   // return swapService.checkEscrowStatus(reservationRequestId);
//   // }

//   Future<void> escrow({
//     required String eventId,
//     required Amount amount,
//     required String sellerPubkey,
//     required String escrowPubkey,
//     required String escrowContractAddress,
//     required int timelock,
//   }) {
//     // Validate params via workflow
//     _workflow.validateEscrowParams(
//       eventId: eventId,
//       amount: amount,
//       sellerPubkey: sellerPubkey,
//       escrowPubkey: escrowPubkey,
//       escrowContractAddress: escrowContractAddress,
//       timelock: timelock,
//     );

//     return swapService.escrow(
//       eventId: eventId,
//       amount: amount,
//       sellerPubkey: sellerPubkey,
//       escrowPubkey: escrowPubkey,
//       escrowContractAddress: escrowContractAddress,
//       timelock: timelock,
//     );
//   }

//   Future<void> swapOutAll() => swapService.swapOutAll();

//   Future<void> listEvents() => swapService.listEvents();
// }
