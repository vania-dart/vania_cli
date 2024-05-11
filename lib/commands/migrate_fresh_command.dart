import 'dart:io';

import 'package:vania_cli/models/migrate_file_model.dart';
import 'package:vania_cli/utils/functions.dart';

import 'command.dart';
import 'command_runner.dart';

String migrateFileContents = '''
import 'dart:io';

import 'package:vania/vania.dart';

import '../../config/database.dart';

void main() async {
  Env().load();
  await Migrate().dropTables();
  await MigrationConnection().closeConnection();
  exit(0);
}

class Migrate {
  dropTables() async {
    await MigrationConnection().setup(databaseConfig);
    await MigrationDatabaseTable().down();
  }
}
''';

class MigrateFreshCommand implements Command {
  @override
  String get name => "migrate:fresh";

  @override
  String get description => "Drop all tables and re-run all migrations";

  @override
  void execute(List<String> arguments) async {
    print('\x1B[32m Dropping tables ........... \x1B[0m');

    final files = Directory("${Directory.current.path}/lib/database/migrations")
        .listSync();

    List<MigrateFileModel> migrationFiles = getMigrationFileList(files);

    String migrationFilePath =
        "${Directory.current.path}/lib/database/migrations/.migrate.dart";
    File migrate = File(migrationFilePath);

    if (!migrate.existsSync()) {
      migrate.createSync(recursive: true);
    } else {
      migrateFileContents = migrate.readAsStringSync();
    }

    final importRegExp = RegExp(r'import .+;');
    final dropTableConstructorRegex =
        RegExp(r'dropTables\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

    if (migrationFiles.isNotEmpty) {
      for (final fileModel in migrationFiles) {
        // Find import statement and append new import
        var importMatch = importRegExp.allMatches(migrateFileContents);
        if (importMatch.isNotEmpty) {
          migrateFileContents = migrateFileContents.replaceFirst(
            importMatch.last.group(0).toString(),
            "${importMatch.last.group(0)}\nimport '${fileModel.fileName}';",
          );
        }

        // Find registry and dropTables constructors, and replace with modified versions
        Match? dropTableRepositoriesBlockMatch =
            dropTableConstructorRegex.firstMatch(migrateFileContents);

        if (dropTableRepositoriesBlockMatch != null) {
          migrateFileContents = migrateFileContents.replaceAll(
            dropTableConstructorRegex,
            '''dropTables() async {\n\t\t${dropTableRepositoriesBlockMatch.group(1)}\n\t\t await ${fileModel.name}().down();\n\t }''',
          );
        }

        // Write modified content back to file
        migrate.writeAsStringSync(migrateFileContents);
      }
    }

    await Process.start(
      'dart',
      [
        'run',
        migrationFilePath,
      ],
    );

    ///Delete the migration file after database down
    migrate.delete();

    ///Re-run the migrate command
    CommandRunner().run(["migrate"]);
  }
}
