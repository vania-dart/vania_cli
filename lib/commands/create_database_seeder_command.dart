import 'dart:io';

import 'package:vania_cli/common/recase.dart';

import 'command.dart';

String seederStubs = '''
import 'package:vania/database.dart';

class seederName extends Seeder {
  @override
  Future<void> run() async {
    try {
      // TODO: implement run
      print("seederName call");
    } catch (e) {
      print(e.toString());
    }
  }
}
''';

String seederWithFactoryStubs = '''
import 'package:vania/database.dart';

import '../factory/factoryFileName.dart';

class seederName extends Seeder {
  @override
  Future<void> run() async {
    try {
      final data = factoryName().createMany(500);
      // TODO: implement run
      print("seederName call");
    } catch (e) {
      print(e.toString());
    }
  }
}
''';

String factoryStub = '''
import 'package:vania/database.dart' show SeederFactory;

class factoryName extends SeederFactory {
  @override
  Map<String, dynamic> definition() {
    return {};
  }
}
''';

String seedersFileContents = '''
import 'package:vania/database.dart' show SeederRunner;

import '../../config/database.dart';

void main() async {
  await SeederRunner().setup(database: database, seeders: [
    
  ]);
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

    RegExp alphaRegex = RegExp(r'^[A-Za-z][A-Za-z_]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
        ' \x1B[41m\x1B[37m ERROR \x1B[0m Seeder must contain only letters a-z and optional _',
      );
      exit(0);
    }

    // Check for factory flag
    String? factoryName;
    bool hasFactory = false;

    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i] == '--factory' && i + 1 < arguments.length) {
        factoryName = arguments[i + 1];
        hasFactory = true;
        break;
      }
    }

    List fileName = arguments[0].toLowerCase().split(RegExp(r'[/]'));

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

    String str;
    if (hasFactory && factoryName != null) {
      // Create factory file first
      String factoryPath =
          '${Directory.current.path}/lib/database/factory/${factoryName.snakeCase}.dart';
      File factoryFile = File(factoryPath);

      if (!factoryFile.existsSync()) {
        factoryFile.createSync(recursive: true);
        String factoryContent = factoryStub.replaceAll(
          'factoryName',
          factoryName.pascalCase,
        );
        factoryFile.writeAsString(factoryContent);
        print(
          ' \x1B[44m\x1B[37m INFO \x1B[0m Factory [$factoryPath] created successfully.',
        );
      }

      // Create seeder with factory
      str = seederWithFactoryStubs
          .replaceAll('seederName', seederName.pascalCase)
          .replaceAll('factoryName', factoryName.pascalCase)
          .replaceAll('factoryFileName', factoryName.snakeCase);
    } else {
      str = seederStubs.replaceAll('seederName', seederName.pascalCase);
    }

    newFile.writeAsString(str);

    ///Register new seeder file into main database seeder file
    File databaseSeederFile = File(
      '${Directory.current.path}/lib/database/seeders/database_seeder.dart',
    );

    if (!databaseSeederFile.existsSync()) {
      databaseSeederFile.createSync(recursive: true);
    } else {
      seedersFileContents = databaseSeederFile.readAsStringSync();
    }

    final importRegExp = RegExp(r'import .+;');
    final seederRegisterRegex = RegExp(
      r'seeders:\s*\[\s*([\s\S]*?)\s*\]',
      multiLine: true,
    );

    // Find import statement and append new import
    var importMatch = importRegExp.allMatches(seedersFileContents);
    if (importMatch.isNotEmpty) {
      seedersFileContents = seedersFileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0)}\nimport '${seederName.snakeCase}.dart';",
      );
    }

    // Find seeders array and replace with modified version
    Match? seederRegisterMatch = seederRegisterRegex.firstMatch(
      seedersFileContents,
    );

    if (seederRegisterMatch != null) {
      String existingSeeders = seederRegisterMatch.group(1)?.trim() ?? '';
      String newSeeders;

      if (existingSeeders.isEmpty) {
        newSeeders = '${seederName.pascalCase}()';
      } else {
        // Remove trailing comma if exists
        existingSeeders = existingSeeders.replaceAll(RegExp(r',\s*$'), '');
        newSeeders = '$existingSeeders,\n    ${seederName.pascalCase}()';
      }

      seedersFileContents = seedersFileContents.replaceAll(
        seederRegisterRegex,
        'seeders: [\n    $newSeeders,\n  ]',
      );
    }

    databaseSeederFile.writeAsStringSync(seedersFileContents);

    print(
      ' \x1B[44m\x1B[37m INFO \x1B[0m Seeder [$controllerPath] created successfully.',
    );
  }
}
