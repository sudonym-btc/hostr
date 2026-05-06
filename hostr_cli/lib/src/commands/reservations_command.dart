import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'action_bridge.dart';
import 'base.dart';

class ReservationsCommand extends Command<int> {
  ReservationsCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(ReservationOfferCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ReservationPayCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ReservationCommitCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ReservationCancelCommand(stdout: stdout, stderr: stderr));
    addSubcommand(
      ReservationNegotiationCommand(stdout: stdout, stderr: stderr),
    );
    addSubcommand(TripsListCommand(stdout: stdout, stderr: stderr));
    addSubcommand(BookingsListCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'reservations';

  @override
  final String description = 'Create and manage Hostr reservations.';
}

class ReservationOfferCommand extends HostrCliCommand {
  ReservationOfferCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Reservation JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Broadcast without interactive confirmation.',
      );
  }

  @override
  final String name = 'offer';

  @override
  final String description =
      'Send a private gift-wrapped negotiate-stage reservation offer.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.reservations.negotiateOffer',
      input: input,
      requireYesForLive: true,
    );
  }
}

class ReservationPayCommand extends HostrCliCommand {
  ReservationPayCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'trade-context',
        mandatory: true,
        help: 'Trade context JSON file, inline object, or trade id.',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Broadcast/transact without interactive confirmation.',
      );
  }

  @override
  final String name = 'pay';

  @override
  final String description =
      'Create the Boltz swap invoice for a payable reservation trade.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = _readTradeContextArg(this);
    return runSharedAction(
      this,
      action: 'hostr.reservations.pay',
      input: input,
      requireYesForLive: true,
    );
  }
}

class ReservationCommitCommand extends HostrCliCommand {
  ReservationCommitCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption('swap-id', mandatory: true, help: 'Boltz swap id.')
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Publish the committed reservation without prompting.',
      );
  }

  @override
  final String name = 'commit';

  @override
  final String description =
      'Publish a public commit-stage reservation with escrow proof.';

  @override
  Future<HostrCliResult> runCommand() async {
    final swapId = (argResults?['swap-id'] as String).trim();
    return runSharedAction(
      this,
      action: 'hostr.reservations.commit',
      input: {'swapId': swapId},
      requireYesForLive: true,
    );
  }
}

class ReservationCancelCommand extends HostrCliCommand {
  ReservationCancelCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Cancel JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Broadcast without interactive confirmation.',
      );
  }

  @override
  final String name = 'cancel';

  @override
  final String description =
      'Cancel a private negotiation or a committed reservation.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.reservations.cancel',
      input: input,
      requireYesForLive: true,
    );
  }
}

class ReservationNegotiationCommand extends Command<int> {
  ReservationNegotiationCommand({
    required IOSink stdout,
    required IOSink stderr,
  }) {
    addSubcommand(
      ReservationNegotiationOfferCommand(stdout: stdout, stderr: stderr),
    );
    addSubcommand(
      ReservationNegotiationAcceptCommand(stdout: stdout, stderr: stderr),
    );
  }

  @override
  final String name = 'negotiation';

  @override
  final String description = 'Manage reservation negotiation events.';
}

class ReservationNegotiationOfferCommand extends HostrCliCommand {
  ReservationNegotiationOfferCommand({
    required super.stdout,
    required super.stderr,
  }) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Offer JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Broadcast without interactive confirmation.',
      );
  }

  @override
  final String name = 'offer';

  @override
  final String description = 'Send a reservation negotiation offer.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.reservations.negotiateOffer',
      input: input,
      requireYesForLive: true,
    );
  }
}

class ReservationNegotiationAcceptCommand extends HostrCliCommand {
  ReservationNegotiationAcceptCommand({
    required super.stdout,
    required super.stderr,
  }) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Accept JSON input file, inline object, or "-".',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Broadcast without interactive confirmation.',
      );
  }

  @override
  final String name = 'accept';

  @override
  final String description = 'Accept the latest reservation negotiation offer.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.reservations.negotiateAccept',
      input: input,
      requireYesForLive: true,
    );
  }
}

class TripsListCommand extends HostrCliCommand {
  TripsListCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('limit', defaultsTo: '50');
  }

  @override
  final String name = 'trips';

  @override
  final String description =
      'List reservation events involving the active user as guest.';

  @override
  Future<HostrCliResult> runCommand() =>
      _runReservationCollection(this, action: 'hostr.trips.list');
}

class BookingsListCommand extends HostrCliCommand {
  BookingsListCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('limit', defaultsTo: '50');
  }

  @override
  final String name = 'bookings';

  @override
  final String description =
      'List reservation events for listings authored by the active user.';

  @override
  Future<HostrCliResult> runCommand() =>
      _runReservationCollection(this, action: 'hostr.bookings.list');
}

class TripsCommand extends Command<int> {
  TripsCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(TripsListTopLevelCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'trips';

  @override
  final String description = 'List and inspect trips for the active user.';
}

class TripsListTopLevelCommand extends HostrCliCommand {
  TripsListTopLevelCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('limit', defaultsTo: '50');
  }

  @override
  final String name = 'list';

  @override
  final String description = 'List trips for the active user.';

  @override
  Future<HostrCliResult> runCommand() =>
      _runReservationCollection(this, action: 'hostr.trips.list');
}

class BookingsCommand extends Command<int> {
  BookingsCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(BookingsListTopLevelCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'bookings';

  @override
  final String description =
      'List and inspect host bookings for the active user.';
}

class BookingsListTopLevelCommand extends HostrCliCommand {
  BookingsListTopLevelCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('limit', defaultsTo: '50');
  }

  @override
  final String name = 'list';

  @override
  final String description = 'List bookings for the active user.';

  @override
  Future<HostrCliResult> runCommand() =>
      _runReservationCollection(this, action: 'hostr.bookings.list');
}

Future<HostrCliResult> _runReservationCollection(
  HostrCliCommand command, {
  required String action,
}) {
  final limit =
      int.tryParse((command.argResults?['limit'] as String?) ?? '') ?? 50;
  return runSharedAction(command, action: action, input: {'limit': limit});
}

Map<String, dynamic> _readTradeContextArg(HostrCliCommand command) {
  final raw = (command.argResults?['trade-context'] as String?)?.trim();
  if (raw == null || raw.isEmpty) {
    throw HostrCliException(
      'missing_trade_context',
      'Pass --trade-context with a trade id, JSON object, or JSON file path.',
      exitCode: 64,
    );
  }
  if (raw.startsWith('{')) {
    return jsonDecode(raw) as Map<String, dynamic>;
  }
  final file = File(raw);
  if (file.existsSync()) {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
  return {'tradeId': raw};
}
