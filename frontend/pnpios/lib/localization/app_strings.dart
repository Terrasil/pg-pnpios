import 'dart:convert';

import 'package:flutter/services.dart';
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
    return oldWidget.strings.languageCode != strings.languageCode || oldWidget.strings._values != strings._values;
  }
}

class AppStringsLoader {
  static const List<String> supportedLanguageCodes = <String>['pl', 'en'];

  static Future<AppStrings> load(String languageCode) async {
    final normalized = _normalizeLanguageCode(languageCode);
    final data = await _loadJsonMap(normalized);
    return AppStrings._(normalized, data);
  }

  static String _normalizeLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    return supportedLanguageCodes.contains(normalized) ? normalized : 'en';
  }

  static Future<Map<String, dynamic>> _loadJsonMap(String languageCode) async {
    final candidates = <String>[
      'assets/i18n/$languageCode.json',
      if (languageCode != 'en') 'assets/i18n/en.json',
    ];

    for (final path in candidates) {
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Try next candidate.
      }
    }

    throw FlutterError('Could not load localization JSON for language: $languageCode');
  }
}

class AppStrings {
  final String languageCode;
  final Map<String, dynamic> _values;

  const AppStrings._(this.languageCode, this._values);

  String get appTitle => _text('appTitle');

  String get navBooks => _text('navBooks');
  String get navAuthors => _text('navAuthors');
  String get navCurrencies => _text('navCurrencies');
  String get navSaved => _text('navSaved');
  String get navSettings => _text('navSettings');

  String get booksSearchTitle => _text('booksSearchTitle');
  String get authorsSearchTitle => _text('authorsSearchTitle');
  String get currenciesTitle => _text('currenciesTitle');
  String get savedTitle => _text('savedTitle');
  String get settingsTitle => _text('settingsTitle');

  String get searchButton => _text('searchButton');
  String get booksSearchHint => _text('booksSearchHint');
  String get authorsSearchHint => _text('authorsSearchHint');

  String get noInitialResultsTitle => _text('noInitialResultsTitle');
  String get noInitialBooksMessage => _text('noInitialBooksMessage');
  String get noInitialAuthorsMessage => _text('noInitialAuthorsMessage');

  String get noResultsTitle => _text('noResultsTitle');
  String get noBooksResultsMessage => _text('noBooksResultsMessage');
  String get noAuthorsResultsMessage => _text('noAuthorsResultsMessage');

  String get noCurrenciesTitle => _text('noCurrenciesTitle');
  String get noCurrenciesMessage => _text('noCurrenciesMessage');

  String get currentCurrencyLabel => _text('currentCurrencyLabel');
  String get rateLabel => _text('rateLabel');
  String get dateLabel => _text('dateLabel');
  String get missingCode => _text('missingCode');
  String get missingName => _text('missingName');

  String get savedFilterHint => _text('savedFilterHint');
  String get booksTab => _text('booksTab');
  String get authorsTab => _text('authorsTab');
  String get noSavedBooksTitle => _text('noSavedBooksTitle');
  String get noSavedBooksMessage => _text('noSavedBooksMessage');
  String get noSavedAuthorsTitle => _text('noSavedAuthorsTitle');
  String get noSavedAuthorsMessage => _text('noSavedAuthorsMessage');
  String get refreshSavedButton => _text('refreshSavedButton');
  String get syncingSavedData => _text('syncingSavedData');

  String get languageLabel => _text('languageLabel');
  String get textSizeLabel => _text('textSizeLabel');
  String get highContrastLabel => _text('highContrastLabel');
  String get polish => _text('polish');
  String get english => _text('english');

  String get noDataTitle => _text('noDataTitle');
  String get noBookDetailsMessage => _text('noBookDetailsMessage');
  String get noAuthorDetailsMessage => _text('noAuthorDetailsMessage');
  String get missingBookDescription => _text('missingBookDescription');
  String get missingAuthorDescription => _text('missingAuthorDescription');
  String get offersTitle => _text('offersTitle');
  String get noOffersTitle => _text('noOffersTitle');
  String get noOffersMessage => _text('noOffersMessage');
  String get authorBooksTitle => _text('authorBooksTitle');
  String get noAuthorBooksTitle => _text('noAuthorBooksTitle');
  String get noAuthorBooksMessage => _text('noAuthorBooksMessage');

  String get copyOfferUrlTooltip => _text('copyOfferUrlTooltip');
  String get openOfferTooltip => _text('openOfferTooltip');
  String get offerUrlCopied => _text('offerUrlCopied');
  String get invalidOfferUrl => _text('invalidOfferUrl');
  String get failedOpenUrl => _text('failedOpenUrl');

  String get loadErrorTitle => _text('loadErrorTitle');
  String get retryButton => _text('retryButton');
  String get closeButton => _text('closeButton');

  String get noAuthor => _text('noAuthor');

  String valueOrDash(String? value) => (value == null || value.trim().isEmpty) ? '-' : value;

  String authorLabel(String value) => _format('authorLabel', {'value': value});
  String languageValue(String value) => _format('languageValue', {'value': value});
  String publisherValue(String value) => _format('publisherValue', {'value': value});
  String yearValue(String value) => _format('yearValue', {'value': value});
  String birthDateValue(String value) => _format('birthDateValue', {'value': value});
  String deathDateValue(String value) => _format('deathDateValue', {'value': value});
  String genreValue(String value) => _format('genreValue', {'value': value});
  String offersCount(int count) => _format('offersCount', {'count': count.toString()});
  String booksCount(int count) => _format('booksCount', {'count': count.toString()});
  String simpleBooksCount(int count) => _format('simpleBooksCount', {'count': count.toString()});
  String priceValue(String value) => _format('priceValue', {'value': value});
  String originalPriceValue(String value) => _format('originalPriceValue', {'value': value});
  String convertedPriceValue(String value) => _format('convertedPriceValue', {'value': value});
  String availabilityValue(String value) => _format('availabilityValue', {'value': value});

  String _text(String key) {
    final value = _values[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return key;
  }

  String _format(String key, Map<String, String> params) {
    var template = _text(key);
    params.forEach((placeholder, value) {
      template = template.replaceAll('{$placeholder}', value);
    });
    return template;
  }
}

extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStringsScope.of(this);
}
