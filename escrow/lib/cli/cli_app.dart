import 'dart:io';

import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/cli/screens/arbitrate.dart';
import 'package:escrow/cli/screens/audit.dart';
import 'package:escrow/cli/screens/badges.dart';
import 'package:escrow/cli/screens/navigation.dart';
import 'package:escrow/cli/screens/profile_edit.dart';
import 'package:escrow/cli/screens/service_edit.dart';
import 'package:escrow/cli/screens/service_list.dart';
import 'package:escrow/cli/screens/thread_detail.dart';
import 'package:escrow/cli/screens/thread_list.dart';
import 'package:escrow/cli/screens/trade_detail.dart';
import 'package:escrow/cli/screens/trade_list.dart';
import 'package:escrow/cli/styles.dart';
import 'package:escrow/cli/widgets.dart';
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
    String? selectedBadgeDefinitionAnchor;

    while (nav.next != Screen.exit) {
      // Merge context from the navigation result.
      selectedTradeId = nav.selectedTradeId ?? selectedTradeId;
      selectedThreadId = nav.selectedThreadId ?? selectedThreadId;
      selectedServiceId = nav.selectedServiceId ?? selectedServiceId;
      selectedBadgeDefinitionAnchor =
          nav.selectedBadgeDefinitionAnchor ?? selectedBadgeDefinitionAnchor;

      // Clear screen between navigations for a clean view.
      _clearScreen();

      try {
        nav = await _runScreen(nav.next, selectedTradeId, selectedThreadId,
            selectedServiceId, selectedBadgeDefinitionAnchor);
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
    String? badgeDefinitionAnchor,
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

      case Screen.badgeMenu:
        return await badgeMenuScreen(client);

      case Screen.badgeDefinitionList:
        return await badgeDefinitionListScreen(client);

      case Screen.badgeDefinitionCreate:
        return await badgeDefinitionCreateScreen(client);

      case Screen.badgeDefinitionEdit:
        if (badgeDefinitionAnchor == null) {
          return Navigation.to(Screen.badgeDefinitionList);
        }
        return await badgeDefinitionEditScreen(client, badgeDefinitionAnchor);

      case Screen.badgeAwardList:
        return await badgeAwardListScreen(
          client,
          filterDefinitionAnchor: badgeDefinitionAnchor,
        );

      case Screen.badgeAward:
        return await badgeAwardScreen(client);

      case Screen.exit:
        return Navigation.to(Screen.exit);
    }
  }

  /// Wraps [mainMenuScreen] but also handles the "Daemon status" option inline.
  Future<Navigation> _mainMenuWithStatus() async {
    final options = [
      'Trades',
      'Threads',
      'Services',
      'Profile',
      'Badges',
      'EVM mnemonic',
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
        return Navigation.to(Screen.badgeMenu);
      case 5:
        await _showEvmMnemonic();
        return Navigation.to(Screen.mainMenu);
      case 6:
        await _showStatus();
        return Navigation.to(Screen.mainMenu);
      case 7:
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

  Future<void> _showEvmMnemonic() async {
    try {
      final info = await client.getEvmMnemonic();
      final mnemonic = info['mnemonic'] as String;
      final evmAddress = info['evmAddress'] as String;
      final path = info['derivationPath'] as String;

      print('');
      print(sectionHeader('EVM Mnemonic (MetaMask-compatible)'));
      print('');
      print(kvTable({
        'Address': evmAddress,
        'Derivation path': path,
        'Mnemonic': mnemonic,
      }));
      print('');
      print(kWarnStyle.render(
          '  ⚠ Keep this mnemonic secret — it controls the escrow EVM wallet.'));
      print('');
      pressAnyKey();
    } catch (e) {
      print('  Error: $e');
      print('');
      pressAnyKey();
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
      print(sectionHeader('Daemon Status'));
      print(kvTable({
        'Status': colorStatus('${status['status']}'),
        'Tracked trades': '${status['trackedTrades']}',
        'Pending trades': '${status['pendingTrades']}',
        'Synced threads': '${status['syncedThreads']}',
      }));
      print('');
      pressAnyKey();
    } catch (e) {
      spinner.failed();
      print('  Error: $e');
      print('');
      pressAnyKey();
    }
  }
}
