import 'dart:io';

import 'package:vania_cli/commands/command.dart';
import 'package:vania_cli/common/env.dart';

class TerminateOpenPortCommand extends Command {
  @override
  String get description =>
      'Terminate the open port assigned for the application in the env file';

  @override
  String get name => 'terminate-port';

  @override
  void execute(List<String> arguments) async {
    Env().load();
    if (Platform.isWindows) {
      await _killPortOnWindows(Env.get<int>('APP_PORT', 300));
    } else if (Platform.isLinux || Platform.isMacOS) {
      await _killPortOnUnix(Env.get<int>('APP_PORT', 3000));
    } else {
      throw UnsupportedError('Unsupported platform');
    }
    print('Done');
    exit(0);
  }

  Future<void> _killPortOnWindows(int port) async {
    try {
      final netstatResult = await Process.run('netstat', ['-ano']);
      if (netstatResult.exitCode == 0) {
        final lines = netstatResult.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.contains(':$port')) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 5) {
              final pid = parts[4];
              final taskkillResult =
                  await Process.run('taskkill', ['/PID', pid, '/F']);
              if (taskkillResult.exitCode == 0) {
                print('Killed process $pid on port $port');
              } else {
                print('Failed to kill process $pid: ${taskkillResult.stderr}');
              }
              break;
            }
          }
        }
      } else {
        print('Failed to run netstat: ${netstatResult.stderr}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _killPortOnUnix(int port) async {
    try {
      final lsofResult = await Process.run('lsof', ['-i', ':$port']);
      if (lsofResult.exitCode == 0) {
        final lines = lsofResult.stdout.toString().split('\n');
        for (var line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length > 1 && parts[1] != 'PID') {
            final pid = parts[1];
            final killResult = await Process.run('kill', ['-9', pid]);
            if (killResult.exitCode == 0) {
              print('Killed process $pid on port $port');
            } else {
              print('Failed to kill process $pid: ${killResult.stderr}');
            }
            break;
          }
        }
      } else {
        print('Failed to run lsof: ${lsofResult.stderr}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
