import 'dart:io';

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
    });
  }
}
''';

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

    String filePath =
        '${Directory.current.path}/lib/database/migrations/${pascalToSnake(migrationName)}.dart';
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
    var importMatch = importRegExp.allMatches(migrateFileContents);

    migrateFileContents = migrateFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0).toString()}\nimport '$migrationName.dart';");

    final constructorRegex =
        RegExp(r'registry\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

    Match? repositoriesBlockMatch =
        constructorRegex.firstMatch(migrateFileContents);

    migrateFileContents = migrateFileContents.replaceAll(constructorRegex,
        '''registry() async{\n\t\t${repositoriesBlockMatch?.group(1)}\n\t\t await ${migrationName.pascalCase}().up();\n\t}''');
    migrate.writeAsStringSync(migrateFileContents);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.');
  }
}
