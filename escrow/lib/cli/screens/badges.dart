import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' hide Spinner, Select;
import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/styles.dart';
import 'package:escrow/cli/widgets.dart';
import 'package:escrow/shared/protocol.dart';
import 'package:interact_cli/interact_cli.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _trunc(String s, int maxLen) =>
    s.length > maxLen ? '${s.substring(0, maxLen)}' : s;

/// Accepts either a 64-char hex pubkey or an npub1... bech32 string.
/// Returns the lowercase hex pubkey, or throws [ValidationError] if invalid.
String _resolveHexPubkey(String input) {
  final v = input.trim();
  if (Nip19.isPubkey(v)) {
    try {
      return Nip19.decode(v);
    } catch (_) {
      throw ValidationError('Invalid npub: could not decode');
    }
  }
  if (v.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(v)) {
    return v.toLowerCase();
  }
  throw ValidationError('Enter a valid 64-char hex pubkey or npub1... string');
}

/// Result of resolving an npub or naddr input.
class _AwardTarget {
  final String recipientPubkey;
  final String? listingAnchor; // non-null when input was naddr
  _AwardTarget({required this.recipientPubkey, this.listingAnchor});
}

/// Parses an npub1 or naddr1 input into an [_AwardTarget].
/// - npub  → recipient pubkey only
/// - naddr → recipient = naddr pubkey, listing anchor = kind:pubkey:dTag
/// Throws [ValidationError] on invalid input.
_AwardTarget _resolveTarget(String input) {
  final v = input.trim();
  if (v.startsWith('npub1')) {
    return _AwardTarget(recipientPubkey: _resolveHexPubkey(v));
  }
  if (v.startsWith('naddr1')) {
    try {
      final naddr = Nip19.decodeNaddr(v);
      final anchor = '${naddr.kind}:${naddr.pubkey}:${naddr.identifier}';
      return _AwardTarget(
        recipientPubkey: naddr.pubkey,
        listingAnchor: anchor,
      );
    } catch (_) {
      throw ValidationError('Invalid naddr: could not decode');
    }
  }
  // Bare hex pubkey — treat as user-only award
  if (v.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(v)) {
    return _AwardTarget(recipientPubkey: v.toLowerCase());
  }
  throw ValidationError(
      'Enter an npub1... (user) or naddr1... (listing) or 64-char hex pubkey');
}

// ── Top-level badge menu ─────────────────────────────────────────────────────

Future<Navigation> badgeMenuScreen(DaemonClient client) async {
  print('');
  print(sectionHeader('Badges'));
  print('');

  final options = [
    'Badge Definitions  (create / edit / delete)',
    'Badge Awards       (assign / revoke)',
  ];

  final idx = SelectOrBack(prompt: 'Badges', options: options).interact();

  switch (idx) {
    case 0:
      return Navigation.to(Screen.badgeDefinitionList);
    case 1:
      return Navigation.to(Screen.badgeAwardList);
    default:
      return Navigation.to(Screen.mainMenu);
  }
}

// ── Badge definition list ────────────────────────────────────────────────────

Future<Navigation> badgeDefinitionListScreen(DaemonClient client) async {
  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading badge definitions...',
      SpinnerStateType.done => 'Loaded',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  List<BadgeDefinitionSummary> definitions;
  try {
    definitions = await client.listBadgeDefinitions();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    pressAnyKey();
    return Navigation.to(Screen.badgeMenu);
  }

  print('');
  print(sectionHeader('Badge Definitions'));
  print('');

  if (definitions.isNotEmpty) {
    final table = Table()
        .headers(['#', 'Identifier', 'Name', 'Image'])
        .border(Border.rounded)
        .padding(1)
        .headerStyle(Style().bold().foreground(Colors.cyan));
    for (var i = 0; i < definitions.length; i++) {
      final d = definitions[i];
      table.row([
        '${i + 1}',
        d.identifier,
        d.name,
        d.image != null ? 'yes' : '-',
      ]);
    }
    print(table.render());
    print('');
  } else {
    print('  No badge definitions found.\n');
  }

  final options = [
    '+ Create new badge definition',
    ...definitions.map((d) => '${d.identifier}  (${d.name})'),
  ];

  final idx =
      SelectOrBack(prompt: 'Badge Definitions', options: options).interact();

  if (idx == -1) return Navigation.to(Screen.badgeMenu);

  if (idx == 0) {
    return Navigation.to(Screen.badgeDefinitionCreate);
  }

  return Navigation(
    Screen.badgeDefinitionEdit,
    selectedBadgeDefinitionAnchor: definitions[idx - 1].anchor,
  );
}

