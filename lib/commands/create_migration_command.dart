import 'dart:io';

import 'package:vania_cli/common/recase.dart';
import 'package:vania_cli/utils/_pluralize.dart';
import 'package:vania_cli/utils/functions.dart';

import 'command.dart';

String migrationStub = '''
import 'package:vania/migration.dart';

class MigrationName extends Migration {
  @override
  Future<void> up() async {
    await create('TableName', (Schema table) {
      table.id();
      table.timeStamps();
    });
  }

  @override
  Future<void> down() async {
    await drop('DropTableName');
  }
}
''';

String migrateFileContents = '''
import 'dart:io';
import 'package:vania/database/database.dart';
import '../../config/database.dart';

void main(List<String> args) async {
  try {
    await MigrationConnection().setup(database);
    await MigrationRunner().migrationRegister([

    ]).run(args);
    wait MigrationConnection().connection?.close();
  } catch (e) {
    print('Migration failed: \$e');
    exit(0);
  } finally {
    exit(0);
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
      stdout.writeln('  What should the migration be named?');
      stdout.writeln('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[A-Za-z][A-Za-z_]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      stdout.writeln(
        ' \x1B[41m\x1B[37m ERROR \x1B[0m Migration must contain only letters a-z and optional _',
      );
      exit(0);
    }

    String migrationName = arguments[0].toLowerCase();

    String filePath =
        '${Directory.current.path}/lib/database/migrations/${pascalToSnake(migrationName)}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      stdout.writeln(
        ' \x1B[41m\x1B[37m ERROR \x1B[0m Migration already exists.',
      );
      exit(0);
    }

    newFile.createSync(recursive: true);

    String tableName = Pluralize().make(
      migrationName
          .replaceAll('create_', '')
          .replaceAll('_table', '')
          .toLowerCase(),
    );
    String str = migrationStub
        .replaceFirst('MigrationName', snakeToPascal(migrationName))
        .replaceFirst('TableName', tableName)
        .replaceFirst('DropTableName', tableName);

    newFile.writeAsString(str);

    File migrate = File(
      '${Directory.current.path}/lib/database/migrations/migrate.dart',
    );

    if (!migrate.existsSync()) {
      migrate.createSync(recursive: true);
    } else {
      migrateFileContents = migrate.readAsStringSync();
    }

    final importRegExp = RegExp(r'import .+;');
    final migrationRegisterRegex = RegExp(
      r'migrationRegister\s*\(\s*\[\s*([\s\S]*?)\s*\]\s*\)',
      multiLine: true,
    );

    // Find import statement and append new import
    var importMatch = importRegExp.allMatches(migrateFileContents);
    if (importMatch.isNotEmpty) {
      migrateFileContents = migrateFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0)}\nimport '${pascalToSnake(migrationName)}.dart';",
      );
    }

    // Find migrationRegister array and replace with modified version
    Match? migrationRegisterMatch = migrationRegisterRegex.firstMatch(
      migrateFileContents,
    );

    if (migrationRegisterMatch != null) {
      String existingMigrations = migrationRegisterMatch.group(1)?.trim() ?? '';
      String newMigrations;
      
      if (existingMigrations.isEmpty) {
        newMigrations = '${migrationName.pascalCase}()';
      } else {
        // Remove trailing comma if exists
        existingMigrations = existingMigrations.replaceAll(RegExp(r',\s*$'), '');
        newMigrations = '$existingMigrations,\n      ${migrationName.pascalCase}()';
      }
      
      migrateFileContents = migrateFileContents.replaceAll(
        migrationRegisterRegex,
        'migrationRegister([\n      $newMigrations,\n    ])',
      );
    }

    // Write modified content back to file
    migrate.writeAsStringSync(migrateFileContents);

    stdout.writeln(
      ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.',
    );
  }
}