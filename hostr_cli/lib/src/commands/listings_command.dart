import 'dart:io';

import 'package:args/command_runner.dart';

import 'action_bridge.dart';
import 'base.dart';

class ListingsCommand extends Command<int> {
  ListingsCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(ListingsSearchCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ListingsListCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ListingsCreateCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ListingsEditCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ListingsAvailableCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ListingsReviewsCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ListingsReservationsCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'listings';

  @override
  final String description =
      'Search, list, create, edit, and inspect Hostr listings.';
}

class ListingsSearchCommand extends HostrCliCommand {
  ListingsSearchCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption('input', help: 'JSON input file, inline object, or "-".')
      ..addOption(
        'location',
        help: 'Location text to resolve to H3 polygon cover.',
      )
      ..addOption(
        'query',
        help: 'Client-side text filter over title/description.',
      )
      ..addOption('type', help: 'Listing type.')
      ..addOption('guests', help: 'Minimum guests.')
      ..addMultiOption('feature', help: 'Required feature/spec.')
      ..addOption('limit', defaultsTo: '10');
  }

  @override
  final String name = 'search';

  @override
  final String description = 'Search Hostr marketplace listings.';

  @override
  Future<HostrCliResult> runCommand() {
    final input = _optionalInput(this);
    final features = [
      ...stringListOption('feature'),
      ..._stringList(input['features']),
    ];
    return runSharedAction(
      this,
      action: 'hostr.listings.search',
      input: {
        ...input,
        if (argResults?['location'] != null)
          'location': argResults!['location'],
        if (argResults?['query'] != null) 'query': argResults!['query'],
        if (argResults?['type'] != null) 'type': argResults!['type'],
        if (argResults?['guests'] != null) 'guests': argResults!['guests'],
        if (features.isNotEmpty) 'features': features,
        if (argResults?['limit'] != null) 'limit': argResults!['limit'],
      },
    );
  }
}

class ListingsListCommand extends HostrCliCommand {
  ListingsListCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addFlag('mine', help: 'List listings authored by the active pubkey.')
      ..addOption('author', help: 'List listings authored by this pubkey.')
      ..addOption('limit', defaultsTo: '50');
  }

  @override
  final String name = 'list';

  @override
  final String description = 'List listings.';

  @override
  Future<HostrCliResult> runCommand() {
    return runSharedAction(
      this,
      action: 'hostr.listings.list',
      input: {
        'mine': argResults?['mine'] == true,
        if (argResults?['author'] != null) 'author': argResults!['author'],
        if (argResults?['limit'] != null) 'limit': argResults!['limit'],
      },
    );
  }
}

class ListingsCreateCommand extends HostrCliCommand {
  ListingsCreateCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Listing JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Publish without interactive confirmation.',
      );
  }

  @override
  final String name = 'create';

  @override
  final String description = 'Create a Hostr listing.';

  @override
  Future<HostrCliResult> runCommand() {
    return runSharedAction(
      this,
      action: 'hostr.listings.create',
      input: readInputObject(),
      requireYesForLive: true,
    );
  }
}

class ListingsEditCommand extends HostrCliCommand {
  ListingsEditCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption('anchor', help: 'Listing naddr/a-tag anchor.')
      ..addOption(
        'input',
        mandatory: true,
        help: 'Listing patch JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Publish without interactive confirmation.',
      );
  }

  @override
  final String name = 'edit';

  @override
  final String description = 'Edit an existing Hostr listing.';

  @override
  Future<HostrCliResult> runCommand() {
    final input = readInputObject();
    final anchor =
        (argResults?['anchor'] as String?)?.trim() ??
        input['anchor']?.toString().trim();
    final patch = Map<String, dynamic>.from(input)..remove('anchor');
    return runSharedAction(
      this,
      action: 'hostr.listings.edit',
      input: {
        if (anchor != null && anchor.isNotEmpty) 'anchor': anchor,
        'patch': patch,
      },
      requireYesForLive: true,
    );
  }
}

class ListingsAvailableCommand extends HostrCliCommand {
  ListingsAvailableCommand({required super.stdout, required super.stderr}) {
    argParser.addOption(
      'input',
      mandatory: true,
      help: 'JSON input with anchors, start, end.',
    );
  }

  @override
  final String name = 'available';

  @override
  final String description = 'Check listing availability for dates.';

  @override
  Future<HostrCliResult> runCommand() => runSharedAction(
    this,
    action: 'hostr.listings.availability',
    input: readInputObject(),
  );
}

class ListingsReviewsCommand extends HostrCliCommand {
  ListingsReviewsCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('input', help: 'JSON input with anchors.');
    argParser.addMultiOption('anchor', help: 'Listing anchor.');
  }

  @override
  final String name = 'reviews';

  @override
  final String description = 'Fetch reviews for listings.';

  @override
  Future<HostrCliResult> runCommand() => runSharedAction(
    this,
    action: 'hostr.listings.reviews',
    input: _anchorsInput(this),
  );
}

class ListingsReservationsCommand extends HostrCliCommand {
  ListingsReservationsCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('input', help: 'JSON input with anchors.');
    argParser.addMultiOption('anchor', help: 'Listing anchor.');
  }

  @override
  final String name = 'reservations';

  @override
  final String description = 'Fetch reservation groups for listings.';

  @override
  Future<HostrCliResult> runCommand() => runSharedAction(
    this,
    action: 'hostr.listings.reservationGroups',
    input: _anchorsInput(this),
  );
}

Map<String, dynamic> _optionalInput(HostrCliCommand command) {
  final raw = command.argResults?['input'] as String?;
  if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
  return command.readInputObject();
}

Map<String, dynamic> _anchorsInput(HostrCliCommand command) {
  final input = _optionalInput(command);
  final anchors = [
    ...command.stringListOption('anchor'),
    ..._stringList(input['anchors'] ?? input['anchor']),
  ].where((anchor) => anchor.trim().isNotEmpty).toList();
  if (anchors.isEmpty) {
    throw HostrCliException(
      'missing_anchor',
      'Pass at least one --anchor or input.anchors value.',
      exitCode: 64,
    );
  }
  return {...input, 'anchors': anchors};
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value.map((item) => item.toString()).toList();
  return value.toString().split(',').map((item) => item.trim()).toList();
}
