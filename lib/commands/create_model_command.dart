import 'dart:io';

import 'package:vania_cli/commands/command.dart';
import 'package:vania_cli/utils/functions.dart';

String modelStub = '''
import 'package:vania/vania.dart';

class ModelName extends Model{
    
  ModelName(){
    super.table('TableName');
  }

}
''';

class CreateModelCommand extends Command {
  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new Eloquent model class';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      print('  What should the model be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    if (arguments.length < 2) {
      print('  What should the table be named?');
      stdout.write('\x1B[1m > c');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z]+(?:[_][a-zA-Z]+)*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Model must contain only letters a-z and optional _');
      return;
    }

    String modelName = arguments[0];

    String filePath =
        '${Directory.current.path}/lib/app/models/${pascalToSnake(modelName)}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Model already exists.');
      return;
    }

    newFile.createSync(recursive: true);

    String tableName = arguments[1];

    String str = modelStub
        .replaceAll('ModelName', snakeToPascal(modelName))
        .replaceFirst('TableName', tableName.toLowerCase());

    newFile.writeAsString(str);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Model [$filePath] created successfully.');
  }
}
