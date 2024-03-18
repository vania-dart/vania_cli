import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:vania_cli/utils/functions.dart';
import 'package:watcher/watcher.dart';
import 'package:vania_cli/commands/command.dart';

class ServeCommand extends Command {
  @override
  String get name => 'serve';

  @override
  String get description =>
      'Serve the application. To enable VM service, add the `--vm` flag.';

  @override
  void execute(List<String> arguments) async {
    DirectoryWatcher watcher = DirectoryWatcher(Directory.current.path);
    Timer? timer;
    String? vmService;
    if (arguments.isNotEmpty && arguments[0].toLowerCase() == '--vm') {
      vmService = '--enable-vm-service';
    }

    Process? process = await _serve(vmService);

    /// save process info on `.dartTool` folder for upcoming serve features
    /// like down, up, etc
    _updateDartToolVaniaConfig(process);

    watcher.events.listen((event) async {
      if (path.extension(event.path) == '.dart') {
        print("\x1B[32m File changed: ${path.basename(event.path)} \x1B[0m");
        print("Restarting the server....");
        if (timer != null) {
          timer?.cancel();
        }

        timer = Timer(Duration(milliseconds: 500), () async {
          process?.kill();
          int? exitCode = await process?.exitCode;
          if (exitCode.toString().isNotEmpty) {
            process = await _serve(vmService);
          }
        });
      }
    });

    ProcessSignal.sigint.watch().listen((signal) {
      print('Stopping the server...');
      Timer(Duration(milliseconds: 600), () {
        if (timer != null) {
          timer?.cancel();
        }
        process?.kill();
        print('Server down');
        exit(0);
      });
    });
  }

  Future<Process> _serve(String? vm) async {
    Process process;
    if (vm == null) {
      process = await Process.start('dart', ['bin/server.dart']);
    } else {
      process = await Process.start('dart', [vm, 'bin/server.dart']);
    }

    process.stdout.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          print(line);
        }
      }
    });

    return process;
  }

  void _updateDartToolVaniaConfig(Process? process) =>
      getDartToolVaniaConfig().then((dartToolVania) {
        if (dartToolVania == null) {
          return;
        }
        dartToolVania['process'] = {'pid': process?.pid};

        updateDartToolVaniaConfig(dartToolVania);
      });
}
