import 'dart:io';

import 'package:vania_cli/common/recase.dart';

import 'command.dart';

String seederStubs = '''
import 'package:vania/vania.dart';

class seederName extends Seeder {
  @override
  Future<void> run() async {
    // TODO: implement run
    print("seederName call");
  }
}

''';

String seedersFileContents = '''
import 'dart:io';
import 'package:vania/vania.dart';

void main() async {
  await DatabaseSeeder().registry();
  exit(0);
}

class DatabaseSeeder {
  registry() async {
	}
}
''';

class CreateDatabaseSeederCommand implements Command {
  @override
  String get name => "db:seed";

  @override
  String get description => "Create a seeder class";

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      print('  What should the seeder be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_/\\]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Seeder must contain only letters a-z, numbers 0-9 and optional _');
      exit(0);
    }

    List fileName = arguments[0].split(RegExp(r'[/]'));

    String seederName = fileName[fileName.length - 1];

    String secondPath = "";

    if (fileName.length > 1) {
      fileName.remove(fileName[fileName.length - 1]);
      secondPath = fileName.join("/");
      secondPath = secondPath.endsWith("/") ? secondPath : "$secondPath/";
    }

    String controllerPath =
        '${Directory.current.path}/lib/database/seeders/$secondPath${seederName.snakeCase}.dart';
    File newFile = File(controllerPath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Seeder already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);

    String str = seederStubs.replaceAll('seederName', seederName.pascalCase);

    newFile.writeAsString(str);

    ///Register new seeder file into main database seeder file
    File databaseSeederFile = File(
        '${Directory.current.path}/lib/database/seeders/database_seeder.dart');

    if (!databaseSeederFile.existsSync()) {
      databaseSeederFile.createSync(recursive: true);
    } else {
      seedersFileContents = databaseSeederFile.readAsStringSync();
    }

    final importRegExp = RegExp(r'import .+;');
    var importMatch = importRegExp.allMatches(seedersFileContents);

    seedersFileContents = seedersFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0).toString()}\nimport '${seederName.snakeCase}.dart';");

    final constructorRegex =
        RegExp(r'registry\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

    Match? repositoriesBlockMatch =
        constructorRegex.firstMatch(seedersFileContents);

    seedersFileContents = seedersFileContents.replaceAll(constructorRegex,
        '''registry() async{\n\t\t${repositoriesBlockMatch?.group(1)}\n\t\t await ${seederName.pascalCase}().run();\n\t}''');
    databaseSeederFile.writeAsStringSync(seedersFileContents);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Seeder [$controllerPath] created successfully.');
  }
}