// ── Create badge definition ──────────────────────────────────────────────────

Future<Navigation> badgeDefinitionCreateScreen(DaemonClient client) async {
  print('');
  print(sectionHeader('Create Badge Definition'));
  print('');

  final identifier = Input(
    prompt: 'Identifier (unique slug, e.g. "verified-host")',
    validator: (v) {
      if (v.trim().isEmpty) throw ValidationError('Identifier cannot be empty');
      if (v.contains(' '))
        throw ValidationError('Identifier must not contain spaces');
      return true;
    },
  ).interact();

  final name = Input(
    prompt: 'Display name',
    validator: (v) {
      if (v.trim().isEmpty) throw ValidationError('Name cannot be empty');
      return true;
    },
  ).interact();

  final description = Input(
    prompt: 'Description (optional, press Enter to skip)',
  ).interact();

  final image = Input(
    prompt: 'Image URL (optional, press Enter to skip)',
  ).interact();

  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Publishing badge definition...',
      SpinnerStateType.done => 'Published',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  try {
    final anchor = await client.upsertBadgeDefinition(
      identifier: identifier.trim(),
      name: name.trim(),
      description: description.trim().isNotEmpty ? description.trim() : null,
      image: image.trim().isNotEmpty ? image.trim() : null,
    );
    spinner.done();
    print('');
    print('  Badge definition created.');
    print(kvTable({'Anchor': anchor}));
    print('');
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
  }

  pressAnyKey();
  return Navigation.to(Screen.badgeDefinitionList);
}

// ── Edit / delete badge definition ──────────────────────────────────────────

Future<Navigation> badgeDefinitionEditScreen(
  DaemonClient client,
  String anchor,
) async {
  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading...',
      SpinnerStateType.done => 'Loaded',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  List<BadgeDefinitionSummary> all;
  try {
    all = await client.listBadgeDefinitions();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    pressAnyKey();
    return Navigation.to(Screen.badgeDefinitionList);
  }

  final current = all.where((d) => d.anchor == anchor).firstOrNull;
  if (current == null) {
    print('  Definition not found for anchor: $anchor');
    print('');
    pressAnyKey();
    return Navigation.to(Screen.badgeDefinitionList);
  }

  print('');
  print(sectionHeader('Badge Definition: ${current.identifier}'));
  print('');
  print(kvTable({
    'Anchor': current.anchor,
    'Name': current.name,
    'Description': current.description ?? '-',
    'Image': current.image ?? '-',
  }));
  print('');

  final actions = [
    'Update name / description / image',
    'Delete this badge definition',
    'View awards for this badge',
  ];

  final idx = SelectOrBack(prompt: 'Action', options: actions).interact();

  switch (idx) {
    case -1:
      return Navigation.to(Screen.badgeDefinitionList);

    case 0:
      return await _editBadgeDefinitionFields(client, current);

    case 1:
      return await _deleteBadgeDefinitionConfirm(client, current);

    case 2:
      return Navigation(
        Screen.badgeAwardList,
        selectedBadgeDefinitionAnchor: current.anchor,
      );

    default:
      return Navigation.to(Screen.badgeDefinitionList);
  }
}

