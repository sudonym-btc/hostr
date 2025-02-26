
# Escrow

We deposit using our EVM balance, usually after a swap in.

```mermaid
flowchart TD
    PayEscrow[Pay Escrow
  amount, escrowPubkey, counterpartyPubkey]
  --> CalculateFees
  --> GenerateEscrow[GenerateEscrowContract,
    amount, escrowPubkey, counterpartyPubkey]
  --> SwapIn[Swap In with params:
    amountPlusFees, claimAddr, onComplete: next]
  --> FundEscrow(GenerateEscrowContract.id, amount, )

```

```dart
class EscrowDepositManager extends Cubit<Map<String, dynamic>> {
  final SwapManager swapManager;
  final RpcClient rpcClient;
  Map<String, dynamic> pendingDeposits = {};

  EscrowDepositManager(this.swapManager, this.rpcClient) : super({});

  void initiateEscrowDeposit(double amount, String escrowPubkey, String counterpartyPubkey) {
    final depositId = DateTime.now().millisecondsSinceEpoch.toString();
    pendingDeposits[depositId] = {
      'amount': amount,
      'escrowPubkey': escrowPubkey,
      'counterpartyPubkey': counterpartyPubkey,
      'status': 'initiated'
    };
    emit(pendingDeposits);

    swapManager.swapIn(amount);
    swapManager.stream.listen((swapStatus) {
      if (swapStatus == 'Completed') {
        _completeEscrowDeposit(depositId);
      }
    });
  }

  void _completeEscrowDeposit(String depositId) {
    final deposit = pendingDeposits[depositId];
    if (deposit != null) {
      final amount = deposit['amount'];
      final escrowPubkey = deposit['escrowPubkey'];
      final counterpartyPubkey = deposit['counterpartyPubkey'];

      // Create and broadcast the escrow transaction
      rpcClient.createEscrowTransaction(amount, escrowPubkey, counterpartyPubkey).then((txHash) {
        deposit['status'] = 'completed';
        deposit['txHash'] = txHash;
        emit(pendingDeposits);
      }).catchError((error) {
        deposit['status'] = 'failed';
        emit(pendingDeposits);
      });
    }
  }

  void resumePendingDeposits() {
    pendingDeposits.forEach((depositId, deposit) {
      if (deposit['status'] == 'initiated') {
        swapManager.swapIn(deposit['amount']);
        swapManager.stream.listen((swapStatus) {
          if (swapStatus == 'Completed') {
            _completeEscrowDeposit(depositId);
          }
        });
      }
    });
  }
```

```mermaid
flowchart TD
  A[Escrow Deposit Initiated] --> B[Show Escrow Profile]
  B --> C[Show Listing Info Widget]
  C --> D[Show Profile of Seller]
  D --> E[Show Pricing + Fees]
  E --> F{Buyer OK's This?}
  F -- Yes --> G[Initiate Swap In]
  G --> H[Initiate Lightning Payment]
  H --> I{Swap Completed or Failed?}
  I -- Completed --> J[Open Escrow-Deposit Modal]
  I -- Failed --> K[Handle Swap Failure]
  J --> L[Wait for Escrow Transaction Confirmation]
  L --> M[Escrow Deposit Completed]
```
