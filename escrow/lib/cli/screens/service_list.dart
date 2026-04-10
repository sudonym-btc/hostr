import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' hide Spinner;
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

    // Print a styled table of services.
    print('');
    final table = Table()
        .headers(['#', 'Contract', 'Chain', 'Fee'])
        .border(Border.rounded)
        .padding(1)
        .headerStyle(Style().bold().foreground(Colors.cyan))
        .styleFunc((row, col, data) {
          if (row == Table.headerRow) return null; // handled by headerStyle
          if (col == 3) return Style().foreground(Colors.success);
          return null;
        });
    for (var i = 0; i < services.length; i++) {
      final s = services[i];
      table.row([
        '${i + 1}',
        '${s.contractAddress.substring(0, 10)}…',
        '${s.chainId}',
        '${s.feePercent}%',
      ]);
    }
    print(table.render());
    print('');

    final options = services
        .asMap()
        .entries
        .map(
            (e) => '${e.key + 1}. ${e.value.contractAddress.substring(0, 10)}…')
        .toList();

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
