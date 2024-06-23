import 'dart:io';

import '../service/service.dart';
import 'auth_command.dart';
import 'build_command.dart';
import 'command.dart';
import 'create_alter_table_migration_command.dart';
import 'create_controller_command.dart';
import 'create_database_seeder_command.dart';
import 'create_mail_command.dart';
import 'create_middleware_command.dart';
import 'create_migration_command.dart';
import 'create_model_command.dart';
import 'create_service_provider_command.dart';
import 'terminate_port_command.dart';
import 'migrate_command.dart';
import 'migrate_databse_seeder_command.dart';
import 'migrate_fresh_command.dart';
import 'new_project.dart';
import 'serve_command.dart';
import 'serve_down_command.dart';
import 'update_command.dart';

class CommandRunner {
  final Map<String, Command> _commands = {
    'serve': ServeCommand(),
    'create': NewProject(),
    'down': ServeDownCommand(),
    'build': BuildCommand(),
    'update': UpdateCommand(),
    'make:auth': AuthCommand(),
    'make:controller': CreateControllerCommand(),
    'make:middleware': CreateMiddlewareCommand(),
    'make:migration': CreateMigrationCommand(),
    'make:migration-alter': CreateAlterTableMigrationCommand(),
    'make:model': CreateModelCommand(),
    'make:mail': CreateMailCommand(),
    'make:provider': CreateServiceProviderCommand(),
    'migrate': MigrateCommand(),
    'db:seed': CreateDatabaseSeederCommand(),
    'migrate:seed': MigrateDatabaseSeederCommand(),
    'migrate:fresh': MigrateFreshCommand(),
    'terminate-port': TerminateOpenPortCommand(),
  };

  void run(List<String> arguments) async {
    if (arguments.isEmpty) {
      print(
          '\x1B[32m -V, --version  \x1B[0m\tDisplay this application version');

      int longestCommandLength =
          _commands.keys.reduce((a, b) => a.length > b.length ? a : b).length;

      _commands.forEach((name, command) {
        final paddedName = name.padRight(longestCommandLength);
        print('\x1B[32m$paddedName\x1B[0m\t\t${command.description}');
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
