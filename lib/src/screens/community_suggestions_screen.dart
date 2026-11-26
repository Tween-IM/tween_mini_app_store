import 'package:flutter/material.dart';

import '../models/app_suggestion.dart';
import '../repository/app_suggestion_repository.dart';
import 'suggest_app_screen.dart';

class CommunitySuggestionsScreen extends StatefulWidget {
  const CommunitySuggestionsScreen({super.key, required this.repository});
  final AppSuggestionRepository repository;

  @override
  State<CommunitySuggestionsScreen> createState() => _CommunitySuggestionsScreenState();
}

class _CommunitySuggestionsScreenState extends State<CommunitySuggestionsScreen> {
  late Future<List<AppSuggestion>> _future;
  final Set<String> _voted = {};
  final Map<String, int> _votes = {};

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchSuggestions();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.fetchSuggestions());
  }

  Future<void> _suggest() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => SuggestAppScreen(repository: widget.repository),
    ));
    if (result == true && mounted) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your suggestion is now in the community list.')),
      );
    }
  }

  String _status(SuggestionStatus status) => switch (status) {
    SuggestionStatus.pending => 'Under review',
    SuggestionStatus.approved => 'Approved',
    SuggestionStatus.declined => 'Not selected',
  };

  IconData _sourceIcon(SuggestionSource source) => switch (source) {
    SuggestionSource.website => Icons.language_rounded,
    SuggestionSource.github => Icons.code_rounded,
    SuggestionSource.appIdea => Icons.lightbulb_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Community suggestions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _suggest,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Suggest an app'),
      ),
      body: FutureBuilder<List<AppSuggestion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Could not load suggestions: ${snapshot.error}'));
          final items = snapshot.data ?? const <AppSuggestion>[];
          if (items.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tips_and_updates_outlined, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 14),
                Text('Be the first to suggest an app', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Share a website, a GitHub project, or an idea the Tween community would love.',
                  textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: _suggest, icon: const Icon(Icons.add_rounded), label: const Text('Make a suggestion')),
              ]),
            ));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final voted = _voted.contains(item.id);
                final count = _votes[item.id] ?? 0;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(child: Icon(_sourceIcon(item.source))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('${item.category} • ${_status(item.status)}', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text(item.description),
                        if (item.sourceUrl != null) ...[
                          const SizedBox(height: 6),
                          Text(item.sourceUrl!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 8),
                        Text('Suggested by ${item.submitter}', style: theme.textTheme.labelSmall),
                      ])),
                      const SizedBox(width: 6),
                      Column(children: [
                        IconButton(
                          tooltip: voted ? 'Vote recorded' : 'Support this suggestion',
                          onPressed: voted ? null : () => setState(() {
                            _voted.add(item.id);
                            _votes[item.id] = count + 1;
                          }),
                          icon: Icon(voted ? Icons.arrow_upward_rounded : Icons.keyboard_arrow_up_rounded),
                        ),
                        Text('$count', style: theme.textTheme.labelMedium),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
