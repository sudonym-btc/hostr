import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'action_bridge.dart';
import 'base.dart';

class OrdersCommand extends Command<int> {
  OrdersCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(OrderOfferCommand(stdout: stdout, stderr: stderr));
    addSubcommand(OrderPayCommand(stdout: stdout, stderr: stderr));
    addSubcommand(OrderCommitCommand(stdout: stdout, stderr: stderr));
    addSubcommand(OrderCancelCommand(stdout: stdout, stderr: stderr));
    addSubcommand(OrderNegotiationCommand(stdout: stdout, stderr: stderr));
    addSubcommand(TripsListCommand(stdout: stdout, stderr: stderr));
    addSubcommand(BookingsListCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'orders';

  @override
  final String description = 'Create and manage Hostr orders.';
}

class OrderOfferCommand extends HostrCliCommand {
  OrderOfferCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Order JSON input file, inline object, or "-".',
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
      'Send a private gift-wrapped negotiate-stage order offer.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.orders.negotiateOffer',
      input: input,
      requireYesForLive: true,
    );
  }
}

class OrderPayCommand extends HostrCliCommand {
  OrderPayCommand({required super.stdout, required super.stderr}) {
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
      'Create the Boltz swap invoice for a payable order trade.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = _readTradeContextArg(this);
    return runSharedAction(
      this,
      action: 'hostr.orders.pay',
      input: input,
      requireYesForLive: true,
    );
  }
}

class OrderCommitCommand extends HostrCliCommand {
  OrderCommitCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption('swap-id', mandatory: true, help: 'Boltz swap id.')
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Publish the committed order without prompting.',
      );
  }

  @override
  final String name = 'commit';

  @override
  final String description =
      'Publish a public commit-stage order with escrow proof.';

  @override
  Future<HostrCliResult> runCommand() async {
    final swapId = (argResults?['swap-id'] as String).trim();
    return runSharedAction(
      this,
      action: 'hostr.orders.commit',
      input: {'swapId': swapId},
      requireYesForLive: true,
    );
  }
}

class OrderCancelCommand extends HostrCliCommand {
  OrderCancelCommand({required super.stdout, required super.stderr}) {
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
      'Cancel a private negotiation or a committed order.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.orders.cancel',
      input: input,
      requireYesForLive: true,
    );
  }
}

class OrderNegotiationCommand extends Command<int> {
  OrderNegotiationCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(OrderNegotiationOfferCommand(stdout: stdout, stderr: stderr));
    addSubcommand(
      OrderNegotiationAcceptCommand(stdout: stdout, stderr: stderr),
    );
  }

  @override
  final String name = 'negotiation';

  @override
  final String description = 'Manage order negotiation events.';
}

class OrderNegotiationOfferCommand extends HostrCliCommand {
  OrderNegotiationOfferCommand({required super.stdout, required super.stderr}) {
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
  final String description = 'Send a order negotiation offer.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.orders.negotiateOffer',
      input: input,
      requireYesForLive: true,
    );
  }
}

class OrderNegotiationAcceptCommand extends HostrCliCommand {
  OrderNegotiationAcceptCommand({
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
  final String description = 'Accept the latest order negotiation offer.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = readInputObject();
    return runSharedAction(
      this,
      action: 'hostr.orders.negotiateAccept',
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
      'List order events involving the active user as guest.';

  @override
  Future<HostrCliResult> runCommand() =>
      _runOrderCollection(this, action: 'hostr.trips.list');
}

class BookingsListCommand extends HostrCliCommand {
  BookingsListCommand({required super.stdout, required super.stderr}) {
    argParser.addOption('limit', defaultsTo: '50');
  }

  @override
  final String name = 'bookings';

  @override
  final String description =
      'List order events for listings authored by the active user.';

  @override
  Future<HostrCliResult> runCommand() =>
      _runOrderCollection(this, action: 'hostr.bookings.list');
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
      _runOrderCollection(this, action: 'hostr.trips.list');
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
      _runOrderCollection(this, action: 'hostr.bookings.list');
}

Future<HostrCliResult> _runOrderCollection(
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
