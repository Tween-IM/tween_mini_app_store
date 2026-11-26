import 'package:flutter/material.dart';

import '../models/mini_app.dart';
import '../repository/mini_app_repository.dart';
import '../services/website_metadata_service.dart';

class SubmitMiniAppScreen extends StatefulWidget {
  const SubmitMiniAppScreen({super.key, required this.repository});
  final MiniAppRepository repository;

  @override
  State<SubmitMiniAppScreen> createState() => _SubmitMiniAppScreenState();
}

class _SubmitMiniAppScreenState extends State<SubmitMiniAppScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _launchUrl = TextEditingController();
  final _description = TextEditingController();
  final _developer = TextEditingController();
  final _iconUrl = TextEditingController();
  final _coverUrl = TextEditingController();
  final _privacyUrl = TextEditingController();
  final _supportUrl = TextEditingController();
  final _shortDescription = TextEditingController();
  final _keywords = TextEditingController();
  final _screenshots = TextEditingController();

  final _metadataService = WebsiteMetadataService();
  WebsiteMetadata? _metadata;
  String _category = 'Utilities';
  bool _fetching = false;
  bool _saving = false;
  String? _fetchError;

  static const _categories = [
    'Utilities',
    'Shopping',
    'Education',
    'Entertainment',
    'Finance',
    'Lifestyle',
    'Productivity',
    'Social',
  ];

  @override
  void dispose() {
    for (final controller in [
      _name,
      _url,
      _launchUrl,
      _description,
      _developer,
      _iconUrl,
      _coverUrl,
      _privacyUrl,
      _supportUrl,
      _shortDescription,
      _keywords,
      _screenshots,
    ]) {
      controller.dispose();
    }
    _metadataService.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _httpsUrl(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'This field is required' : null;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return 'Enter a valid HTTPS URL';
    }
    return null;
  }

  Future<void> _fetchWebsite() async {
    if (_httpsUrl(_url.text) != null) {
      setState(() => _fetchError = 'Enter a valid HTTPS URL first.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _fetching = true;
      _fetchError = null;
    });
    try {
      final result = await _metadataService.fetch(_url.text);
      if (!mounted) return;
      setState(() {
        _metadata = result;
        // Fetch is explicit: metadata fills fields, and every field remains editable.
        _name.text = result.title ?? result.siteName ?? _name.text;
        _description.text = result.description ?? _description.text;
        _developer.text = result.siteName ?? _developer.text;
        _iconUrl.text = result.iconUrl ?? _iconUrl.text;
        _coverUrl.text = result.imageUrl ?? _coverUrl.text;
        final canonical = result.canonicalUrl ?? _url.text.trim();
        _launchUrl.text = canonical;
        _category = _suggestCategory(
          '${result.title ?? ''} ${result.description ?? ''} ${_url.text}',
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website details fetched. Review and edit before submitting.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fetchError = 'Could not automatically read this website. '
            'You can still complete the listing manually. (${_friendlyError(error)})';
      });
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.toLowerCase().contains('cors') ||
        text.toLowerCase().contains('clientexception')) {
      return 'The site may block direct requests (common on Flutter Web). '
          'A metadata backend endpoint is recommended.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  String _suggestCategory(String text) {
    final value = text.toLowerCase();
    if (value.contains(RegExp(r'school|learn|course|class|education|student'))) {
      return 'Education';
    }
    if (value.contains(RegExp(r'shop|store|cart|product|market'))) {
      return 'Shopping';
    }
    if (value.contains(RegExp(r'music|video|movie|game|stream|entertain'))) {
      return 'Entertainment';
    }
    if (value.contains(RegExp(r'bank|payment|wallet|finance|money'))) {
      return 'Finance';
    }
    if (value.contains(RegExp(r'chat|social|community|message'))) {
      return 'Social';
    }
    if (value.contains(RegExp(r'task|project|work|productivity'))) {
      return 'Productivity';
    }
    if (value.contains(RegExp(r'health|beauty|travel|food|lifestyle'))) {
      return 'Lifestyle';
    }
    return 'Utilities';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a mini app')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text('Publish a website as a mini app',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(
              'Paste a public HTTPS link. We will try to find its name, icon, '
              'description and preview image automatically. Everything can be edited.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://yourapp.com',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
              ),
              validator: _httpsUrl,
              onChanged: (value) {
                if (_launchUrl.text.trim().isEmpty) {
                  _launchUrl.text = value.trim();
                }
                if (_metadata != null) setState(() => _metadata = null);
              },
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _fetching ? null : _fetchWebsite,
              icon: _fetching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_fetching ? 'Reading website…' : 'Fetch website details'),
            ),
            if (_fetchError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_fetchError!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            ],
            if (_metadata != null) ...[
              const SizedBox(height: 14),
              _MetadataPreview(metadata: _metadata!),
            ],
            const SizedBox(height: 24),
            Text('Store listing',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Mini app name',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shortDescription,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Short description (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Full description',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _developer,
              decoration: const InputDecoration(
                labelText: 'Developer / publisher',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? 'Utilities'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _iconUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'App icon URL',
                hintText: 'https://…/icon.png',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              validator: (value) => _httpsUrl(value, required: false),
              onChanged: (_) => setState(() {}),
            ),
            if (_iconUrl.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _ImagePreview(url: _iconUrl.text, size: 60),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Icon preview • Edit the URL above to replace it')),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Cover / preview image URL',
                hintText: 'Optional website preview image',
                prefixIcon: Icon(Icons.photo_outlined),
              ),
              validator: (value) => _httpsUrl(value, required: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _screenshots,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Screenshot image URLs (optional)',
                hintText: 'Paste one HTTPS image URL per line',
                helperText: 'Use images hosted on your website or CDN.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _launchUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Launch URL',
                helperText: 'The exact page opened inside the mini app',
                prefixIcon: Icon(Icons.open_in_browser_rounded),
              ),
              validator: _httpsUrl,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _privacyUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Privacy policy URL (optional)'),
              validator: (value) => _httpsUrl(value, required: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supportUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Support URL (optional)'),
              validator: (value) => _httpsUrl(value, required: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keywords,
              decoration: const InputDecoration(
                labelText: 'Search keywords (optional)',
                hintText: 'learning, classes, online',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.publish_rounded),
              label: Text(_saving ? 'Submitting…' : 'Submit for review'),
            ),
            const SizedBox(height: 8),
            Text(
              'The demo repository stores submissions in memory. Connect your '
              'backend for developer accounts, moderation and persistent publishing.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final app = MiniApp(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      launchUrl: (_launchUrl.text.trim().isEmpty ? _url.text : _launchUrl.text).trim(),
      category: _category,
      iconUrl: _iconUrl.text.trim().isEmpty ? null : _iconUrl.text.trim(),
      developer: _developer.text.trim(),
      coverImageUrl: _coverUrl.text.trim().isEmpty ? null : _coverUrl.text.trim(),
      shortDescription: _shortDescription.text.trim().isEmpty
          ? null
          : _shortDescription.text.trim(),
      privacyPolicyUrl: _privacyUrl.text.trim().isEmpty ? null : _privacyUrl.text.trim(),
      supportUrl: _supportUrl.text.trim().isEmpty ? null : _supportUrl.text.trim(),
      keywords: _keywords.text.trim().isEmpty ? null : _keywords.text.trim(),
      canonicalUrl: _metadata?.canonicalUrl,
      language: _metadata?.language,
      themeColor: _metadata?.themeColor,
      screenshotUrls: _screenshots.text
          .split(RegExp(r'[\r\n]+'))
          .map((value) => value.trim())
          .where((value) => value.startsWith('https://'))
          .toList(),
    );
    try {
      await widget.repository.submitApp(app);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MetadataPreview extends StatelessWidget {
  const _MetadataPreview({required this.metadata});
  final WebsiteMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ImagePreview(url: metadata.iconUrl ?? metadata.imageUrl, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Website preview',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(metadata.title ?? metadata.siteName ?? 'No title found',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(metadata.description ?? 'No description metadata found',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
                if (metadata.language != null)
                  Text('Language: ${metadata.language}',
                      style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url, required this.size});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parsed = url == null ? null : Uri.tryParse(url!);
    if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(size * .2),
        ),
        child: const Icon(Icons.apps_rounded),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .2),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
