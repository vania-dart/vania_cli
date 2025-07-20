import 'dart:io';

import 'package:interact_cli/interact_cli.dart';
import 'package:vania_cli/common/recase.dart';
import 'package:vania_cli/utils/_pluralize.dart';
import 'package:vania_cli/utils/functions.dart';

import 'command.dart';

String migrationStub = '''
import 'package:vania/migration.dart';

class MigrationALterNameClass extends Migration {
  @override
  Future<void> up() async {
    await alterColumn( 'users', (Schema table){
      
    },afterColumn: 'email');
  }

  
  @override
  Future<void> down() async {}
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

class CreateAlterTableMigrationCommand implements Command {
  @override
  String get name => 'make:migration-alter';

  @override
  String get description =>
      'Create a new alter table migration file. This command allows you to add a new column to an existing table or alter an existing column';

  String _readMigrationName() {
    return Input.withTheme(
      theme: Theme.defaultTheme,
      prompt: 'What should the migration be named?',
      validator: (x) {
        if (!RegExp(r'^[A-Za-z][A-Za-z_]*$').hasMatch(x)) {
          throw ValidationError(
            'Migration must contain only letters a-z and optional _',
          );
        }
        if (x.isEmpty) {
          throw ValidationError('Select a name for your migration file');
        }
        return true;
      },
    ).interact();
  }

  String _readTableName() {
    return Input.withTheme(
      theme: Theme.defaultTheme,
      prompt: 'To which table should this column be added?',
      validator: (x) {
        if (x.isEmpty) {
          throw ValidationError(
            'Specify to which table you want to add the column (fill in the table name)',
          );
        }
        return true;
      },
    ).interact();
  }

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      arguments.add(_readMigrationName());
    }

    String migrationName = arguments[0].toLowerCase();

    if (arguments.length < 2) {
      arguments.add(_readTableName());
    }

    String tableName = Pluralize().make(arguments[1].toLowerCase());

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

    String str = migrationStub
        .replaceFirst('MigrationALterNameClass', snakeToPascal(migrationName))
        .replaceFirst('TableName', tableName);

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

    var importMatch = importRegExp.allMatches(migrateFileContents);
    if (importMatch.isNotEmpty) {
      migrateFileContents = migrateFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0)}\nimport '${pascalToSnake(migrationName)}.dart';",
      );
    }

    Match? migrationRegisterMatch = migrationRegisterRegex.firstMatch(
      migrateFileContents,
    );

    if (migrationRegisterMatch != null) {
      String existingMigrations = migrationRegisterMatch.group(1)?.trim() ?? '';
      String newMigrations;
      
      if (existingMigrations.isEmpty) {
        newMigrations = '${migrationName.pascalCase}()';
      } else {
        existingMigrations = existingMigrations.replaceAll(RegExp(r',\s*$'), '');
        newMigrations = '$existingMigrations,\n      ${migrationName.pascalCase}()';
      }
      
      migrateFileContents = migrateFileContents.replaceAll(
        migrationRegisterRegex,
        'migrationRegister([\n      $newMigrations,\n    ])',
      );
    }

    migrate.writeAsStringSync(migrateFileContents);

    stdout.writeln(
      ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.',
    );
  }
}