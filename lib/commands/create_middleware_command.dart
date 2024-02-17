import 'dart:io';

import 'package:vania_cli/commands/command.dart';
import 'package:vania_cli/utils/functions.dart';

String middlewareStub = '''
import 'package:vania/vania.dart';

class MiddlewareName extends Middleware {
  @override
  handle(Request req) async {
    next?.handle(req);
  }
}
''';

class CreateMiddlewareCommand extends Command {
  @override
  String get name => 'make:middleware';

  @override
  String get description => 'Create a new middleware class';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      print('  What should the middleware be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z]+(?:[_][a-zA-Z]+)*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Middleware must contain only letters a-z and optional _');
      return;
    }

    String middlewareName = arguments[0];

    String filePath =
        '${Directory.current.path}\\lib\\app\\http\\middleware\\${pascalToSnake(middlewareName)}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Middleware already exists.');
      return;
    }

    newFile.createSync(recursive: true);

    String str = middlewareStub
        .replaceFirst('MiddlewareName', snakeToPascal(middlewareName));

    newFile.writeAsString(str);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Middleware [$filePath] created successfully.');
  }
}
