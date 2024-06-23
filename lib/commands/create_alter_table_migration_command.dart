import 'dart:io';

import 'package:vania_cli/common/recase.dart';
import 'package:vania_cli/utils/functions.dart';

import 'command.dart';

String migrationStub = '''
import 'package:vania/vania.dart';

class MigrationALterNameClass extends Migration {
  @override
  Future<void> up() async {
    super.up();
    await alterColumn( 'TableName', (){
      
    });
  }
  
  @override
  Future<void> down() async{
    super.down();
  }
}

''';

String migrateFileContents = '''
import 'dart:io';

import 'package:vania/vania.dart';

void main(List<String> args) async {
		await MigrationConnection().setup();
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
  }

  dropTables() async {
  }
}
''';

class CreateAlterTableMigrationCommand implements Command {
  @override
  String get name => 'make:migration-alter';

  @override
  String get description =>
      'Create a new alter table migration file. This command allows you to add a new column to an existing table or alter an existing column';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      stdout.writeln('  What should the migration be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_/\\]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      stdout.writeln(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Migration must contain only letters a-z, numbers 0-9 and optional _');
      exit(0);
    }

    String migrationName = arguments[0].toLowerCase();

    if (arguments.length < 2) {
      stdout.writeln('To which table should this column be added?');
      stdout.writeln('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    String tableName = arguments[1].toLowerCase();

    String filePath =
        '${Directory.current.path}/lib/database/migrations/${pascalToSnake(migrationName)}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      stdout
          .writeln(' \x1B[41m\x1B[37m ERROR \x1B[0m Migration already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);

    String str = migrationStub
        .replaceFirst('MigrationALterNameClass', snakeToPascal(migrationName))
        .replaceFirst('TableName', tableName);

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

    // Find import statement and append new import
    var importMatch = importRegExp.allMatches(migrateFileContents);
    if (importMatch.isNotEmpty) {
      migrateFileContents = migrateFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0)}\nimport '${pascalToSnake(migrationName)}.dart';",
      );
    }

    // Find registry and dropTables constructors, and replace with modified versions
    Match? registryRepositoriesBlockMatch =
        registryConstructorRegex.firstMatch(migrateFileContents);

    if (registryRepositoriesBlockMatch != null) {
      migrateFileContents = migrateFileContents.replaceAll(
        registryConstructorRegex,
        '''registry() async {\n\t\t ${registryRepositoriesBlockMatch.group(1)}\n\t\t await ${migrationName.pascalCase}().up();\n\t}''',
      );
    }

    // Write modified content back to file
    migrate.writeAsStringSync(migrateFileContents);

    stdout.writeln(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.');
  }
}
