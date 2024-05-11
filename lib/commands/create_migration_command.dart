import 'dart:io';

import 'package:intl/intl.dart';
import 'package:vania_cli/utils/functions.dart';

import 'command.dart';

String migrationStub = '''
import 'package:vania/vania.dart';

class MigrationName extends Migration {

  @override
  Future<void> up() async{
   super.up();
   await createTableNotExists('TableName', () {
      id();
      timeStamps();
    });
  }
  
  @override
  Future<void> down() async {
    super.down();
    await dropIfExists('DropTableName');
  }
}
''';

class CreateMigrationCommand implements Command {
  @override
  String get name => 'make:migration';

  @override
  String get description => 'Create a new migration file';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      print('  What should the migration be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_/\\]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Migration must contain only letters a-z, numbers 0-9 and optional _');
      exit(0);
    }

    String migrationName = arguments[0];

    String formattedDateTime =
        "${DateFormat('yyyy_MM_dd_HHmmss').format(DateTime.now().toLocal())}_";

    String migrationFileName =
        "$formattedDateTime${pascalToSnake(migrationName)}.dart";

    String filePath =
        '${Directory.current.path}/lib/database/migrations/$migrationFileName';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Migration already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);

    String tableName =
        migrationName.replaceAll('create_', '').replaceAll('_table', '');
    String str = migrationStub
        .replaceFirst('MigrationName', snakeToPascal(migrationName))
        .replaceFirst('TableName', tableName)
        .replaceFirst('DropTableName', tableName);

    newFile.writeAsString(str);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.');
  }
}
