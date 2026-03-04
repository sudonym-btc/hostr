import 'dart:io';

import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/arbitrate.dart';
import 'package:escrow/cli/screens/audit.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/screens/profile_edit.dart';
import 'package:escrow/cli/screens/service_edit.dart';
import 'package:escrow/cli/screens/service_list.dart';
import 'package:escrow/cli/screens/thread_detail.dart';
import 'package:escrow/cli/screens/thread_list.dart';
import 'package:escrow/cli/screens/trade_detail.dart';
import 'package:escrow/cli/screens/trade_list.dart';
import 'package:interact_cli/interact_cli.dart';

/// Main interactive CLI loop.
///
/// Connects to the daemon, then navigates between screens using a simple
/// state machine. Each screen returns a [Navigation] telling us where to go
/// next and what context to carry forward.
class CliApp {
  final DaemonClient client;

  CliApp({required this.client});

  Future<void> run() async {
    var nav = Navigation.to(Screen.mainMenu);

    // Carried context
    String? selectedTradeId;
    String? selectedThreadId;
    String? selectedServiceId;

    while (nav.next != Screen.exit) {
      // Merge context from the navigation result.
      selectedTradeId = nav.selectedTradeId ?? selectedTradeId;
      selectedThreadId = nav.selectedThreadId ?? selectedThreadId;
      selectedServiceId = nav.selectedServiceId ?? selectedServiceId;

      // Clear screen between navigations for a clean view.
      _clearScreen();

      try {
        nav = await _runScreen(
            nav.next, selectedTradeId, selectedThreadId, selectedServiceId);
      } catch (e) {
        print('\n  Unexpected error: $e');
        nav = Navigation.to(Screen.mainMenu);
      }
    }

    print('Goodbye.');
  }

  Future<Navigation> _runScreen(
    Screen screen,
    String? tradeId,
    String? threadId,
    String? serviceId,
  ) async {
    switch (screen) {
      case Screen.mainMenu:
        return await _mainMenuWithStatus();

      case Screen.tradeList:
        return await tradeListScreen(client);

      case Screen.tradeDetail:
        if (tradeId == null) return Navigation.to(Screen.tradeList);
        return await tradeDetailScreen(client, tradeId);

      case Screen.audit:
        if (tradeId == null) return Navigation.to(Screen.tradeList);
        return await auditScreen(client, tradeId);

      case Screen.arbitrate:
        if (tradeId == null) return Navigation.to(Screen.tradeList);
        return await arbitrateScreen(client, tradeId);

      case Screen.threadList:
        return await threadListScreen(client);

      case Screen.threadDetail:
        if (threadId == null) return Navigation.to(Screen.threadList);
        return await threadDetailScreen(client, threadId);

      case Screen.serviceList:
        return await serviceListScreen(client);

      case Screen.serviceEdit:
        if (serviceId == null) return Navigation.to(Screen.serviceList);
        return await serviceEditScreen(client, serviceId);

      case Screen.profileEdit:
        return await profileEditScreen(client);

      case Screen.exit:
        return Navigation.to(Screen.exit);
    }
  }

  /// Wraps [mainMenuScreen] but also handles the "Daemon status" option inline.
  Future<Navigation> _mainMenuWithStatus() async {
    final options = [
      'Pending trades',
      'Threads',
      'Services',
      'Profile',
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
        return Navigation.to(Screen.serviceList);
      case 3:
        return Navigation.to(Screen.profileEdit);
      case 4:
        await _showStatus();
        return Navigation.to(Screen.mainMenu);
      case 5:
      default:
        return Navigation.to(Screen.exit);
    }
  }

  /// Clears the terminal using ANSI escape codes.
  void _clearScreen() {
    if (stdout.hasTerminal) {
      stdout.write('\x1B[2J\x1B[H');
    }
  }

  Future<void> _showStatus() async {
    final spinner = Spinner(
      icon: '✓',
      rightPrompt: (state) => switch (state) {
        SpinnerStateType.inProgress => 'Checking daemon status…',
        SpinnerStateType.done => 'Status OK',
        SpinnerStateType.failed => 'Status check failed',
      },
    ).interact();

    try {
      final status = await client.getStatus();
      spinner.done();
      print('');
      print('  Status         : ${status['status']}');
      print('  Tracked trades : ${status['trackedTrades']}');
      print('  Pending trades : ${status['pendingTrades']}');
      print('  Synced threads : ${status['syncedThreads']}');
      print('');
    } catch (e) {
      spinner.failed();
      print('  Error: $e');
      print('');
    }
  }
}
