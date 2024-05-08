import 'dart:convert';
import 'dart:io';

import 'command.dart';

class MigrateDatabaseSeederCommand implements Command {
  @override
  String get name => "migrate:seed";

  @override
  String get description => "Run the database seeders";

  @override
  void execute(List<String> arguments) async {
    print('\x1B[32m Database seed started \x1B[0m');
    Process process = await Process.start(
      'dart',
      ['run', '${Directory.current.path}/lib/database/seeders/database_seeder.dart'],
    );

    await for (var data in process.stdout.transform(utf8.decoder)) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    }
  }
}
