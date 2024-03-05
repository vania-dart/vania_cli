import 'dart:io';

import 'package:vania_cli/commands/build_command.dart';
import 'package:vania_cli/commands/command.dart';
import 'package:vania_cli/commands/create_controller_command.dart';
import 'package:vania_cli/commands/create_middleware_command.dart';
import 'package:vania_cli/commands/create_migration_command.dart';
import 'package:vania_cli/commands/create_model_command.dart';
import 'package:vania_cli/commands/create_service_provider_command.dart';
import 'package:vania_cli/commands/migrate_command.dart';
import 'package:vania_cli/commands/new_project.dart';
import 'package:vania_cli/commands/serve_command.dart';
import 'package:vania_cli/commands/update_command.dart';
import 'package:vania_cli/service/service.dart';

class CommandRunner {
  final Map<String, Command> _commands = {
    'serve': ServeCommand(),
    'create': NewProject(),
    'build': BuildCommand(),
    'update': UpdateCommand(),
    'make:controller': CreateControllerCommand(),
    'make:middleware': CreateMiddlewareCommand(),
    'make:migration': CreateMigrationCommand(),
    'make:model': CreateModelCommand(),
    'make:provider': CreateSrviceProviderCommand(),
    'migrate': MigrateCommand(),
  };

  void run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print(
          '\x1B[32m -V, --version  \x1B[0m\t\t Display this application version');
      _commands.forEach((name, command) {
        print('\x1B[32m$name\x1B[0m\t\t${command.description}');
      });
      return;
    }

    final commandName = arguments[0].toString().toLowerCase();

    if (commandName == '-V' ||
        commandName == '--version' ||
        commandName == '--v') {
      String version = await Service().fetchVaniaVersion();
      print(' \x1B[1mVania Dart Framework \x1B[32m $version  \x1B[0m');
      return;
    }

    final command = _commands[commandName];

    if (command == null) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Command "$commandName" is not defined.');
      return;
    }

    if (!Directory('${Directory.current.path}/lib').existsSync() &&
        !(commandName == 'create' || commandName == 'update')) {
      print(
          '\x1B[41m\x1B[37m ERROR \x1B[0m Please run this command from the root directory of the Vania project');
      exit(0);
    }

    final commandArguments = arguments.sublist(1);

    command.execute(commandArguments);
  }
}
