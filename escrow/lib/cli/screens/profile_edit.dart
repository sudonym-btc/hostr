import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:interact_cli/interact_cli.dart';

/// Show the current profile and let the user edit individual fields.
Future<Navigation> profileEditScreen(DaemonClient client) async {
  final spinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading profile…',
      SpinnerStateType.done => 'Profile loaded',
      SpinnerStateType.failed => 'Failed to load profile',
    },
  ).interact();

  Map<String, dynamic> profile;
  try {
    profile = await client.getProfile();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    return Navigation.to(Screen.mainMenu);
  }

  print('');
  print('── Profile ──');
  print('  Pubkey      : ${profile['pubkey']}');
  print('  Name        : ${profile['name'] ?? '—'}');
  print('  Display name: ${profile['displayName'] ?? '—'}');
  print('  About       : ${profile['about'] ?? '—'}');
  print('  Picture     : ${profile['picture'] ?? '—'}');
  print('  Banner      : ${profile['banner'] ?? '—'}');
  print('  NIP-05      : ${profile['nip05'] ?? '—'}');
  print('  LN address  : ${profile['lud16'] ?? '—'}');
  print('  Website     : ${profile['website'] ?? '—'}');
  print('  EVM address : ${profile['evmAddress'] ?? '—'}');
  print('');

  final fields = [
    ('name', 'Name'),
    ('displayName', 'Display name'),
    ('about', 'About'),
    ('picture', 'Picture URL'),
    ('banner', 'Banner URL'),
    ('nip05', 'NIP-05'),
    ('lud16', 'LN address'),
    ('website', 'Website'),
  ];

  final options = [
    ...fields.map((f) => 'Edit ${f.$2}'),
    'Refresh',
  ];

  final idx = SelectOrBack(prompt: 'Profile', options: options).interact();

  if (idx == -1) {
    return Navigation.to(Screen.mainMenu);
  }

  if (idx < fields.length) {
    final (key, label) = fields[idx];
    final current = profile[key]?.toString() ?? '';
    final value =
        Input(prompt: '$label (current: ${current.isEmpty ? '—' : current})')
            .interact()
            .trim();

    if (value.isEmpty) {
      print('  No change.');
      return Navigation.to(Screen.profileEdit);
    }

    final confirmed = Confirm(
      prompt: 'Set $label to "$value" and broadcast?',
      defaultValue: true,
    ).interact();

    if (!confirmed) {
      print('  Cancelled.');
      return Navigation.to(Screen.profileEdit);
    }

    final saveSpinner = Spinner(
      icon: '✓',
      rightPrompt: (state) => switch (state) {
        SpinnerStateType.inProgress => 'Broadcasting profile…',
        SpinnerStateType.done => 'Profile broadcast',
        SpinnerStateType.failed => 'Profile update failed',
      },
    ).interact();

    try {
      await _updateProfileField(client, key, value);
      saveSpinner.done();
    } catch (e) {
      saveSpinner.failed();
      print('  Error: $e');
    }
    print('');
    return Navigation.to(Screen.profileEdit);
  }

  if (idx == fields.length) {
    // Refresh
    return Navigation.to(Screen.profileEdit);
  }

  // Fallback
  return Navigation.to(Screen.mainMenu);
}

Future<void> _updateProfileField(
    DaemonClient client, String key, String value) async {
  switch (key) {
    case 'name':
      await client.updateProfile(name: value);
    case 'displayName':
      await client.updateProfile(displayName: value);
    case 'about':
      await client.updateProfile(about: value);
    case 'picture':
      await client.updateProfile(picture: value);
    case 'banner':
      await client.updateProfile(banner: value);
    case 'nip05':
      await client.updateProfile(nip05: value);
    case 'lud16':
      await client.updateProfile(lud16: value);
    case 'website':
      await client.updateProfile(website: value);
  }
}
