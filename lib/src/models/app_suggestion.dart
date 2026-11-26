enum SuggestionSource { website, github, appIdea }

enum SuggestionStatus { pending, approved, declined }

class AppSuggestion {
  const AppSuggestion({
    required this.id,
    required this.name,
    required this.source,
    required this.description,
    required this.category,
    required this.submitter,
    this.sourceUrl,
    this.status = SuggestionStatus.pending,
    this.createdAt,
  });

  final String id;
  final String name;
  final SuggestionSource source;
  final String description;
  final String category;
  final String submitter;
  final String? sourceUrl;
  final SuggestionStatus status;
  final DateTime? createdAt;

  AppSuggestion copyWith({SuggestionStatus? status}) => AppSuggestion(
    id: id, name: name, source: source, description: description,
    category: category, submitter: submitter, sourceUrl: sourceUrl,
    status: status ?? this.status, createdAt: createdAt,
  );
}
