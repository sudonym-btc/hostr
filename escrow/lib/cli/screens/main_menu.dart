import 'package:escrow/cli/screens/navigation.dart';
import 'package:interact_cli/interact_cli.dart';

/// The top-level main menu.
Future<Navigation> mainMenuScreen() async {
  final options = [
    'Pending trades',
    'Threads',
    'Daemon status',
    'Exit',
  ];

  final idx = Select(prompt: 'Escrow CLI', options: options).interact();

  switch (idx) {
    case 0:
      return Navigation.to(Screen.tradeList);
    case 1:
      return Navigation.to(Screen.threadList);
    case 2:
      return Navigation.to(Screen.mainMenu); // handled inline below
    case 3:
    default:
      return Navigation.to(Screen.exit);
  }
}
