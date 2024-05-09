import 'dart:io';

import 'package:intl/intl.dart';
import 'package:vania_cli/common/recase.dart';
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

String migrateFileContents = '''
import 'dart:io';

import 'package:vania/vania.dart';

import '../../config/database.dart';

void main(List<String> args) async {
  Env().load();
  if (args.isNotEmpty && args.first.toLowerCase() == "migrate:fresh") {
    await Migrate().dropTables();
  } else {
    await Migrate().registry();
  }
  await MigrationConnection().closeConnection();
  exit(0);
}

class Migrate {
  registry() async {
    await MigrationConnection().setup(databaseConfig);
  }

  dropTables() async {
    await MigrationConnection().setup(databaseConfig);
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

    File migrate =
        File('${Directory.current.path}/lib/database/migrations/migrate.dart');

    if (!migrate.existsSync()) {
      migrate.createSync(recursive: true);
    } else {
      migrateFileContents = migrate.readAsStringSync();
    }

    final importRegExp = RegExp(r'import .+;');
    final registryConstructorRegex =
        RegExp(r'registry\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');
    final dropTableConstructorRegex =
        RegExp(r'dropTables\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

    // Find import statement and append new import
    var importMatch = importRegExp.allMatches(migrateFileContents);
    if (importMatch.isNotEmpty) {
      migrateFileContents = migrateFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0)}\nimport '$migrationFileName';",
      );
    }

    // Find registry and dropTables constructors, and replace with modified versions
    Match? registryRepositoriesBlockMatch =
        registryConstructorRegex.firstMatch(migrateFileContents);
    Match? dropTableRepositoriesBlockMatch =
        dropTableConstructorRegex.firstMatch(migrateFileContents);

    if (registryRepositoriesBlockMatch != null &&
        dropTableRepositoriesBlockMatch != null) {
      migrateFileContents = migrateFileContents.replaceAll(
        registryConstructorRegex,
        '''registry() async {\n\t\t${registryRepositoriesBlockMatch.group(1)}\n\t\t await ${migrationName.pascalCase}().up();\n\t}''',
      ).replaceAll(
        dropTableConstructorRegex,
        '''dropTables() async {\n\t\t${dropTableRepositoriesBlockMatch.group(1)}\n\t\t await ${migrationName.pascalCase}().down();\n\t }''',
      );
    }

    // Write modified content back to file
    migrate.writeAsStringSync(migrateFileContents);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.');
  }
}
