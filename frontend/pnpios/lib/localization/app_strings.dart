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
    return oldWidget.strings.languageCode != strings.languageCode ||
        oldWidget.strings._values != strings._values;
  }
}

class AppStrings {
  final String languageCode;
  final Map<String, dynamic> _values;

  const AppStrings._(this.languageCode, this._values);

  static Future<AppStrings> load(String languageCode) async {
    final normalized = languageCode.toLowerCase();
    final assetPath = 'assets/i18n/$normalized.json';

    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;

    return AppStrings._(normalized, map);
  }

  String _t(String key) {
    final value = _values[key];
    if (value is String) {
      return value;
    }
    return key;
  }

  String _tf(String key, Map<String, String> params) {
    String value = _t(key);
    params.forEach((paramKey, paramValue) {
      value = value.replaceAll('{$paramKey}', paramValue);
    });
    return value;
  }

  String get appTitle => _t('appTitle');

  String get navBooks => _t('navBooks');
  String get navAuthors => _t('navAuthors');
  String get navCurrencies => _t('navCurrencies');
  String get navSaved => _t('navSaved');
  String get navSettings => _t('navSettings');

  String get booksSearchTitle => _t('booksSearchTitle');
  String get authorsSearchTitle => _t('authorsSearchTitle');
  String get currenciesTitle => _t('currenciesTitle');
  String get savedTitle => _t('savedTitle');
  String get settingsTitle => _t('settingsTitle');

  String get searchButton => _t('searchButton');
  String get booksSearchHint => _t('booksSearchHint');
  String get authorsSearchHint => _t('authorsSearchHint');
  String get offersSearchHint => _t('offersSearchHint');

  String get noInitialResultsTitle => _t('noInitialResultsTitle');
  String get noInitialBooksMessage => _t('noInitialBooksMessage');
  String get noInitialAuthorsMessage => _t('noInitialAuthorsMessage');

  String get noResultsTitle => _t('noResultsTitle');
  String get noBooksResultsMessage => _t('noBooksResultsMessage');
  String get noAuthorsResultsMessage => _t('noAuthorsResultsMessage');

  String get noCurrenciesTitle => _t('noCurrenciesTitle');
  String get noCurrenciesMessage => _t('noCurrenciesMessage');

  String get currentCurrencyLabel => _t('currentCurrencyLabel');
  String get rateLabel => _t('rateLabel');
  String get dateLabel => _t('dateLabel');
  String get missingCode => _t('missingCode');
  String get missingName => _t('missingName');

  String get savedFilterHint => _t('savedFilterHint');
  String get booksTab => _t('booksTab');
  String get authorsTab => _t('authorsTab');
  String get noSavedBooksTitle => _t('noSavedBooksTitle');
  String get noSavedBooksMessage => _t('noSavedBooksMessage');
  String get noSavedAuthorsTitle => _t('noSavedAuthorsTitle');
  String get noSavedAuthorsMessage => _t('noSavedAuthorsMessage');
  String get refreshSavedButton => _t('refreshSavedButton');
  String get syncingSavedData => _t('syncingSavedData');

  String get languageLabel => _t('languageLabel');
  String get textSizeLabel => _t('textSizeLabel');
  String get highContrastLabel => _t('highContrastLabel');
  String get polish => _t('polish');
  String get english => _t('english');

  String get noDataTitle => _t('noDataTitle');
  String get noBookDetailsMessage => _t('noBookDetailsMessage');
  String get noAuthorDetailsMessage => _t('noAuthorDetailsMessage');
  String get missingBookDescription => _t('missingBookDescription');
  String get missingAuthorDescription => _t('missingAuthorDescription');
  String get offersTitle => _t('offersTitle');
  String get noOffersTitle => _t('noOffersTitle');
  String get noOffersMessage => _t('noOffersMessage');
  String get authorBooksTitle => _t('authorBooksTitle');
  String get noAuthorBooksTitle => _t('noAuthorBooksTitle');
  String get noAuthorBooksMessage => _t('noAuthorBooksMessage');

  String get copyOfferUrlTooltip => _t('copyOfferUrlTooltip');
  String get openOfferTooltip => _t('openOfferTooltip');
  String get offerUrlCopied => _t('offerUrlCopied');
  String get invalidOfferUrl => _t('invalidOfferUrl');
  String get failedOpenUrl => _t('failedOpenUrl');

  String get loadErrorTitle => _t('loadErrorTitle');
  String get retryButton => _t('retryButton');
  String get closeButton => _t('closeButton');
  String get filterButton => _t('filterButton');
  String get applyButton => _t('applyButton');
  String get clearButton => _t('clearButton');
  String get historyButton => _t('historyButton');
  String get noHistoryMessage => _t('noHistoryMessage');
  String get clearHistoryButton => _t('clearHistoryButton');
  String get sortLabel => _t('sortLabel');
  String get sourceFilterLabel => _t('sourceFilterLabel');
  String get allSourcesOption => _t('allSourcesOption');
  String get sortTitleAsc => _t('sortTitleAsc');
  String get sortTitleDesc => _t('sortTitleDesc');
  String get sortPriceAsc => _t('sortPriceAsc');
  String get sortPriceDesc => _t('sortPriceDesc');
  String get sortOffersAsc => _t('sortOffersAsc');
  String get sortOffersDesc => _t('sortOffersDesc');
  String get sortNameAsc => _t('sortNameAsc');
  String get sortNameDesc => _t('sortNameDesc');
  String get sortBirthAsc => _t('sortBirthAsc');
  String get sortBirthDesc => _t('sortBirthDesc');
  String get sortBooksAsc => _t('sortBooksAsc');
  String get sortBooksDesc => _t('sortBooksDesc');
  String get sortSourceAsc => _t('sortSourceAsc');

  String get noAuthor => _t('noAuthor');

  String valueOrDash(String? value) {
    return (value == null || value.trim().isEmpty) ? '-' : value;
  }

  String authorLabel(String value) => _tf('authorLabel', {'value': value});
  String languageValue(String value) => _tf('languageValue', {'value': value});
  String publisherValue(String value) => _tf('publisherValue', {'value': value});
  String yearValue(String value) => _tf('yearValue', {'value': value});
  String birthDateValue(String value) => _tf('birthDateValue', {'value': value});
  String deathDateValue(String value) => _tf('deathDateValue', {'value': value});
  String genreValue(String value) => _tf('genreValue', {'value': value});
  String offersCount(int count) => _tf('offersCount', {'count': count.toString()});
  String booksCount(int count) => _tf('booksCount', {'count': count.toString()});
  String simpleBooksCount(int count) => _tf('simpleBooksCount', {'count': count.toString()});
  String priceValue(String value) => _tf('priceValue', {'value': value});
  String originalPriceValue(String value) => _tf('originalPriceValue', {'value': value});
  String convertedPriceValue(String value) => _tf('convertedPriceValue', {'value': value});
  String availabilityValue(String value) => _tf('availabilityValue', {'value': value});
}

extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStringsScope.of(this);
}
