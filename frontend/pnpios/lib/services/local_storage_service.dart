import 'package:shared_preferences/shared_preferences.dart';

class StoredAppState {
  final String selectedCurrency;
  final String language;
  final double textScale;
  final bool highContrast;
  final Set<String> savedBookIds;
  final Set<String> savedAuthorIds;

  const StoredAppState({
    required this.selectedCurrency,
    required this.language,
    required this.textScale,
    required this.highContrast,
    required this.savedBookIds,
    required this.savedAuthorIds,
  });
}

class LocalStorageService {
  static const int _maxHistoryItems = 10;

  static const String _selectedCurrencyKey = 'selected_currency';
  static const String _languageKey = 'language';
  static const String _textScaleKey = 'text_scale';
  static const String _highContrastKey = 'high_contrast';
  static const String _savedBookIdsKey = 'saved_book_ids';
  static const String _savedAuthorIdsKey = 'saved_author_ids';
  static const String _bookSearchHistoryKey = 'book_search_history';
  static const String _authorSearchHistoryKey = 'author_search_history';

  Future<StoredAppState> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    return StoredAppState(
      selectedCurrency: prefs.getString(_selectedCurrencyKey) ?? 'PLN',
      language: prefs.getString(_languageKey) ?? 'pl',
      textScale: prefs.getDouble(_textScaleKey) ?? 1.0,
      highContrast: prefs.getBool(_highContrastKey) ?? false,
      savedBookIds: (prefs.getStringList(_savedBookIdsKey) ?? const <String>[]).toSet(),
      savedAuthorIds: (prefs.getStringList(_savedAuthorIdsKey) ?? const <String>[]).toSet(),
    );
  }

  Future<void> saveSettings({
    required String selectedCurrency,
    required String language,
    required double textScale,
    required bool highContrast,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCurrencyKey, selectedCurrency);
    await prefs.setString(_languageKey, language);
    await prefs.setDouble(_textScaleKey, textScale);
    await prefs.setBool(_highContrastKey, highContrast);
  }

  Future<void> saveSavedBookIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedBookIdsKey, ids.toList()..sort());
  }

  Future<void> saveSavedAuthorIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedAuthorIdsKey, ids.toList()..sort());
  }

  Future<List<String>> loadBookSearchHistory() {
    return _loadSearchHistory(_bookSearchHistoryKey);
  }

  Future<List<String>> loadAuthorSearchHistory() {
    return _loadSearchHistory(_authorSearchHistoryKey);
  }

  Future<List<String>> addBookSearchHistory(String query) {
    return _addSearchHistory(_bookSearchHistoryKey, query);
  }

  Future<List<String>> addAuthorSearchHistory(String query) {
    return _addSearchHistory(_authorSearchHistoryKey, query);
  }

  Future<List<String>> _loadSearchHistory(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(key) ?? const <String>[]);
  }

  Future<List<String>> _addSearchHistory(String key, String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return _loadSearchHistory(key);
    }

    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(prefs.getStringList(key) ?? const <String>[]);
    current.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
    current.insert(0, normalized);

    final limited = current.take(_maxHistoryItems).toList();
    await prefs.setStringList(key, limited);
    return limited;
  }
}