Future<Navigation> _editBadgeDefinitionFields(
  DaemonClient client,
  BadgeDefinitionSummary current,
) async {
  print('');
  print('  Leave blank to keep existing value.\n');

  final name = Input(
    prompt: 'Name [${current.name}]',
  ).interact();

  final description = Input(
    prompt: 'Description [${current.description ?? ''}]',
  ).interact();

  final image = Input(
    prompt: 'Image URL [${current.image ?? ''}]',
  ).interact();

  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Publishing update...',
      SpinnerStateType.done => 'Updated',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  try {
    await client.upsertBadgeDefinition(
      identifier: current.identifier,
      name: name.trim().isNotEmpty ? name.trim() : current.name,
      description: description.trim().isNotEmpty
          ? description.trim()
          : current.description,
      image: image.trim().isNotEmpty ? image.trim() : current.image,
    );
    spinner.done();
    print('  Badge definition updated.\n');
  } catch (e) {
    spinner.failed();
    print('  Error: $e\n');
  }

  pressAnyKey();
  return Navigation(
    Screen.badgeDefinitionEdit,
    selectedBadgeDefinitionAnchor: current.anchor,
  );
}

Future<Navigation> _deleteBadgeDefinitionConfirm(
  DaemonClient client,
  BadgeDefinitionSummary current,
) async {
  print('');
  final confirm = Confirm(
    prompt:
        'Delete badge definition "${current.name}" (${current.identifier})?',
    defaultValue: false,
  ).interact();

  if (!confirm) return Navigation.to(Screen.badgeDefinitionList);

  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Deleting...',
      SpinnerStateType.done => 'Deleted',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  try {
    await client.deleteBadgeDefinition(current.anchor);
    spinner.done();
    print('  Badge definition deleted.\n');
  } catch (e) {
    spinner.failed();
    print('  Error: $e\n');
  }

  pressAnyKey();
  return Navigation.to(Screen.badgeDefinitionList);
}

// ── Badge award list ─────────────────────────────────────────────────────────

Future<Navigation> badgeAwardListScreen(
  DaemonClient client, {
  String? filterDefinitionAnchor,
}) async {
  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading badge awards...',
      SpinnerStateType.done => 'Loaded',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  List<BadgeAwardSummary> awards;
  List<BadgeDefinitionSummary> definitions;
  try {
    awards =
        await client.listBadgeAwards(definitionAnchor: filterDefinitionAnchor);
    definitions = await client.listBadgeDefinitions();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    pressAnyKey();
    return Navigation.to(Screen.badgeMenu);
  }

  final defByAnchor = {for (final d in definitions) d.anchor: d};

  print('');
  final headerLabel = filterDefinitionAnchor != null
      ? 'Badge Awards -- ${defByAnchor[filterDefinitionAnchor]?.name ?? filterDefinitionAnchor}'
      : 'Badge Awards';
  print(sectionHeader(headerLabel));
  print('');

  if (awards.isNotEmpty) {
    final table = Table()
        .headers(['#', 'Badge', 'Recipient', 'Listing', 'Issued'])
        .border(Border.rounded)
        .padding(1)
        .headerStyle(Style().bold().foreground(Colors.cyan));
    for (var i = 0; i < awards.length; i++) {
      final a = awards[i];
      final badgeName = defByAnchor[a.definitionAnchor]?.name ??
          _trunc(a.definitionAnchor, 16);
      final recipient = _trunc(a.recipientPubkey, 12);
      final listing =
          a.listingAnchor != null ? _trunc(a.listingAnchor!, 16) : '-';
      table.row([
        '${i + 1}',
        badgeName,
        '$recipient...',
        listing,
        relativeTime(a.issuedAt),
      ]);
    }
    print(table.render());
    print('');
  } else {
    print('  No badge awards found.\n');
  }

  final options = [
    '+ Award a badge',
    ...awards.asMap().entries.map((e) {
      final a = e.value;
      final badgeName = defByAnchor[a.definitionAnchor]?.name ?? '?';
      final listing = a.listingAnchor != null ? ' [listing]' : '';
      return '${e.key + 1}. $badgeName -> ${_trunc(a.recipientPubkey, 12)}...$listing';
    }),
  ];

  final idx = SelectOrBack(prompt: 'Badge Awards', options: options).interact();

  if (idx == -1) return Navigation.to(Screen.badgeMenu);

  if (idx == 0) {
    return Navigation.to(Screen.badgeAward);
  }

  return await _revokeAwardConfirm(client, awards[idx - 1]);
}

