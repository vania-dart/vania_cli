import 'dart:convert';
import 'dart:io';
import 'package:vania_cli/utils/functions.dart';
import 'command.dart';
import 'package:interact_cli/interact_cli.dart'
    show Confirm, Input, Select, Theme, ValidationError;

class NewProject implements Command {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Vania project';

  @override
  void execute(List<String> arguments) async {
    stdout.write('''\x1B[34m							 
 _    __    ___     _   __    ____    ___ 
| |  / /   /   |   / | / /   /  _/   /   |
| | / /   / /| |  /  |/ /    / /    / /| |
| |/ /   / ___ | / /|  /   _/ /    / ___ |
|___/   /_/  |_|/_/ |_/   /___/   /_/  |_|                             
\x1B[0m\t\t\n''');
    stdout.writeln();
    stdout.writeln();
    final theme = Theme.defaultTheme;
    if (arguments.isEmpty) {
      final name =
          Input.withTheme(
            theme: theme,
            prompt: ' What is the name of your project?:',
            validator: (x) {
              if (x.contains(RegExp(r'[^a-z_A-Z\d]'))) {
                throw ValidationError('Contains an invalid character!');
              }
              return true;
            },
          ).interact();
      arguments.add(name);
    }

    final starterKit = ['Basic', 'Feature Based', 'Basic CRUD', 'MVC MongoDB'];

    final selectedKit =
        Select.withTheme(
          theme: theme,
          prompt: 'Which starter kit would you like to use? (default: Basic)',
          options: starterKit,
        ).interact();

    String branch = 'basic';

    switch (selectedKit) {
      case 0:
        branch = 'basic';
        break;
      case 1:
        branch = 'feature_based';
        break;
      case 2:
        branch = 'basic_crud';
        break;
      case 3:
        branch = 'mvc_mongodb';
        break;
    }

    String projectName = pascalToSnake(arguments[0]);

    final projectFolder = Directory('${Directory.current.path}/$projectName');

    if (projectFolder.existsSync()) {
      stdout.writeln(
        '\x1B[41m\x1B[37m ERROR \x1B[0m "$projectName" already exist',
      );
      exit(0);
    }
    final gitInit =
        Confirm(
          prompt: 'Would you like to initialize a Git repository?',
          defaultValue: true,
          waitForNewLine: true,
        ).interact();

    stdout.writeln(' Creating a "Vania/Dart" project at "./$projectName"');

    Process.runSync('git', [
      'clone',
      '--branch',
      branch,
      'https://github.com/vania-dart/sample.git',
      projectName,
    ]);

    Directory gitDirectory = Directory('${projectFolder.path}/.git');
    if (gitDirectory.existsSync()) {
      gitDirectory.deleteSync(recursive: true);
    }

    final files = projectFolder.listSync(recursive: true);
    for (final file in files) {
      if (file is File) {
        if (!file.path.contains('bin/vania')) {
          final content = file.readAsStringSync().replaceAll(
            'vania_template_project',
            projectName,
          );
          file.writeAsStringSync(content);
        }
      }
    }

    Directory.current = Directory(projectFolder.path);

    Process process = await Process.start('dart', ['pub', 'add', 'vania']);
    process.stdout
        .transform(utf8.decoder)
        .listen((data) {
          List lines = data.split("\n");
          for (String line in lines) {
            if (line.isNotEmpty) {
              stdout.write('\x1B[32m $line \x1B[0m\n');
            }
          }
        })
        .onDone(() async {
          if (selectedKit == 3) {
            await Process.start('dart', ['pub', 'add', 'mongo_dart']);
          }

          if (gitInit) {
            Process.runSync('git', ['init']);
          }

          final db = ['None', 'MySQL', 'PostgreSQL', 'SQLite', 'MongoDB'];

          final selectedDB =
              Select.withTheme(
                theme: theme,
                prompt: 'Which database will your application use?',
                options: db,
              ).interact();

          File configFile = File('${projectFolder.path}/.env');
          if (configFile.existsSync()) {
            String content = configFile.readAsStringSync();
            content = content
                .replaceAll('applicationName', projectName)
                .replaceAll('applicationKey', generateRandomKey());

            if ((selectedDB > 0 && selectedDB < 4) && selectedKit != 3) {
              String conn = '';
              switch (selectedDB) {
                case 1:
                  conn = 'mysql';
                  break;
                case 2:
                  conn = 'pgsql';
                  break;
                case 3:
                  conn = 'sqlite';
                  break;
              }

              final host =
                  Input.withTheme(
                    theme: theme,
                    prompt:
                        ' What is the address of your database? (default: localhost):',
                    defaultValue: 'localhost',
                  ).interact();

              final port =
                  Input.withTheme(
                    theme: theme,
                    prompt:
                        ' What is the port of your database? (default: 3306):',
                    defaultValue: '3306',
                  ).interact();

              final dbName =
                  Input.withTheme(
                    theme: theme,
                    prompt: ' What is the name of your database?:',
                  ).interact();

              final username =
                  Input.withTheme(
                    theme: theme,
                    prompt: ' What is your database username?:',
                  ).interact();

              final password =
                  Input.withTheme(
                    theme: theme,
                    prompt: ' What is your database password?:',
                  ).interact();

              final dbBlock = '''
DB_CONNECTION=$conn
DB_HOST=$host
DB_PORT=$port
DB_NAME=$dbName
DB_USERNAME=$username
DB_PASSWORD=$password
DB_SSL_MODE=false
DB_POOL=true
DB_POOL_SIZE=2''';
              const marker = 'SESSION_LIFETIME=86400';
              if (content.contains(marker)) {
                content = content.replaceFirst(
                  marker,
                  '$marker\n\n$dbBlock\n\n',
                );
              }
            }
            configFile.writeAsStringSync(content);
          }

          stdout.writeln(
            '\n\n\x1B[42m SUCCESS \x1B[0m All done! Build something amazing',
          );
          stdout.writeln(
            'You can find general documentation for Vania at: https://vdart.dev/docs/intro/\n',
          );

          stdout.writeln('In order to run your application, type:');
          stdout.writeln(r' $ cd ' + projectName);
          stdout.writeln(r' $ vania serve');
        });
  }
}
