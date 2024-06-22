import 'dart:io';

import '../utils/functions.dart';
import 'command.dart';

String mailStub = '''
import 'package:vania/vania.dart';

class MailableName extends Mailable {
  final String to;
  final String text;
  final String subject;

  const MailableName({required this.to, required this.text, required this.subject});

  @override
  List<Attachment>? attachments() {
    return null;
  }

  @override
  Content content() {
    return Content(
      text: text,
    );
  }

  @override
  Envelope envelope() {
    return Envelope(
      from: Address('From Email Address','From Name'),
      to: [Address(to)],
      subject: subject,
    );
  }
}

''';

class CreateMailCommand implements Command {
  @override
  String get description => 'Create a new email class';

  @override
  String get name => 'make:mail';

  @override
  void execute(List<String> arguments) {
    if (arguments.isEmpty) {
      print('  What should the mailable be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_/\\]*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Mailable must contain only letters a-z, numbers 0-9 and optional _');
      exit(0);
    }

    String mailableName = arguments[0];

    String filePath =
        '${Directory.current.path}/lib/app/mail/${pascalToSnake(mailableName)}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Mail class already exists.');
      exit(0);
    }

    newFile.createSync(recursive: true);

    String str =
        mailStub.replaceAll('MailableName', snakeToPascal(mailableName));

    newFile.writeAsString(str);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Mail class [$filePath] created successfully.');
  }
}
