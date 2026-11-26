import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/mini_app.dart';

class ImportedMiniAppPackage {
  const ImportedMiniAppPackage({
    required this.name,
    required this.description,
    required this.category,
    required this.developer,
    required this.indexPath,
  });
  final String name;
  final String description;
  final String category;
  final String developer;
  final String indexPath;
}

/// Imports a ZIP mini-app package locally. This demo importer supports Android,
/// iOS, Windows, macOS and Linux. Flutter Web needs server-side package hosting.
class MiniAppPackageImporter {
  static const maxZipBytes = 25 * 1024 * 1024;
  static const maxExpandedBytes = 60 * 1024 * 1024;
  static const maxFiles = 1500;

  Future<ImportedMiniAppPackage?> pickAndImport() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'ZIP package installation in the web demo needs backend hosting. '
        'Use the Android app to test local package upload.',
      );
    }

    // Android document providers often label ZIP archives inconsistently.
    // FileType.custom + allowedExtensions may reject valid archives before
    // selection, so allow any file and validate it below.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    if (!picked.name.trim().toLowerCase().endsWith('.zip')) {
      throw FormatException(
        'Please choose a ZIP mini app package (.zip). Selected: ${picked.name}',
      );
    }
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw FormatException(
        'Android could not read this file. Move the ZIP to Downloads and select it again.',
      );
    }
    // Check ZIP's local-file, end-of-central-directory, or spanning signature.
    if (bytes.length < 4 ||
        bytes[0] != 0x50 ||
        bytes[1] != 0x4b ||
        !((bytes[2] == 0x03 && bytes[3] == 0x04) ||
          (bytes[2] == 0x05 && bytes[3] == 0x06) ||
          (bytes[2] == 0x07 && bytes[3] == 0x08))) {
      throw FormatException(
        'The selected file does not look like a valid ZIP. Download the package again.',
      );
    }
    if (bytes.length > maxZipBytes) {
      throw FormatException('ZIP is too large. Maximum upload size is 25 MB.');
    }

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.files.length > maxFiles) {
      throw FormatException('Package contains too many files.');
    }

    var expandedBytes = 0;
    final safeFiles = <ArchiveFile>[];
    for (final entry in archive.files) {
      if (entry.isDirectory) continue;
      final name = entry.name.replaceAll('\\', '/');
      final segments = name.split('/');
      if (name.startsWith('/') ||
          name.contains(':') ||
          segments.any((part) => part == '..' || part.isEmpty)) {
        throw FormatException('ZIP contains an unsafe file path.');
      }
      expandedBytes += entry.size;
      if (expandedBytes > maxExpandedBytes) {
        throw FormatException('Unpacked package exceeds 60 MB.');
      }
      safeFiles.add(entry);
    }

    final indexEntry = safeFiles.where((f) =>
      f.name.replaceAll('\\', '/').split('/').last.toLowerCase() == 'index.html'
    ).toList();
    if (indexEntry.isEmpty) {
      throw FormatException('Package must contain an index.html file.');
    }
    // Use root index.html when present; otherwise use the first nested entry.
    final chosen = indexEntry.firstWhere(
      (f) => f.name.replaceAll('\\', '/') == 'index.html',
      orElse: () => indexEntry.first,
    );
    final prefix = chosen.name.replaceAll('\\', '/').substring(
      0, chosen.name.replaceAll('\\', '/').lastIndexOf('/') + 1,
    );

    final docs = await getApplicationDocumentsDirectory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final target = Directory('${docs.path}/tween_packages/$id');
    await target.create(recursive: true);

    try {
      for (final entry in safeFiles) {
        var relative = entry.name.replaceAll('\\', '/');
        if (prefix.isNotEmpty && relative.startsWith(prefix)) {
          relative = relative.substring(prefix.length);
        }
        if (relative.isEmpty || relative.split('/').any((part) => part == '..')) {
          continue;
        }
        final output = File('${target.path}/$relative');
        await output.parent.create(recursive: true);
        final content = entry.content;
        if (content is List<int>) {
          await output.writeAsBytes(content, flush: true);
        } else {
          await output.writeAsBytes(List<int>.from(content as Iterable), flush: true);
        }
      }

      final indexPath = '${target.path}/index.html';
      if (!await File(indexPath).exists()) {
        // Some packages nest the web root. Move the selected entry to a stable
        // root path and preserve relative assets by using the nested file's
        // directory as the package root in the runtime URL.
        final nestedIndex = File('${target.path}/${chosen.name.substring(prefix.length)}');
        if (!await nestedIndex.exists()) throw FormatException('Unable to extract index.html.');
        return _readMetadata(nestedIndex, target.path);
      }
      return _readMetadata(File(indexPath), target.path);
    } catch (_) {
      if (await target.exists()) await target.delete(recursive: true);
      rethrow;
    }
  }

  Future<ImportedMiniAppPackage> _readMetadata(File index, String rootPath) async {
    final html = await index.readAsString();
    final title = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false,
      dotAll: true).firstMatch(html)?.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    String meta(String key) {
      final pattern = RegExp(
        r'''<meta[^>]+(?:name|property)=["']'''
        + RegExp.escape(key)
        + r'''["'][^>]+content=["']([^"']*)["'][^>]*>''',
        caseSensitive: false,
      );
      return pattern.firstMatch(html)?.group(1)?.trim() ?? '';
    }
    final name = _decode(title ?? '').trim();
    final description = _decode(meta('description'));
    final developer = _decode(meta('author'));
    final category = _decode(meta('application-category'));
    return ImportedMiniAppPackage(
      name: name.isEmpty ? 'Imported Mini App' : name,
      description: description.isEmpty
        ? 'A locally imported HTML mini app package.' : description,
      category: category.isEmpty ? 'Utilities' : category,
      developer: developer.isEmpty ? 'Package developer' : developer,
      indexPath: index.path,
    );
  }

  String _decode(String value) => value
    .replaceAll('&amp;', '&').replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'").replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');
}
