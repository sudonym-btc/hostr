import 'package:hostr_sdk/usecase/evm/operations/funds_monitor/funds_monitor_service.dart';
import 'package:hostr_sdk/util/token_amount_ext.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

void main() {
  group('FundsMonitorService dust policy', () {
    final token = Token.native(30);
    final minimum = tokenAmountFromSats(token, BigInt.from(1000));

    test('marks sub-sat balances as dust without swap limits', () {
      final balance = rbtcFromWei(BigInt.one, chainId: token.chainId);

      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(balance),
        isTrue,
      );
    });

    test('marks whole-sat balances below the Boltz minimum as dust', () {
      final balance = tokenAmountFromSats(token, BigInt.one);

      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(
          balance,
          minimumSwapOutAmount: minimum,
        ),
        isTrue,
      );
    });

    test('treats the exact Boltz minimum as sweepable', () {
      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(
          minimum,
          minimumSwapOutAmount: minimum,
        ),
        isFalse,
      );
    });

    test('treats balances above the Boltz minimum as sweepable', () {
      final balance = tokenAmountFromSats(token, BigInt.from(1001));

      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(
          balance,
          minimumSwapOutAmount: minimum,
        ),
        isFalse,
      );
    });
  });
}
