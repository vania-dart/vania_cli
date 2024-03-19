import 'dart:convert';
import 'dart:io';

import 'command.dart';

class UpdateCommand implements Command {
  @override
  String get name => 'update';

  @override
  String get description => 'Update vania-cli to the latest version';

  @override
  void execute(List<String> arguments) async {
    final process =
        await Process.start('dart', ['pub', 'global', 'activate', 'vania_cli']);
    process.stdout.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    });
  }
}
