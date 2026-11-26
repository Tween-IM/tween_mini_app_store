import 'package:flutter/material.dart';

import '../models/app_suggestion.dart';
import '../repository/app_suggestion_repository.dart';

class SuggestAppScreen extends StatefulWidget {
  const SuggestAppScreen({super.key, required this.repository, this.initialSource = SuggestionSource.website});
  final AppSuggestionRepository repository;
  final SuggestionSource initialSource;

  @override
  State<SuggestAppScreen> createState() => _SuggestAppScreenState();
}

class _SuggestAppScreenState extends State<SuggestAppScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sourceUrl = TextEditingController();
  final _reason = TextEditingController();
  final _submitter = TextEditingController();
  String _category = 'Entertainment';
  SuggestionSource _source = SuggestionSource.website;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
  }

  static const _categories = [
    'Entertainment', 'Education', 'Business', 'Shopping', 'Productivity',
    'Design & Creativity', 'Utilities', 'Social', 'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _sourceUrl.dispose();
    _reason.dispose();
    _submitter.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (_source == SuggestionSource.appIdea) return null;
    final uri = Uri.tryParse((value ?? '').trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return 'Enter a valid HTTPS website or repository link';
    }
    if (_source == SuggestionSource.github &&
        !uri.host.toLowerCase().contains('github.com')) {
      return 'For GitHub import suggestions, use a github.com repository URL';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = AppSuggestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      source: _source,
      sourceUrl: _sourceUrl.text.trim().isEmpty ? null : _sourceUrl.text.trim(),
      description: _reason.text.trim(),
      category: _category,
      submitter: _submitter.text.trim().isEmpty ? 'Community member' : _submitter.text.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await widget.repository.submitSuggestion(item);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send suggestion: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceDescription = switch (_source) {
      SuggestionSource.website => 'Suggest a website or PWA for the store.',
      SuggestionSource.github => 'Suggest a public GitHub repository for developer review.',
      SuggestionSource.appIdea => 'Share an app idea even if it is not built yet.',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Suggest an app')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.onSecondaryContainer, size: 30),
                const SizedBox(height: 8),
                Text('Help grow Tween', style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Recommend useful apps. The store team can review suggestions before publishing.',
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
              ]),
            ),
            const SizedBox(height: 20),
            Text('What are you suggesting?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<SuggestionSource>(
              value: _source,
              decoration: const InputDecoration(labelText: 'Submission type'),
              items: const [
                DropdownMenuItem(value: SuggestionSource.website, child: Text('Website / PWA')),
                DropdownMenuItem(value: SuggestionSource.github, child: Text('GitHub project')),
                DropdownMenuItem(value: SuggestionSource.appIdea, child: Text('An app idea')),
              ],
              onChanged: (value) => setState(() => _source = value ?? SuggestionSource.website),
            ),
            const SizedBox(height: 5),
            Text(sourceDescription, style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'App or project name', prefixIcon: Icon(Icons.apps_rounded)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),
            if (_source != SuggestionSource.appIdea) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _sourceUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: _source == SuggestionSource.github ? 'GitHub repository URL' : 'Website URL',
                  hintText: _source == SuggestionSource.github ? 'https://github.com/owner/project' : 'https://example.com',
                  prefixIcon: const Icon(Icons.link_rounded),
                ),
                validator: _validateUrl,
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Other'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Why should Tween add it?',
                hintText: 'Tell us what makes this app useful…',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().length < 8 ? 'Add a short reason (at least 8 characters)' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _submitter,
              decoration: const InputDecoration(labelText: 'Your name or developer name (optional)', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
              label: Text(_saving ? 'Sending…' : 'Send suggestion'),
            ),
            const SizedBox(height: 12),
            Text('Suggestions are stored in this demo session only. A connected backend is needed for permanent submissions and team review.',
              style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
