import 'dart:convert';
import 'dart:math';

String snakeToPascal(String name) {
  return name
      .split("_")
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .toList()
      .join('');
}

String pascalToSnake(String input) {
  if (input.isEmpty) return '';
  StringBuffer result = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    if (i != 0 && input[i] != '_' && input[i].toUpperCase() == input[i]) {
      result.write('_');
    }
    result.write(input[i].toLowerCase());
  }
  return result.toString();
}

String generateRandomKey() {
  final random = Random.secure();
  final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(keyBytes);
}

String firstLetterLowerCase(String str) {
  return '${str[0].toLowerCase()}${str.substring(1)}';
}
