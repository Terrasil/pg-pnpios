import 'package:flutter/material.dart';

import 'dialogs/author_details_dialog.dart';
import 'dialogs/book_details_dialog.dart';
import 'models/app_models.dart';
import 'screens/authors_screen.dart';
import 'screens/books_screen.dart';
import 'screens/currencies_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'widgets/side_nav_bar.dart';

void main() {
  runApp(const BookFinderApp());
}

class BookFinderApp extends StatefulWidget {
  const BookFinderApp({super.key});

  @override
  State<BookFinderApp> createState() => _BookFinderAppState();
}

class _BookFinderAppState extends State<BookFinderApp> {
  final ApiService _apiService = ApiService();

  AppSection _selectedSection = AppSection.books;
  String _selectedCurrency = 'PLN';
  String _language = 'pl';
  double _textScale = 1.0;
  bool _highContrast = false;

  final Map<String, BookListItem> _savedBooks = <String, BookListItem>{};
  final Map<String, AuthorSearchItem> _savedAuthors = <String, AuthorSearchItem>{};

  void _toggleSavedBook(BookListItem item) {
    setState(() {
      if (_savedBooks.containsKey(item.id)) {
        _savedBooks.remove(item.id);
      } else {
        _savedBooks[item.id] = item;
      }
    });
  }

  void _toggleSavedAuthor(AuthorSearchItem item) {
    setState(() {
      if (_savedAuthors.containsKey(item.id)) {
        _savedAuthors.remove(item.id);
      } else {
        _savedAuthors[item.id] = item;
      }
    });
  }

  Future<void> _openBookDialog(String bookId) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => BookDetailsDialog(
        apiService: _apiService,
        bookId: bookId,
        currency: _selectedCurrency,
      ),
    );
  }

  Future<void> _openAuthorDialog(String authorId) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AuthorDetailsDialog(
        apiService: _apiService,
        authorId: authorId,
        currency: _selectedCurrency,
        onOpenBook: _openBookDialog,
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case AppSection.books:
        return BooksScreen(
          apiService: _apiService,
          currency: _selectedCurrency,
          savedBookIds: _savedBooks.keys.toSet(),
          onToggleSaved: _toggleSavedBook,
          onOpenBook: _openBookDialog,
        );
      case AppSection.authors:
        return AuthorsScreen(
          apiService: _apiService,
          savedAuthorIds: _savedAuthors.keys.toSet(),
          onToggleSaved: _toggleSavedAuthor,
          onOpenAuthor: _openAuthorDialog,
        );
      case AppSection.currencies:
        return CurrenciesScreen(
          apiService: _apiService,
          selectedCurrency: _selectedCurrency,
          onSelectCurrency: (currency) {
            setState(() {
              _selectedCurrency = currency;
            });
          },
        );
      case AppSection.saved:
        return SavedScreen(
          savedBooks: _savedBooks.values.toList(),
          savedAuthors: _savedAuthors.values.toList(),
          currency: _selectedCurrency,
          onOpenBook: _openBookDialog,
          onOpenAuthor: _openAuthorDialog,
          onRemoveBook: (item) => _toggleSavedBook(item),
          onRemoveAuthor: (item) => _toggleSavedAuthor(item),
        );
      case AppSection.settings:
        return SettingsScreen(
          selectedLanguage: _language,
          textScale: _textScale,
          highContrast: _highContrast,
          onLanguageChanged: (value) {
            setState(() {
              _language = value;
            });
          },
          onTextScaleChanged: (value) {
            setState(() {
              _textScale = value;
            });
          },
          onHighContrastChanged: (value) {
            setState(() {
              _highContrast = value;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Finder',
      theme: ThemeData(
        useMaterial3: true,
        brightness: _highContrast ? Brightness.dark : Brightness.light,
        colorSchemeSeed: _highContrast ? Colors.amber : Colors.deepPurple,
        scaffoldBackgroundColor: _highContrast ? const Color(0xFF111111) : null,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(_textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: Row(
          children: [
            SideNavBar(
              selected: _selectedSection,
              onSelect: (section) {
                setState(() {
                  _selectedSection = section;
                });
              },
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
