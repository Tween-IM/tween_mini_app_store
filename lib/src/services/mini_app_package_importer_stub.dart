import '../models/mini_app.dart';

class ImportedMiniAppPackage {
  const ImportedMiniAppPackage({
    required this.name, required this.description, required this.category,
    required this.developer, required this.indexPath,
  });
  final String name;
  final String description;
  final String category;
  final String developer;
  final String indexPath;
}

class MiniAppPackageImporter {
  Future<ImportedMiniAppPackage?> pickAndImport() async {
    throw UnsupportedError(
      'ZIP upload in the Flutter Web demo needs a backend package host. '
      'Use the Android/iOS app for local package installation.',
    );
  }
}
