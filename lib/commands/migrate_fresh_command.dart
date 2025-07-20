import 'dart:convert';
import 'dart:io';
import 'command.dart';

class MigrateFreshCommand implements Command {
  final String flag;
  final String des;

  MigrateFreshCommand({required this.flag, required this.des});

  @override
  String get name => "migrate:fresh";

  @override
  String get description => des;

  @override
  void execute(List<String> arguments) async {
    arguments.remove(flag);
    Process process = await Process.start('dart', [
      'run',
      '${Directory.current.path}/lib/database/migrations/migrate.dart',
      flag,
      ...arguments,
    ]);

    process.stdout.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          stdout.write('\x1B[32m $line \x1B[0m\n');
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          stdout.writeln(line);
        }
      }
    });
  }
}
