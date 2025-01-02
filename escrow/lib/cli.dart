// filepath: /Users/sudonym/Documents/GitHub/hostr/nostr_service/bin/cli.dart
import 'package:args/args.dart';
import 'package:escrow/server.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('list-pending')
    ..addCommand('take-action');

  final argResults = parser.parse(arguments);

  switch (argResults.command?.name) {
    case 'list-active':
      break;
    case 'list-closed':
      break;
    case 'create-service':
      break;
    case 'update-service':
      break;
    case 'delete-service':
      break;
    case 'resolve':
      break;
    default:
      print('Unknown command');
  }
}
