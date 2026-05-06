import 'dart:io';

import 'package:args/command_runner.dart';

import 'action_bridge.dart';
import 'base.dart';

class ProfileCommand extends Command<int> {
  ProfileCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(ProfileShowCommand(stdout: stdout, stderr: stderr));
    addSubcommand(ProfileEditCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'profile';

  @override
  final String description = 'Show or update Hostr profile metadata.';
}

class ProfileShowCommand extends HostrCliCommand {
  ProfileShowCommand({required super.stdout, required super.stderr});

  @override
  final String name = 'show';

  @override
  final String description = 'Show profile metadata for the active session.';

  @override
  Future<HostrCliResult> runCommand() {
    return runSharedAction(this, action: 'hostr.profile.show', input: {});
  }
}

class ProfileEditCommand extends HostrCliCommand {
  ProfileEditCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'input',
        mandatory: true,
        help: 'Profile JSON input file, inline object, or "-".',
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
  final String description = 'Create or update active profile metadata.';

  @override
  Future<HostrCliResult> runCommand() {
    return runSharedAction(
      this,
      action: 'hostr.profile.edit',
      input: readInputObject(),
      requireYesForLive: true,
    );
  }
}
