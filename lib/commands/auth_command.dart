import 'dart:io';
import 'package:vania_cli/commands/command.dart';

String authMigrationContent = '''
import 'package:vania/vania.dart';

class CreatePersonalAccessTokensTable extends Migration {
  @override
  Future<void> up() async {
    super.up();
    await createTableNotExists('personal_access_tokens', () {
      id();
      tinyText('name');
      bigInt('tokenable_id');
      string('token');
      timeStamp('last_used_at', nullable: true);
      timeStamp('created_at', nullable: true);
      timeStamp('deleted_at', nullable: true);

      index(ColumnIndex.unique, 'token', ['token']);
    });
  }

   @override
  Future<void> down() async {
    super.down();
    await dropIfExists('personal_access_tokens');
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
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Personal access tokens migration already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);
    newFile.writeAsString(authMigrationContent);

    File migrate =
        File('${Directory.current.path}/lib/database/migrations/migrate.dart');

    String migrateFileContents = migrate.readAsStringSync();

    final importRegExp = RegExp(r'import .+;');
    var importMatch = importRegExp.allMatches(migrateFileContents);

    migrateFileContents = migrateFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0).toString()}\nimport '${filePath}create_personal_access_tokens_table.dart';");

    final constructorRegex =
        RegExp(r'registry\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

    Match? repositoriesBlockMatch =
        constructorRegex.firstMatch(migrateFileContents);

    migrateFileContents = migrateFileContents.replaceAll(constructorRegex,
        '''registry() async{\n\t\t await CreatePersonalAccessTokensTable().up();\n\t\t${repositoriesBlockMatch?.group(1)}\n\t}''');
    migrate.writeAsStringSync(migrateFileContents);

    print(' \x1B[44m\x1B[37m INFO \x1B[0m Auth created successfully.');
  }
}
