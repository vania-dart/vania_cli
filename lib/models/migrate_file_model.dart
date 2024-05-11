class MigrateFileModel {
  final String name;
  final String path;
  final String fileName;

  MigrateFileModel(
      {required this.name, required this.path, required this.fileName});

  Map<String, dynamic> get toJson {
    return {
      "class_name": name,
      "file_path": path,
      "file_name": fileName,
    };
  }
}
