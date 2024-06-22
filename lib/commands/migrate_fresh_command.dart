import 'dart:convert';
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
    stdout.writeln('\x1B[32m Dropping tables ........... \x1B[0m');
    Process process = await Process.start(
      'dart',
      [
        'run',
        '${Directory.current.path}/lib/database/migrations/migrate.dart',
        'migrate:fresh',
      ],
    );

    process.stdout.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          stdout.write('\x1B[32m $line \x1B[0m\n');
        }
      }
    }).onDone(() {
      stdout.writeln('\n\n\x1B[42m SUCCESS \x1B[0m All done!');
      CommandRunner().run(["migrate"]);
    });
  }
}
