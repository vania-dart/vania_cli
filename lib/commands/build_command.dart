import 'dart:convert';
import 'dart:io';

import 'package:vania_cli/commands/command.dart';

class BuildCommand extends Command {
  @override
  String get name => 'build';

  @override
  String get description => 'Serve the application';

  @override
  void execute(List<String> arguments) async {
    print("\x1B[32m Strting to build ... \x1B[0m");
    var process = await Process.start(
        'dart', ['compile', 'exe', 'bin/server.dart', '-o', 'bin/server']);

    process.stdout.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      print(lines.first.toString().replaceAll('INFO', 'Dox'));
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
