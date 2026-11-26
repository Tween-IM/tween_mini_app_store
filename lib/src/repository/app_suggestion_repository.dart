import '../models/app_suggestion.dart';

/// A small demo queue. Replace this with a backend-backed implementation for
/// cross-device persistence, developer accounts, and moderation.
abstract class AppSuggestionRepository {
  Future<List<AppSuggestion>> fetchSuggestions();
  Future<void> submitSuggestion(AppSuggestion suggestion);
  Future<void> updateStatus(String id, SuggestionStatus status);
}

class DemoAppSuggestionRepository implements AppSuggestionRepository {
  static final DemoAppSuggestionRepository instance = DemoAppSuggestionRepository._();
  DemoAppSuggestionRepository._();

  final List<AppSuggestion> _items = [];

  @override
  Future<List<AppSuggestion>> fetchSuggestions() async =>
      List.unmodifiable(_items);

  @override
  Future<void> submitSuggestion(AppSuggestion suggestion) async {
    _items.insert(0, suggestion);
  }

  @override
  Future<void> updateStatus(String id, SuggestionStatus status) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(status: status);
  }
}