Future<Navigation> _revokeAwardConfirm(
  DaemonClient client,
  BadgeAwardSummary award,
) async {
  print('');
  print(sectionHeader('Revoke Badge Award'));
  print('');
  final tableData = <String, String>{
    'Award ID': _trunc(award.id, 20),
    'Badge': award.definitionAnchor,
    'Recipient': award.recipientPubkey,
    'Issued': award.issuedAt.toLocal().toString(),
  };
  if (award.listingAnchor != null) {
    tableData['Listing'] = award.listingAnchor!;
  }
  print(kvTable(tableData));
  print('');

  final confirm = Confirm(
    prompt: 'Revoke this badge award?',
    defaultValue: false,
  ).interact();

  if (!confirm) return Navigation.to(Screen.badgeAwardList);

  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Revoking...',
      SpinnerStateType.done => 'Revoked',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  try {
    await client.revokeBadge(award.id);
    spinner.done();
    print('  Badge award revoked.\n');
  } catch (e) {
    spinner.failed();
    print('  Error: $e\n');
  }

  pressAnyKey();
  return Navigation.to(Screen.badgeAwardList);
}

// ── Assign badge screen ──────────────────────────────────────────────────────

Future<Navigation> badgeAwardScreen(DaemonClient client) async {
  final spinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading badge definitions...',
      SpinnerStateType.done => 'Loaded',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  List<BadgeDefinitionSummary> definitions;
  try {
    definitions = await client.listBadgeDefinitions();
    spinner.done();
  } catch (e) {
    spinner.failed();
    print('  Error: $e');
    print('');
    pressAnyKey();
    return Navigation.to(Screen.badgeAwardList);
  }

  if (definitions.isEmpty) {
    print('');
    print('  No badge definitions found. Create one first.');
    print('');
    pressAnyKey();
    return Navigation.to(Screen.badgeMenu);
  }

  print('');
  print(sectionHeader('Award a Badge'));
  print('');

  // Step 1: Choose badge definition.
  final defOptions =
      definitions.map((d) => '${d.name}  [${d.identifier}]').toList();
  final defIdx =
      SelectOrBack(prompt: 'Select badge', options: defOptions).interact();
  if (defIdx == -1) return Navigation.to(Screen.badgeAwardList);

  final selectedDef = definitions[defIdx];

  // Step 2: Target — npub (user) or naddr (listing).
  final targetRaw = Input(
    prompt: 'Recipient: npub1... (user) or naddr1... (listing)',
    validator: (v) {
      _resolveTarget(v); // throws ValidationError if invalid
      return true;
    },
  ).interact();
  final target = _resolveTarget(targetRaw);
  final recipientPubkey = target.recipientPubkey;
  final listingAnchor = target.listingAnchor;

  // Confirm.
  print('');
  print(kvTable({
    'Badge': '${selectedDef.name} [${selectedDef.identifier}]',
    'Recipient': recipientPubkey.trim(),
    'Scope':
        listingAnchor != null ? 'Listing: ${listingAnchor.trim()}' : 'User',
  }));
  print('');

  final confirm = Confirm(
    prompt: 'Award this badge?',
    defaultValue: true,
  ).interact();

  if (!confirm) return Navigation.to(Screen.badgeAwardList);

  final awardSpinner = Spinner(
    icon: 'v',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Publishing badge award...',
      SpinnerStateType.done => 'Published',
      SpinnerStateType.failed => 'Failed',
    },
  ).interact();

  try {
    final awardId = await client.awardBadge(
      definitionAnchor: selectedDef.anchor,
      recipientPubkey: recipientPubkey.trim(),
      listingAnchor: listingAnchor?.trim(),
    );
    awardSpinner.done();
    print('');
    print('  Badge awarded.');
    print(kvTable({'Award ID': awardId}));
    print('');
  } catch (e) {
    awardSpinner.failed();
    print('  Error: $e\n');
  }

  pressAnyKey();
  return Navigation.to(Screen.badgeAwardList);
}
