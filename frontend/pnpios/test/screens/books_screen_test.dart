import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/localization/app_strings.dart';
import '../../lib/models/app_models.dart';
import '../../lib/screens/books_screen.dart';
import '../../lib/services/api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('books screen shows search field, history button and filters button without search button', (tester) async {
    await tester.pumpWidget(_wrapWithApp(_booksScreen(FakeApiService())));
    await tester.pumpAndSettle();

    expect(find.text('Wyszukiwanie książek'), findsOneWidget);
    expect(find.byTooltip('Historia wyszukiwania'), findsOneWidget);
    expect(find.byTooltip('Filtry wyników'), findsOneWidget);
    expect(find.text('Szukaj'), findsNothing);
  });

  testWidgets('submitting query renders backend results and saves query to history', (tester) async {
    final api = FakeApiService(items: [_hobbitWithOffers()]);
    await tester.pumpWidget(_wrapWithApp(_booksScreen(api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'hobbit');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(api.lastQuery, 'hobbit');
    expect(find.text('The Hobbit'), findsOneWidget);
    expect(find.text('J. R. R. Tolkien'), findsOneWidget);
    expect(find.text('Oferty: 2'), findsOneWidget);
    expect(find.text('18.20 - 22.40 PLN'), findsOneWidget);

    final history = await LocalStorageServiceForTest.loadBookHistory();
    expect(history, ['hobbit']);
  });

  testWidgets('history button opens saved search phrases', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'book_search_history': <String>['hobbit', 'dune'],
    });
    await tester.pumpWidget(_wrapWithApp(_booksScreen(FakeApiService())));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Historia wyszukiwania'));
    await tester.pumpAndSettle();

    expect(find.text('Historia wyszukiwania'), findsWidgets);
    expect(find.text('hobbit'), findsOneWidget);
    expect(find.text('dune'), findsOneWidget);
  });

  testWidgets('author filter limits visible book results', (tester) async {
    final api = FakeApiService(items: [
      _hobbitWithOffers(),
      const BookListItem(
        id: 'OL2W',
        title: 'Harry Potter',
        authors: ['J. K. Rowling'],
        genre: 'Fantasy',
        offersCount: 1,
        priceRange: PriceRange(min: 30, max: 30, currency: 'PLN'),
      ),
    ]);
    await tester.pumpWidget(_wrapWithApp(_booksScreen(api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'fantasy');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('The Hobbit'), findsOneWidget);
    expect(find.text('Harry Potter'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtry wyników'));
    await tester.pumpAndSettle();

    final authorFilter = find.ancestor(
      of: find.text('Filtr autora'),
      matching: find.byType(TextField),
    );
    await tester.enterText(authorFilter, 'rowling');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zamknij'));
    await tester.pumpAndSettle();

    expect(find.text('The Hobbit'), findsNothing);
    expect(find.text('Harry Potter'), findsOneWidget);
    expect(find.text('Oferty: 1'), findsOneWidget);
  });
}

BooksScreen _booksScreen(ApiService apiService) {
  return BooksScreen(
    apiService: apiService,
    currency: 'PLN',
    savedBookIds: const <String>{},
    onToggleSaved: (_) {},
    onOpenBook: (_) {},
  );
}

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    locale: const Locale('pl'),
    supportedLocales: const [Locale('pl'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppStringsScope(
      strings: const AppStrings('pl'),
      child: Scaffold(body: child),
    ),
  );
}

BookListItem _hobbitWithOffers() {
  return const BookListItem(
    id: 'OL1W',
    title: 'The Hobbit',
    authors: ['J. R. R. Tolkien'],
    genre: 'Fantasy',
    offersCount: 2,
    priceRange: PriceRange(min: 18.20, max: 22.40, currency: 'PLN'),
  );
}

class FakeApiService extends ApiService {
  final List<BookListItem> items;
  String? lastQuery;

  FakeApiService({this.items = const []});

  @override
  Future<BookSearchResponse> searchBooks({
    required String query,
    required String currency,
    int page = 0,
    int size = 20,
  }) async {
    lastQuery = query;
    return BookSearchResponse(
      query: query,
      page: page,
      size: size,
      totalPages: 1,
      totalElements: items.length,
      items: items,
    );
  }
}

class LocalStorageServiceForTest {
  static Future<List<String>> loadBookHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('book_search_history') ?? const <String>[];
  }
}
