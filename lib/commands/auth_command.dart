import 'dart:io';
import 'package:vania_cli/commands/command.dart';

String authMigrationContent = '''
import 'package:vania/migration.dart';

class CreatePersonalAccessTokensTable extends Migration {
  @override
  Future<void> up() async {
    await create('personal_access_tokens', (Schema table) {
      table.id();
      table.tinyText('name');
      table.bigInt('tokenable_id');
      table.string('token').unique();
      table.timeStamp('last_used_at').nullable();
      table.timeStamps();
      table.timeStamp('deleted_at').nullable();
    });
  }

  @override
  Future<void> down() async {
    await drop('personal_access_tokens');
  }
}
''';

class AuthCommand extends Command {
  @override
  String get name => 'make:auth';

  @override
  String get description => 'Create personal access tokens migration';

  @override
  void execute(List<String> arguments) async {
    String filePath =
        '${Directory.current.path}/lib/database/migrations/create_personal_access_tokens_table.dart';

    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(
        ' \x1B[41m\x1B[37m ERROR \x1B[0m Personal access tokens migration already exists.',
      );
      exit(0);
    }

    newFile.createSync(recursive: true);
    newFile.writeAsString(authMigrationContent);

    File migrate = File(
      '${Directory.current.path}/lib/database/migrations/migrate.dart',
    );

    String migrateFileContents = migrate.readAsStringSync();

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
        "${importMatch.last.group(0)}\nimport 'create_personal_access_tokens_table.dart';",
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
        newMigrations = 'CreatePersonalAccessTokensTable()';
      } else {
        // Remove trailing comma if exists
        existingMigrations = existingMigrations.replaceAll(
          RegExp(r',\s*$'),
          '',
        );
        newMigrations =
            '$existingMigrations,\n      CreatePersonalAccessTokensTable()';
      }

      migrateFileContents = migrateFileContents.replaceAll(
        migrationRegisterRegex,
        'migrationRegister([\n      $newMigrations,\n    ])',
      );
    }

    migrate.writeAsStringSync(migrateFileContents);

    print(' \x1B[44m\x1B[37m INFO \x1B[0m Auth created successfully.');
  }
}
