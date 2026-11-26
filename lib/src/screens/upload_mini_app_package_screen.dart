import 'package:flutter/material.dart';

import '../models/mini_app.dart';
import '../repository/mini_app_repository.dart';
import '../services/mini_app_package_importer.dart';

class UploadMiniAppPackageScreen extends StatefulWidget {
  const UploadMiniAppPackageScreen({super.key, required this.repository});
  final MiniAppRepository repository;

  @override
  State<UploadMiniAppPackageScreen> createState() => _UploadMiniAppPackageScreenState();
}

class _UploadMiniAppPackageScreenState extends State<UploadMiniAppPackageScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _developer = TextEditingController(text: 'Independent developer');
  final _importer = MiniAppPackageImporter();
  ImportedMiniAppPackage? _package;
  String _category = 'Utilities';
  bool _busy = false;
  String? _fileName;
  String? _error;

  static const _categories = [
    'Education', 'Entertainment', 'Business', 'Shopping', 'Productivity',
    'Design & Creativity', 'Utilities', 'Games', 'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _developer.dispose();
    super.dispose();
  }

  Future<void> _choosePackage() async {
    setState(() { _busy = true; _error = null; });
    try {
      final imported = await _importer.pickAndImport();
      if (imported == null || !mounted) return;
      setState(() {
        _package = imported;
        _name.text = imported.name;
        _description.text = imported.description;
        _developer.text = imported.developer;
        _category = _categories.contains(imported.category) ? imported.category : 'Utilities';
        _fileName = 'ZIP package • index.html found';
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('FormatException: ', '').replaceFirst('UnsupportedError: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    if (_package == null) {
      setState(() => _error = 'Choose and validate a ZIP package first.');
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      await widget.repository.submitApp(MiniApp(
        id: 'package-$id',
        name: _name.text.trim(),
        description: _description.text.trim(),
        shortDescription: _description.text.trim(),
        launchUrl: Uri.file(_package!.indexPath).toString(),
        packagePath: _package!.indexPath,
        category: _category,
        developer: _developer.text.trim().isEmpty ? 'Independent developer' : _developer.text.trim(),
        keywords: 'offline html css javascript uploaded package',
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not add package: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload mini app')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.inventory_2_outlined, size: 32, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text('Upload a mini app package', style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Choose a ZIP with an index.html file and its CSS, JavaScript and assets. Tween checks the package before adding it.',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _choosePackage,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.folder_zip_outlined),
            label: Text(_busy ? 'Checking package…' : _fileName ?? 'Choose ZIP file'),
          ),
          const SizedBox(height: 8),
          const Text('Limit: 25 MB ZIP • 60 MB extracted • up to 1,500 files. HTTPS external links are not required for the app itself.',
            style: TextStyle(fontSize: 12)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          ],
          const SizedBox(height: 22),
          Text('Listing details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'App name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter an app name' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _description, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.trim().length < 5 ? 'Add a short description' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _developer, decoration: const InputDecoration(labelText: 'Developer name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Utilities'),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _busy ? null : _publish,
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Add package to My Apps'),
          ),
          const SizedBox(height: 10),
          Text('This starter installs the HTML package locally on this device. Production publishing and syncing to other users needs secure server storage, scanning and moderation.',
            style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
