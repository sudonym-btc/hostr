import 'dart:io';

import 'package:hostr_cli/hostr_cli.dart';

Future<void> main(List<String> arguments) async {
  final exitCode = await runHostrCli(arguments, stdout: stdout, stderr: stderr);
  await stdout.flush();
  await stderr.flush();
  exit(exitCode);
}
