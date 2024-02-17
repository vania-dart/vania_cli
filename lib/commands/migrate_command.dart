import 'dart:convert';
import 'dart:io';

import 'package:vania_cli/commands/command.dart';

class MigrateCommand extends Command {
  @override
  String get name => 'migrate';

  @override
  String get description => 'Run the database migrations';

  @override
  void execute(List<String> arguments) async {
    print('\x1B[32m Migration started \x1B[0m');
    Process process = await Process.start('dart',
        ['run','\\lib\\database\\migrations\\migrate.dart']);

    await for (var data in process.stdout.transform(utf8.decoder)) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    }
    print('\n\n \x1B[42m SUCCESS \x1B[0m All done.\n\n');
  }
}
