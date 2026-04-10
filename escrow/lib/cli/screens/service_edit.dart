import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Show details of a single escrow service and let the user edit fees / limits.
Future<Navigation> serviceEditScreen(
  DaemonClient client,
  String serviceId,
) async {
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading service…',
      SpinnerStateType.done => 'Service loaded',
      SpinnerStateType.failed => 'Failed to load service',
    },
  ).interact();

  Map<String, dynamic> service;
  try {
    service = await client.getService(serviceId);
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    return Navigation.to(Screen.serviceList);
  }

  print('');
  print(sectionHeader('Service: ${service['contractAddress']}'));
  final minAmt = service['minAmount'] is int
      ? formatSats(service['minAmount'] as int)
      : '${service['minAmount']}';
  final maxAmt = service['maxAmount'] != null && service['maxAmount'] is int
      ? formatSats(service['maxAmount'] as int)
      : 'unlimited';
  final maxDays = '${(service['maxDuration'] as num).toInt() ~/ 86400} days';
  print(kvTable({
    'Chain ID': '${service['chainId']}',
    'EVM address': '${service['evmAddress']}',
    'Fee': '${service['feePercent']}%',
    'Min amount': '$minAmt sats',
    'Max amount': '$maxAmt',
    'Max duration': maxDays,
  }));
  print('');

  final actions = [
    'Edit fee percent',
    'Edit min amount',
    'Edit max amount',
    'Refresh',
  ];

  final idx = SelectOrBack(prompt: 'Action', options: actions).interact();

  switch (idx) {
    case -1:
      return Navigation.to(Screen.serviceList);

    case 0:
      return await _editField(
        client: client,
        serviceId: serviceId,
        label: 'Fee percent',
        current: '${service['feePercent']}',
        onSubmit: (v) =>
            client.updateService(serviceId, feePercent: double.parse(v)),
      );

    case 1:
      return await _editField(
        client: client,
        serviceId: serviceId,
        label: 'Min amount (sats)',
        current: '${service['minAmount']}',
        onSubmit: (v) =>
            client.updateService(serviceId, minAmount: int.parse(v)),
      );

    case 2:
      return await _editField(
        client: client,
        serviceId: serviceId,
        label: 'Max amount (sats, 0 for unlimited)',
        current: '${service['maxAmount'] ?? 0}',
        onSubmit: (v) {
          final val = int.parse(v);
          return client.updateService(serviceId,
              maxAmount: val == 0 ? null : val);
        },
      );

    case 3:
    default:
      // Refresh — revisit this screen
      return Navigation(Screen.serviceEdit, selectedServiceId: serviceId);
  }
}

Future<Navigation> _editField({
  required DaemonClient client,
  required String serviceId,
  required String label,
  required String current,
  required Future<void> Function(String value) onSubmit,
}) async {
  final value = Input(prompt: '$label (current: $current)').interact().trim();

  if (value.isEmpty) {
    print('  No change.');
    return Navigation(Screen.serviceEdit, selectedServiceId: serviceId);
  }

  final confirmed = Confirm(
    prompt: 'Set $label to $value and broadcast?',
    defaultValue: true,
  ).interact();

  if (!confirmed) {
    print('  Cancelled.');
    return Navigation(Screen.serviceEdit, selectedServiceId: serviceId);
  }

  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Broadcasting…',
      SpinnerStateType.done => 'Updated and broadcast',
      SpinnerStateType.failed => 'Update failed',
    },
  ).interact();

  try {
    await onSubmit(value);
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
  }
  print('');

  return Navigation(Screen.serviceEdit, selectedServiceId: serviceId);
}
