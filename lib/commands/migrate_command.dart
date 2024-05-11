import 'dart:convert';
import 'dart:io';

import 'package:vania_cli/models/migrate_file_model.dart';
import 'package:vania_cli/utils/functions.dart';

import 'command.dart';

String migrateFileContents = '''
import 'dart:io';

import 'package:vania/vania.dart';

import '../../config/database.dart';

void main() async {
  Env().load();
  await Migrate().registry();
  await MigrationConnection().closeConnection();
  exit(0);
}

class Migrate {
  registry() async {
    await MigrationConnection().setup(databaseConfig);
    await MigrationDatabaseTable().up();
  }
}
''';

class MigrateCommand implements Command {
  @override
  String get name => 'migrate';

  @override
  String get description => 'Run the database migrations';

  @override
  void execute(List<String> arguments) async {
    print('\x1B[32m Migration started \x1B[0m');

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
    final registryConstructorRegex =
        RegExp(r'registry\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

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
        Match? registryRepositoriesBlockMatch =
            registryConstructorRegex.firstMatch(migrateFileContents);

        if (registryRepositoriesBlockMatch != null) {
          migrateFileContents = migrateFileContents.replaceAll(
            registryConstructorRegex,
            '''registry() async {\n\t\t${registryRepositoriesBlockMatch.group(1)}\n\t\t await ${fileModel.name}().up();\n\t}''',
          );
        }

        // Write modified content back to file
        migrate.writeAsStringSync(migrateFileContents);
      }
    }

    Process process = await Process.start('dart', [
      'run',
      migrationFilePath,
    ]);

    await for (var data in process.stdout.transform(utf8.decoder)) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    }

    ///Delete the migration file after database up
    migrate.delete();
  }
}
