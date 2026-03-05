import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// List escrow services published by our pubkey — pick one to edit.
Future<Navigation> serviceListScreen(DaemonClient client) async {
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading services…',
      SpinnerStateType.done => 'Services loaded',
      SpinnerStateType.failed => 'Failed to load services',
    },
  ).interact();

  try {
    final services = await client.listServices();
    spinner.done();

    if (services.isEmpty) {
      print('');
      print('  No escrow services published.');
      print('');
      pressAnyKey();
      return Navigation.to(Screen.mainMenu);
    }

    print('');
    final options = services.map((s) {
      final chain = 'chain=${s.chainId}';
      final fees = 'base=${s.feeBase} sats, ${s.feePercent}%';
      final range = s.maxAmount != null
          ? '${s.minAmount}–${s.maxAmount} sats'
          : '≥${s.minAmount} sats';
      return '${s.contractAddress.substring(0, 10)}…  $chain  $fees  $range';
    }).toList();

    final idx =
        SelectOrBack(prompt: 'Escrow Services', options: options).interact();

    if (idx == -1) {
      return Navigation.to(Screen.mainMenu);
    }

    return Navigation(
      Screen.serviceEdit,
      selectedServiceId: services[idx].id,
    );
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    return Navigation.to(Screen.mainMenu);
  }
}
