import 'dart:async';
import 'dart:io';

import 'package:vania_cli/utils/functions.dart';
import 'command.dart';

class ServeDownCommand implements Command {
  @override
  String get description => 'To down the running application.';

  @override
  String get name => 'down';

  @override
  void execute(List<String> arguments) {
    Timer? timer;
    getDartToolVaniaConfig().then((dartToolVania) {
      if (dartToolVania == null) {
        return;
      }
      dynamic pid = dartToolVania['process']?['pid'];
      if (pid is String) {
        pid = int.tryParse(pid);
      }

      if (pid != null) {
        print('Stopping the server...');

        timer = Timer(Duration(milliseconds: 500), () async {
          if (timer != null) {
            timer?.cancel();
          }
          Process.killPid(pid, ProcessSignal.sigterm);
          dartToolVania.remove('process');
          await updateDartToolVaniaConfig(dartToolVania);

          print('Server down');
          exit(0);
        });
      }
    });
  }
}
