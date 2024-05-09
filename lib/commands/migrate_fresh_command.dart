import 'dart:io';

import 'package:vania_cli/commands/command_runner.dart';

import 'command.dart';

class MigrateFreshCommand implements Command {
  @override
  String get name => "migrate:fresh";

  @override
  String get description => "Drop all tables and re-run all migrations";

  @override
  void execute(List<String> arguments) async {
    print('\x1B[32m Dropping tables ........... \x1B[0m');
    await Process.start(
      'dart',
      [
        'run',
        '${Directory.current.path}/lib/database/migrations/migrate.dart',
        'migrate:fresh',
      ],
    );

    CommandRunner().run(["migrate"]);
  }
}
