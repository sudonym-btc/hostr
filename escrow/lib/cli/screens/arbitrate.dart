import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Prompts the user for arbitration parameters and executes on-chain.
Future<Navigation> arbitrateScreen(
  DaemonClient client,
  String tradeId,
) async {
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading trade…',
      SpinnerStateType.done => 'Trade loaded',
      SpinnerStateType.failed => 'Failed to load trade',
    },
  ).interact();

  Map<String, dynamic> data;
  try {
    data = await client.getTrade(tradeId);
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  final cached = data['cached'] as Map<String, dynamic>?;
  final onChain = data['onChain'] as Map<String, dynamic>?;
  if (onChain == null) {
    print('');
    print(sectionHeader('Arbitrate: $tradeId'));
    print('');
    print(
      '  This trade is in the local event cache, but it is not active '
      'on the configured escrow contract.',
    );
    print('  It may have already settled, or this daemon may be pointed at');
    print('  a different chain/contract than the one that funded the trade.');
    print('');
    pressAnyKey();
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }
  final amounts = _ArbitrationAmounts.from(cached: cached, onChain: onChain);

  print('');
  print(sectionHeader('Arbitrate: $tradeId'));
  print('');
  print(kvTable({
    'Payment': amounts.format(amounts.paymentAmount),
    'Bond': amounts.format(amounts.bondAmount),
    if (amounts.escrowFee > BigInt.zero)
      'Escrow fee': amounts.format(amounts.escrowFee),
  }));
  print('');
  print('  Enter the forward ratios — the fraction sent to the seller.');
  print('  Each must be between 0 and 1 (inclusive).');
  print('  Example: 1 = all to seller, 0 = full refund to buyer, 0.5 = split.');
  print('');
  print(kDimStyle.render('  Leave blank to go back.'));
  print('');

  // ── Payment forward ────────────────────────────────────────────────
  final paymentStr = Input(prompt: 'Payment forward ratio (0–1)').interact();

  if (paymentStr.trim().isEmpty) {
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  final paymentForward = double.tryParse(paymentStr.trim());

  if (paymentForward == null || paymentForward < 0 || paymentForward > 1) {
    print('  Invalid value. Must be a number between 0 and 1.');
    pressAnyKey();
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // ── Bond forward ───────────────────────────────────────────────────
  final double bondForward;
  if (amounts.bondAmount == BigInt.zero) {
    bondForward = 0;
    print(kDimStyle.render('  No bond is locked for this trade.'));
  } else {
    final bondStr = Input(
      prompt: 'Bond (security deposit) forward ratio (0–1)',
      defaultValue: '0',
    ).interact();

    final parsedBondForward = double.tryParse(bondStr.trim());

    if (parsedBondForward == null ||
        parsedBondForward < 0 ||
        parsedBondForward > 1) {
      print('  Invalid value. Must be a number between 0 and 1.');
      pressAnyKey();
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
    }
    bondForward = parsedBondForward;
  }

  print('');
  print(kvTable(amounts.preview(paymentForward, bondForward)));
  print('');

  // Confirmation
  final confirmed = Confirm(
    prompt:
        'Arbitrate trade $tradeId with paymentForward=$paymentForward, bondForward=$bondForward?',
    defaultValue: false,
  ).interact();

  if (!confirmed) {
    print('  Cancelled.');
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  // ── Execute ────────────────────────────────────────────────────────────
  final submitSpinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Submitting arbitration tx…',
      SpinnerStateType.done => 'Transaction submitted',
      SpinnerStateType.failed => 'Transaction failed',
    },
  ).interact();

  try {
    final txHash = await client.arbitrate(tradeId, paymentForward, bondForward);
    submitSpinner.done();
    print('  Tx hash: $txHash');
  } catch (e) {
    submitSpinner.failed();
    print('');
    print('  Error: $e');
    print('');
    Input(prompt: 'Press Enter to continue').interact();
    return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
  }

  print('');

  final actions = [
    'View updated trade detail',
  ];

  final idx = SelectOrBack(prompt: 'Next', options: actions).interact();

  switch (idx) {
    case 0:
      return Navigation(Screen.tradeDetail, selectedTradeId: tradeId);
    case -1:
    default:
      return Navigation.to(Screen.tradeList);
  }
}

class _ArbitrationAmounts {
  final BigInt paymentAmount;
  final BigInt bondAmount;
  final BigInt escrowFee;
  final int tokenDecimals;
  final String tokenSymbol;

  const _ArbitrationAmounts({
    required this.paymentAmount,
    required this.bondAmount,
    required this.escrowFee,
    required this.tokenDecimals,
    required this.tokenSymbol,
  });

  factory _ArbitrationAmounts.from({
    required Map<String, dynamic>? cached,
    required Map<String, dynamic>? onChain,
  }) {
    final tokenDecimals = onChain?['tokenDecimals'] as int? ??
        cached?['tokenDecimals'] as int? ??
        8;
    final tokenSymbol = onChain?['tokenSymbol'] as String? ??
        cached?['tokenSymbol'] as String? ??
        'sat';
    final paymentAmount = _parseBigInt(
      onChain?['paymentAmount'] as String? ?? cached?['amountWei'] as String?,
    );
    return _ArbitrationAmounts(
      paymentAmount: paymentAmount,
      bondAmount: _parseBigInt(onChain?['bondAmount'] as String?),
      escrowFee: _parseBigInt(onChain?['escrowFee'] as String?),
      tokenDecimals: tokenDecimals,
      tokenSymbol: tokenSymbol,
    );
  }

  String format(BigInt amount) =>
      formatTokenAmount(amount.toString(), tokenDecimals, tokenSymbol);

  Map<String, String> preview(double paymentForward, double bondForward) {
    final paymentAfterFee = paymentAmount - escrowFee;
    final paymentToSeller = _applyRatio(paymentAfterFee, paymentForward);
    final bondToSeller = _applyRatio(bondAmount, bondForward);
    final sellerTotal = paymentToSeller + bondToSeller;
    final buyerTotal =
        (paymentAfterFee - paymentToSeller) + (bondAmount - bondToSeller);

    return {
      'Payment to seller': format(paymentToSeller),
      'Payment to buyer': format(paymentAfterFee - paymentToSeller),
      if (bondAmount > BigInt.zero)
        'Security bond to seller': format(bondToSeller),
      if (bondAmount > BigInt.zero)
        'Security bond to buyer': format(bondAmount - bondToSeller),
      if (escrowFee > BigInt.zero) 'Escrow fee to arbiter': format(escrowFee),
      'Seller total': format(sellerTotal),
      'Buyer total': format(buyerTotal),
    };
  }

  static BigInt _parseBigInt(String? value) =>
      value == null || value.isEmpty ? BigInt.zero : BigInt.parse(value);

  static BigInt _applyRatio(BigInt amount, double ratio) {
    const scale = 1000000;
    final scaledRatio = (ratio * scale).round();
    return amount * BigInt.from(scaledRatio) ~/ BigInt.from(scale);
  }
}
