import 'package:flutter/widgets.dart';

class AppStringsScope extends InheritedWidget {
  final AppStrings strings;

  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    assert(scope != null, 'AppStringsScope not found in widget tree');
    return scope!.strings;
  }

  @override
  bool updateShouldNotify(covariant AppStringsScope oldWidget) {
    return oldWidget.strings.languageCode != strings.languageCode;
  }
}

class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  bool get isPl => languageCode.toLowerCase() == 'pl';

  String get appTitle => isPl ? 'Wyszukiwarka książek' : 'Book Finder';

  String get navBooks => isPl ? 'Książki' : 'Books';
  String get navAuthors => isPl ? 'Autorzy' : 'Authors';
  String get navCurrencies => isPl ? 'Waluty' : 'Currencies';
  String get navSaved => isPl ? 'Zapisane' : 'Saved';
  String get navSettings => isPl ? 'Ustawienia' : 'Settings';

  String get booksSearchTitle => isPl ? 'Wyszukiwanie książek' : 'Book search';
  String get authorsSearchTitle => isPl ? 'Wyszukiwanie autorów' : 'Author search';
  String get currenciesTitle => isPl ? 'Wybór waluty' : 'Currency selection';
  String get savedTitle => isPl ? 'Zapisane książki i autorzy' : 'Saved books and authors';
  String get settingsTitle => isPl ? 'Ustawienia aplikacji' : 'Application settings';

  String get searchButton => isPl ? 'Szukaj' : 'Search';
  String get booksSearchHint => isPl ? 'Tytuł, autor lub ISBN' : 'Title, author or ISBN';
  String get authorsSearchHint => isPl ? 'Imię lub nazwisko autora' : 'Author first or last name';

  String get noInitialResultsTitle => isPl ? 'Brak wyników startowych' : 'No initial results';
  String get noInitialBooksMessage => isPl
      ? 'Wpisz frazę i rozpocznij wyszukiwanie książek.'
      : 'Enter a phrase and start searching for books.';
  String get noInitialAuthorsMessage => isPl
      ? 'Wpisz dane autora i rozpocznij wyszukiwanie.'
      : 'Enter an author name and start searching.';

  String get noResultsTitle => isPl ? 'Brak wyników' : 'No results';
  String get noBooksResultsMessage => isPl
      ? 'Backend zwrócił pustą listę książek dla tego zapytania.'
      : 'The backend returned an empty list of books for this query.';
  String get noAuthorsResultsMessage => isPl
      ? 'Backend zwrócił pustą listę autorów dla tego zapytania.'
      : 'The backend returned an empty list of authors for this query.';


  String get filtersTitle => isPl ? 'Filtry' : 'Filters';
  String get clearFiltersButton => isPl ? 'Wyczyść filtry' : 'Clear filters';
  String get searchHistoryTitle => isPl ? 'Historia wyszukiwania' : 'Search history';
  String get onlySavedFilter => isPl ? 'Tylko zapisane' : 'Saved only';
  String get onlyWithOffersFilter => isPl ? 'Tylko z ofertami' : 'With offers only';
  String get onlyLivingAuthorsFilter => isPl ? 'Tylko żyjący autorzy' : 'Living authors only';
  String get authorFilterHint => isPl ? 'Filtr autora' : 'Author filter';
  String get genreFilterHint => isPl ? 'Filtr gatunku' : 'Genre filter';
  String get languageFilterHint => isPl ? 'Filtr języka' : 'Language filter';
  String get minPriceFilterHint => isPl ? 'Cena od' : 'Min price';
  String get maxPriceFilterHint => isPl ? 'Cena do' : 'Max price';
  String get nameFilterHint => isPl ? 'Filtr nazwy' : 'Name filter';
  String get minBooksFilterHint => isPl ? 'Minimum książek' : 'Minimum books';
  String get noFilteredResultsMessage => isPl
      ? 'Wyniki zostały pobrane, ale żaden element nie spełnia aktywnych filtrów.'
      : 'Results were loaded, but no item matches the active filters.';

  String get noCurrenciesTitle => isPl ? 'Brak walut' : 'No currencies';
  String get noCurrenciesMessage => isPl
      ? 'Backend zwrócił pustą listę walut.'
      : 'The backend returned an empty currency list.';

  String get currentCurrencyLabel => isPl ? 'Aktualna waluta' : 'Current currency';
  String get rateLabel => isPl ? 'Kurs' : 'Rate';
  String get dateLabel => isPl ? 'Data' : 'Date';
  String get missingCode => isPl ? 'Brak kodu' : 'Missing code';
  String get missingName => isPl ? 'Brak nazwy' : 'Missing name';

  String get savedFilterHint => isPl ? 'Filtruj zapisane elementy' : 'Filter saved items';
  String get booksTab => isPl ? 'Książki' : 'Books';
  String get authorsTab => isPl ? 'Autorzy' : 'Authors';
  String get noSavedBooksTitle => isPl ? 'Brak zapisanych książek' : 'No saved books';
  String get noSavedBooksMessage => isPl
      ? 'Dodaj książki z wyników wyszukiwania.'
      : 'Add books from the search results.';
  String get noSavedAuthorsTitle => isPl ? 'Brak zapisanych autorów' : 'No saved authors';
  String get noSavedAuthorsMessage => isPl
      ? 'Dodaj autorów z wyników wyszukiwania.'
      : 'Add authors from the search results.';
  String get refreshSavedButton => isPl ? 'Odśwież z API' : 'Refresh from API';
  String get syncingSavedData => isPl ? 'Odświeżanie zapisanych danych z API…' : 'Refreshing saved data from API…';

  String get languageLabel => isPl ? 'Język' : 'Language';
  String get textSizeLabel => isPl ? 'Rozmiar tekstu' : 'Text size';
  String get highContrastLabel => isPl ? 'Wysoki kontrast' : 'High contrast';
  String get polish => isPl ? 'Polski' : 'Polish';
  String get english => isPl ? 'Angielski' : 'English';

  String get noDataTitle => isPl ? 'Brak danych' : 'No data';
  String get noBookDetailsMessage => isPl
      ? 'Backend nie zwrócił szczegółów książki.'
      : 'The backend did not return book details.';
  String get noAuthorDetailsMessage => isPl
      ? 'Backend nie zwrócił szczegółów autora.'
      : 'The backend did not return author details.';
  String get missingBookDescription => isPl ? 'Brak opisu książki.' : 'No book description.';
  String get missingAuthorDescription => isPl ? 'Brak opisu autora.' : 'No author description.';
  String get offersTitle => isPl ? 'Oferty' : 'Offers';
  String get noOffersTitle => isPl ? 'Brak ofert' : 'No offers';
  String get noOffersMessage => isPl
      ? 'Backend nie zwrócił żadnych ofert dla tej książki.'
      : 'The backend did not return any offers for this book.';
  String get authorBooksTitle => isPl ? 'Książki autora' : 'Author books';
  String get noAuthorBooksTitle => isPl ? 'Brak książek' : 'No books';
  String get noAuthorBooksMessage => isPl
      ? 'Backend nie zwrócił żadnych książek dla tego autora.'
      : 'The backend did not return any books for this author.';


  String get saveToFavoritesTooltip => isPl ? 'Dodaj do zapisanych' : 'Add to saved';
  String get removeFromFavoritesTooltip => isPl ? 'Usuń z zapisanych' : 'Remove from saved';
  String get openAuthorDetailsTooltip => isPl ? 'Pokaż autora' : 'Open author';
  String get openBookDetailsTooltip => isPl ? 'Pokaż książkę' : 'Open book';
  String get descriptionSectionTitle => isPl ? 'Opis' : 'Description';
  String get authorsSectionTitle => isPl ? 'Autorzy' : 'Authors';

  String get copyOfferUrlTooltip => isPl ? 'Kopiuj link oferty' : 'Copy offer link';
  String get openOfferTooltip => isPl ? 'Otwórz link oferty' : 'Open offer link';
  String get offerUrlCopied => isPl ? 'Skopiowano link oferty' : 'Offer link copied';
  String get invalidOfferUrl => isPl ? 'Niepoprawny link oferty' : 'Invalid offer link';
  String get failedOpenUrl => isPl ? 'Nie udało się otworzyć linku' : 'Could not open the link';

  String get loadErrorTitle => isPl ? 'Nie udało się pobrać danych' : 'Could not load data';
  String get retryButton => isPl ? 'Spróbuj ponownie' : 'Try again';
  String get closeButton => isPl ? 'Zamknij' : 'Close';

  String get noAuthor => isPl ? 'Brak autora' : 'No author';
  String valueOrDash(String? value) => (value == null || value.trim().isEmpty) ? '-' : value;

  String authorLabel(String value) => isPl ? 'Autor: $value' : 'Author: $value';
  String languageValue(String value) => isPl ? 'Język: $value' : 'Language: $value';
  String publisherValue(String value) => isPl ? 'Wydawca: $value' : 'Publisher: $value';
  String yearValue(String value) => isPl ? 'Rok: $value' : 'Year: $value';
  String birthDateValue(String value) => isPl ? 'Data urodzenia: $value' : 'Birth date: $value';
  String deathDateValue(String value) => isPl ? 'Data śmierci: $value' : 'Death date: $value';
  String genreValue(String value) => isPl ? 'Gatunek: $value' : 'Genre: $value';
  String offersCount(int count) => isPl ? 'Oferty: $count' : 'Offers: $count';
  String booksCount(int count) => isPl ? 'Liczba książek: $count' : 'Books: $count';
  String simpleBooksCount(int count) => isPl ? 'Książki: $count' : 'Books: $count';
  String priceValue(String value) => isPl ? 'Cena: $value' : 'Price: $value';
  String originalPriceValue(String value) => isPl ? 'Cena oryginalna: $value' : 'Original price: $value';
  String convertedPriceValue(String value) => isPl ? 'Cena po przeliczeniu: $value' : 'Converted price: $value';
  String availabilityValue(String value) => isPl ? 'Dostępność: $value' : 'Availability: $value';
}

extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStringsScope.of(this);
}
