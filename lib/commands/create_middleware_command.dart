import 'dart:io';
import 'package:vania_cli/common/recase.dart';
import 'command.dart';

String middlewareStub = '''
import 'package:vania/http/middleware.dart';
import 'package:vania/http/request.dart';

class MiddlewareName extends Middleware {
  @override
  handle(Request req) async {}
}
''';

class CreateMiddlewareCommand implements Command {
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

    RegExp alphaRegex = RegExp(r'^[A-Za-z][A-Za-z_]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
        ' \x1B[41m\x1B[37m ERROR \x1B[0m Middleware must contain only letters a-z and optional _',
      );
      exit(0);
    }

    String middlewareName = arguments[0];

    String filePath =
        '${Directory.current.path}/lib/app/http/middleware/${middlewareName.snakeCase}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Middleware already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);

    String str = middlewareStub.replaceFirst(
      'MiddlewareName',
      middlewareName.pascalCase,
    );

    newFile.writeAsString(str);

    print(
      ' \x1B[44m\x1B[37m INFO \x1B[0m Middleware [$filePath] created successfully.',
    );
  }
}
