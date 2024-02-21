import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import 'package:vania_cli/commands/command.dart';

class ServeCommand extends Command {
  @override
  String get name => 'serve';

  @override
  String get description => 'Serve the application';

  @override
  void execute(List<String> arguments) async {
    DirectoryWatcher watcher = DirectoryWatcher(Directory.current.path);
    Timer? timer;
    Process? process = await _serve();

    watcher.events.listen((event) async {
      if (path.extension(event.path) != '.dart') {
       exit(0);
      }

      print("\x1B[32m File changed: ${path.basename(event.path)} \x1B[0m");
      print("Restarting the server....");
      if (timer != null) {
        timer?.cancel();
      }

      timer = Timer(Duration(milliseconds: 500), () async {
        process?.kill();
        int? exitCode = await process?.exitCode;
        if (exitCode.toString().isNotEmpty) {
          process = await _serve();
        }
      });
    });
    ProcessSignal.sigint.watch().listen((signal) {
      print('Stopping the server...');
      Timer(Duration(seconds: 1), () {
        if (timer != null) {
          timer?.cancel();
        }
        process?.kill();
        print('Server down');
        exit(0);
      });
    });
  }

  Future<Process> _serve() async {
    Process process =
        await Process.start('dart', ['--enable-vm-service', 'bin/server.dart']);
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
}
