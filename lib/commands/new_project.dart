import 'dart:convert';
import 'dart:io';
import 'package:vania_cli/utils/functions.dart';
import 'command.dart';

class NewProject implements Command {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Vania project';

  @override
  void execute(List<String> arguments) async {
    if (arguments.isEmpty) {
      stdout.writeln('  What is the name of your project?:');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    String projectName = pascalToSnake(arguments[0]);

    final projectFolder = Directory('${Directory.current.path}/$projectName');

    if (projectFolder.existsSync()) {
      stdout.writeln(
          '\x1B[41m\x1B[37m ERROR \x1B[0m "$projectName" already exist');
      exit(0);
    }

    stdout.writeln(' Creating a "Vania/Dart" project at "./$projectName"');

    Process.runSync('git',
        ['clone', 'https://github.com/vania-dart/sample.git', projectName]);

    Directory gitDirectory = Directory('${projectFolder.path}/.git');
    if (gitDirectory.existsSync()) {
      gitDirectory.deleteSync(recursive: true);
    }

    final files = projectFolder.listSync(recursive: true);
    for (final file in files) {
      if (file is File) {
        if (!file.path.contains('bin/vania')) {
          final content =
              file.readAsStringSync().replaceAll('vania_sample', projectName);
          file.writeAsStringSync(content);
        }
      }
    }

    File configFile = File('${projectFolder.path}/.env');

    if (configFile.existsSync()) {
      configFile.writeAsStringSync(configFile
          .readAsStringSync()
          .replaceAll('applicationName', projectName));
      configFile.writeAsStringSync(configFile
          .readAsStringSync()
          .replaceAll('applicationKey', generateRandomKey()));
    }

    Directory.current = Directory(projectFolder.path);

    Process process = await Process.start('dart', ['pub', 'add', 'vania']);
    process.stdout.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          stdout.write('\x1B[32m $line \x1B[0m\n');
        }
      }
    }).onDone(() {
      stdout.writeln(
          '\n\n\x1B[42m SUCCESS \x1B[0m All done! Build something amazing');
      stdout.writeln(
          'You can find general documentation for Vania at: https://vdart.dev/docs/intro/\n');

      stdout.writeln('In order to run your application, type:');
      stdout.writeln(r' $ cd ' + projectName);
      stdout.writeln(r' $ Vania serve');
    });
  }
}
