import 'action_bridge.dart';
import 'base.dart';

class EscrowMethodsCommand extends HostrCliCommand {
  EscrowMethodsCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'user',
        mandatory: true,
        help: 'Seller/host pubkey to inspect escrow compatibility for.',
      )
      ..addOption(
        'buyer',
        help: 'Buyer pubkey. Defaults to the active session pubkey.',
      );
  }

  @override
  final String name = 'escrow-methods';

  @override
  final String description =
      'Show mutual escrow methods and compatible services for a seller.';

  @override
  Future<HostrCliResult> runCommand() async {
    final input = <String, dynamic>{
      'user': (argResults?['user'] as String).trim(),
    };
    final buyer = (argResults?['buyer'] as String?)?.trim();
    if (buyer != null && buyer.isNotEmpty) input['buyer'] = buyer;
    return runSharedAction(this, action: 'hostr.escrow.methods', input: input);
  }
}
