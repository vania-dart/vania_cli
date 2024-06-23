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
      stdout.write('  What is the name of your project?:\n\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    final projectName = pascalToSnake(arguments[0]);
    final projectFolderPath = '${Directory.current.path}/$projectName';
    final projectFolder = Directory(projectFolderPath);

    if (projectFolder.existsSync()) {
      stdout.writeln('\x1B[41m\x1B[37m ERROR \x1B[0m "$projectName" already exists');
      exit(0);
    }

    stdout.writeln('Creating a "Vania/Dart" project at "./$projectName"');

    await cloneRepository(projectName);
    await removeGitDirectory(projectFolder);
    await replaceProjectNameInFiles(projectFolder, projectName);
    await updateConfigFile(projectFolder, projectName);
    await installDependencies(projectName);

    stdout.writeln('\n\n\x1B[42m SUCCESS \x1B[0m All done! Build something amazing');
    stdout.writeln('You can find general documentation for Vania at: https://vdart.dev/docs/intro/\n');
    stdout.writeln('In order to run your application, type:');
    stdout.writeln(' $ cd $projectName');
    stdout.writeln(' $ Vania serve');
  }

  Future<void> cloneRepository(String projectName) async {
    final result = await Process.run('git', ['clone', 'https://github.com/vania-dart/sample.git', projectName]);
    if (result.exitCode != 0) {
      stdout.writeln('Failed to clone repository: ${result.stderr}');
      exit(result.exitCode);
    }
  }

  Future<void> removeGitDirectory(Directory projectFolder) async {
    final gitDirectory = Directory('${projectFolder.path}/.git');
    if (gitDirectory.existsSync()) {
      await gitDirectory.delete(recursive: true);
    }
  }

  Future<void> replaceProjectNameInFiles(Directory projectFolder, String projectName) async {
    final files = projectFolder.listSync(recursive: true);
    for (final file in files) {
      if (file is File && !file.path.contains('bin/vania')) {
        final content = file.readAsStringSync().replaceAll('vania_sample', projectName);
        await file.writeAsString(content);
      }
    }
  }

  Future<void> updateConfigFile(Directory projectFolder, String projectName) async {
    final configFile = File('${projectFolder.path}/.env');
    if (configFile.existsSync()) {
      var content = configFile.readAsStringSync()
        .replaceAll('applicationName', projectName)
        .replaceAll('applicationKey', generateRandomKey());
      await configFile.writeAsString(content);
    }
  }

  Future<void> installDependencies(String projectName) async {
    Directory.current = Directory('${Directory.current.path}/$projectName');
    final process = await Process.start('dart', ['pub', 'add', 'vania']);
    await process.stdout.transform(utf8.decoder).forEach((data) {
      final lines = data.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          stdout.write('\x1B[32m $line \x1B[0m\n');
        }
      }
    });
  }
}
