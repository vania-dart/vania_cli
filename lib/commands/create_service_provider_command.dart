import 'dart:io';
import 'package:vania_cli/common/recase.dart';
import 'command.dart';

String serviceProviderStub = '''
import 'package:vania/vania.dart';

class ServiceProviderName extends ServiceProvider{

  @override
  Future<void> boot() async {}

  @override
  Future<void> register() async {}
}
''';

class CreateServiceProviderCommand implements Command {
  @override
  String get name => 'make:provider';

  @override
  String get description => 'Create a new Service Provider class';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      print('  What should the Service Provider be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_/\\]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Service Provider must contain only letters a-z, numbers 0-9 and optional _');
      exit(0);
    }

    String providerName = arguments[0];

    String filePath =
        '${Directory.current.path}/lib/app/providers/${providerName.snakeCase}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Service Provider already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);

    String str = serviceProviderStub.replaceAll(
        'ServiceProviderName', providerName.pascalCase);

    newFile.writeAsString(str);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Service Provider [$filePath] created successfully.');
  }
}
