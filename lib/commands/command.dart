abstract class Command {
  String get name;
  String get description;

  void execute(List<String> arguments);
}
