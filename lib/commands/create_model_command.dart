import 'dart:io';
import 'package:vania_cli/common/recase.dart';
import 'command.dart';

String modelStub = '''

import 'package:vania/orm/model.dart';

class ModelName extends Model {}

''';

class CreateModelCommand implements Command {
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


    RegExp alphaRegex = RegExp(r'^[A-Za-z][A-Za-z_]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
        ' \x1B[41m\x1B[37m ERROR \x1B[0m Model must contain only letters a-z  and optional _',
      );
      exit(0);
    }

    String modelName = arguments[0];

    String filePath =
        '${Directory.current.path}/lib/app/models/${modelName.snakeCase}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Model already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);


    String str = modelStub
        .replaceAll('ModelName', modelName.pascalCase);

    newFile.writeAsString(str);

    print(
      ' \x1B[44m\x1B[37m INFO \x1B[0m Model [$filePath] created successfully.',
    );
  }
}
