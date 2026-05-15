import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dialogs/author_details_dialog.dart';
import 'dialogs/book_details_dialog.dart';
import 'localization/app_strings.dart';
import 'models/app_models.dart';
import 'screens/authors_screen.dart';
import 'screens/books_screen.dart';
import 'screens/currencies_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorageService = LocalStorageService();

  AppSection _selectedSection = AppSection.books;
  String _selectedCurrency = 'PLN';
  String _language = 'pl';
  double _textScale = 1.0;
  bool _highContrast = false;

  bool _appLoading = true;
  bool _savedLoading = false;
  String? _savedError;

  final Map<String, BookListItem> _savedBooks = <String, BookListItem>{};
  final Map<String, AuthorSearchItem> _savedAuthors = <String, AuthorSearchItem>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final stored = await _localStorageService.loadState();
    if (!mounted) return;

    setState(() {
      _selectedCurrency = stored.selectedCurrency;
      _language = stored.language;
      _textScale = stored.textScale;
      _highContrast = stored.highContrast;
    });

    await _refreshSavedItems(
      bookIds: stored.savedBookIds,
      authorIds: stored.savedAuthorIds,
      showLoading: stored.savedBookIds.isNotEmpty || stored.savedAuthorIds.isNotEmpty,
    );

    if (!mounted) return;
    setState(() {
      _appLoading = false;
    });
  }

  Future<void> _persistSettings() {
    return _localStorageService.saveSettings(
      selectedCurrency: _selectedCurrency,
      language: _language,
      textScale: _textScale,
      highContrast: _highContrast,
    );
  }

  Future<void> _persistSavedIds() async {
    await _localStorageService.saveSavedBookIds(_savedBooks.keys.toSet());
    await _localStorageService.saveSavedAuthorIds(_savedAuthors.keys.toSet());
  }

  Future<void> _toggleSavedBook(BookListItem item) async {
    final isRemoving = _savedBooks.containsKey(item.id);

    setState(() {
      if (isRemoving) {
        _savedBooks.remove(item.id);
      } else {
        _savedBooks[item.id] = item;
      }
    });

    await _persistSavedIds();

    if (!isRemoving) {
      await _refreshSingleSavedBook(item.id);
    }
  }

  Future<void> _toggleSavedAuthor(AuthorSearchItem item) async {
    final isRemoving = _savedAuthors.containsKey(item.id);

    setState(() {
      if (isRemoving) {
        _savedAuthors.remove(item.id);
      } else {
        _savedAuthors[item.id] = item;
      }
    });

    await _persistSavedIds();

    if (!isRemoving) {
      await _refreshSingleSavedAuthor(item.id);
    }
  }

  Future<void> _refreshSingleSavedBook(String bookId) async {
    try {
      final details = await _apiService.getBookDetails(bookId: bookId, currency: _selectedCurrency);
      if (!mounted) return;
      setState(() {
        _savedBooks[bookId] = _mapBookDetailsToListItem(details);
      });
      await _persistSavedIds();
    } catch (_) {
      // Keep the locally visible item if the refresh fails.
    }
  }

  Future<void> _refreshSingleSavedAuthor(String authorId) async {
    try {
      final details = await _apiService.getAuthorDetails(authorId: authorId, currency: _selectedCurrency);
      if (!mounted) return;
      setState(() {
        _savedAuthors[authorId] = _mapAuthorDetailsToSearchItem(details);
      });
      await _persistSavedIds();
    } catch (_) {
      // Keep the locally visible item if the refresh fails.
    }
  }

  Future<void> _refreshSavedBooksOnly() {
    return _refreshSavedItems(
      bookIds: _savedBooks.keys.toSet(),
      authorIds: _savedAuthors.keys.toSet(),
      showLoading: _selectedSection == AppSection.saved,
    );
  }

  Future<void> _refreshSavedItems({
    Set<String>? bookIds,
    Set<String>? authorIds,
    bool showLoading = true,
  }) async {
    final targetBookIds = bookIds ?? _savedBooks.keys.toSet();
    final targetAuthorIds = authorIds ?? _savedAuthors.keys.toSet();

    if (showLoading && mounted) {
      setState(() {
        _savedLoading = true;
        _savedError = null;
      });
    }

    final updatedBooks = <String, BookListItem>{};
    final updatedAuthors = <String, AuthorSearchItem>{};
    String? error;

    for (final id in targetBookIds) {
      try {
        final details = await _apiService.getBookDetails(bookId: id, currency: _selectedCurrency);
        updatedBooks[id] = _mapBookDetailsToListItem(details);
      } catch (e) {
        error ??= e.toString();
        if (_savedBooks.containsKey(id)) {
          updatedBooks[id] = _savedBooks[id]!;
        }
      }
    }

    for (final id in targetAuthorIds) {
      try {
        final details = await _apiService.getAuthorDetails(authorId: id, currency: _selectedCurrency);
        updatedAuthors[id] = _mapAuthorDetailsToSearchItem(details);
      } catch (e) {
        error ??= e.toString();
        if (_savedAuthors.containsKey(id)) {
          updatedAuthors[id] = _savedAuthors[id]!;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _savedBooks
        ..clear()
        ..addAll(updatedBooks);
      _savedAuthors
        ..clear()
        ..addAll(updatedAuthors);
      _savedError = error;
      _savedLoading = false;
    });

    await _persistSavedIds();
  }

  PriceRange? _buildPriceRange(List<OfferItem> offers) {
    final pricedOffers = offers.where((offer) => offer.hasPrice && offer.convertedPrice != null).toList();
    if (pricedOffers.isEmpty) {
      return null;
    }

    final amounts = pricedOffers.map((offer) => offer.convertedPrice!.amount).toList();
    final minAmount = amounts.reduce(math.min);
    final maxAmount = amounts.reduce(math.max);
    return PriceRange(
      min: minAmount,
      max: maxAmount,
      currency: pricedOffers.first.convertedPrice!.currency,
    );
  }

  BookListItem _mapBookDetailsToListItem(BookDetails details) {
    return BookListItem(
      id: details.id,
      title: details.title,
      subtitle: details.subtitle,
      authors: details.authors.map((author) => author.name).toList(),
      coverUrl: details.coverUrl,
      language: details.language,
      genre: details.genres.isEmpty ? null : details.genres.first,
      isbn13: details.isbn13,
      offersCount: details.offers.where((offer) => offer.hasPrice).length,
      priceRange: _buildPriceRange(details.offers),
    );
  }

  AuthorSearchItem _mapAuthorDetailsToSearchItem(AuthorDetails details) {
    return AuthorSearchItem(
      id: details.id,
      name: details.name,
      birthYear: details.birthYear,
      deathYear: details.deathYear,
      photoUrl: details.photoUrl,
      booksCount: details.books.length,
    );
  }


  AuthorSearchItem _mapAuthorShortToSearchItem(AuthorShort author) {
    return AuthorSearchItem(
      id: author.id,
      name: author.name,
      birthYear: null,
      deathYear: null,
      photoUrl: null,
      booksCount: 0,
    );
  }

  Future<void> _setSelectedCurrency(String currency) async {
    setState(() {
      _selectedCurrency = currency;
    });
    await _persistSettings();
    await _refreshSavedBooksOnly();
  }

  Future<void> _setLanguage(String language) async {
    setState(() {
      _language = language;
    });
    await _persistSettings();
  }

  Future<void> _setTextScale(double value) async {
    setState(() {
      _textScale = value;
    });
    await _persistSettings();
  }

  Future<void> _setHighContrast(bool value) async {
    setState(() {
      _highContrast = value;
    });
    await _persistSettings();
  }

  Future<void> _openBookDialog(String bookId) async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) return;
    await showDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (context) => BookDetailsDialog(
        apiService: _apiService,
        bookId: bookId,
        currency: _selectedCurrency,
        isSavedBook: _savedBooks.containsKey(bookId),
        savedAuthorIds: _savedAuthors.keys.toSet(),
        onToggleSavedBook: (item) {
          _toggleSavedBook(item);
        },
        onToggleSavedAuthor: (item) {
          _toggleSavedAuthor(item);
        },
        onOpenAuthor: (authorId) {
          _openAuthorDialog(authorId);
        },
      ),
    );
  }

  Future<void> _openAuthorDialog(String authorId) async {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) return;
    await showDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (context) => AuthorDetailsDialog(
        apiService: _apiService,
        authorId: authorId,
        currency: _selectedCurrency,
        isSavedAuthor: _savedAuthors.containsKey(authorId),
        savedBookIds: _savedBooks.keys.toSet(),
        onToggleSavedAuthor: (item) {
          _toggleSavedAuthor(item);
        },
        onToggleSavedBook: (item) {
          _toggleSavedBook(item);
        },
        onOpenBook: (bookId) {
          _openBookDialog(bookId);
        },
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
          onToggleSaved: (item) {
            _toggleSavedBook(item);
          },
          onOpenBook: (bookId) {
            _openBookDialog(bookId);
          },
        );
      case AppSection.authors:
        return AuthorsScreen(
          apiService: _apiService,
          savedAuthorIds: _savedAuthors.keys.toSet(),
          onToggleSaved: (item) {
            _toggleSavedAuthor(item);
          },
          onOpenAuthor: (authorId) {
            _openAuthorDialog(authorId);
          },
        );
      case AppSection.currencies:
        return CurrenciesScreen(
          apiService: _apiService,
          selectedCurrency: _selectedCurrency,
          onSelectCurrency: (currency) {
            _setSelectedCurrency(currency);
          },
        );
      case AppSection.saved:
        return SavedScreen(
          savedBooks: _savedBooks.values.toList(),
          savedAuthors: _savedAuthors.values.toList(),
          currency: _selectedCurrency,
          loading: _savedLoading,
          error: _savedError,
          onRefresh: () {
            _refreshSavedItems(showLoading: true);
          },
          onOpenBook: (bookId) {
            _openBookDialog(bookId);
          },
          onOpenAuthor: (authorId) {
            _openAuthorDialog(authorId);
          },
          onRemoveBook: (item) {
            _toggleSavedBook(item);
          },
          onRemoveAuthor: (item) {
            _toggleSavedAuthor(item);
          },
        );
      case AppSection.settings:
        return SettingsScreen(
          selectedLanguage: _language,
          textScale: _textScale,
          highContrast: _highContrast,
          onLanguageChanged: (value) {
            _setLanguage(value);
          },
          onTextScaleChanged: (value) {
            _setTextScale(value);
          },
          onHighContrastChanged: (value) {
            _setHighContrast(value);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_language);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: strings.appTitle,
      locale: Locale(_language),
      supportedLocales: const [
        Locale('pl'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: _highContrast ? Brightness.dark : Brightness.light,
        colorSchemeSeed: _highContrast ? Colors.amber : Colors.deepPurple,
        scaffoldBackgroundColor: _highContrast ? const Color(0xFF111111) : null,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return AppStringsScope(
          strings: strings,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(_textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: Scaffold(
        body: _appLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  SideNavBar(
                    selected: _selectedSection,
                    onSelect: (section) {
                      setState(() {
                        _selectedSection = section;
                      });
                      if (section == AppSection.saved) {
                        _refreshSavedItems(showLoading: true);
                      }
                    },
                  ),
                  Expanded(child: _buildContent()),
                ],
              ),
      ),
    );
  }
}
