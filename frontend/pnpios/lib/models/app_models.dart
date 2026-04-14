class PriceRange {
  final double min;
  final double max;
  final String currency;

  const PriceRange({
    required this.min,
    required this.max,
    required this.currency,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? '',
    );
  }
}

class Money {
  final double amount;
  final String currency;

  const Money({required this.amount, required this.currency});

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? '',
    );
  }
}

class AuthorShort {
  final String id;
  final String name;

  const AuthorShort({required this.id, required this.name});

  factory AuthorShort.fromJson(Map<String, dynamic> json) {
    return AuthorShort(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }
}

class OfferItem {
  final String id;
  final String source;
  final String sourceType;
  final String offerUrl;
  final String availability;
  final Money originalPrice;
  final Money convertedPrice;
  final double exchangeRate;
  final String lastUpdated;

  const OfferItem({
    required this.id,
    required this.source,
    required this.sourceType,
    required this.offerUrl,
    required this.availability,
    required this.originalPrice,
    required this.convertedPrice,
    required this.exchangeRate,
    required this.lastUpdated,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) {
    return OfferItem(
      id: (json['id'] as String?) ?? '',
      source: (json['source'] as String?) ?? '',
      sourceType: (json['sourceType'] as String?) ?? '',
      offerUrl: (json['offerUrl'] as String?) ?? '',
      availability: (json['availability'] as String?) ?? 'UNKNOWN',
      originalPrice: Money.fromJson(
        (json['originalPrice'] as Map<String, dynamic>?) ?? const {},
      ),
      convertedPrice: Money.fromJson(
        (json['convertedPrice'] as Map<String, dynamic>?) ?? const {},
      ),
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 0,
      lastUpdated: (json['lastUpdated'] as String?) ?? '',
    );
  }
}

class BookListItem {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? coverUrl;
  final String? language;
  final String? genre;
  final String? isbn13;
  final int offersCount;
  final PriceRange? priceRange;

  const BookListItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.authors,
    this.coverUrl,
    this.language,
    this.genre,
    this.isbn13,
    required this.offersCount,
    this.priceRange,
  });

  factory BookListItem.fromJson(Map<String, dynamic> json) {
    final priceRangeJson = json['priceRange'] as Map<String, dynamic>?;
    return BookListItem(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      authors: ((json['authors'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      coverUrl: json['coverUrl'] as String?,
      language: json['language'] as String?,
      genre: json['genre'] as String?,
      isbn13: json['isbn13'] as String?,
      offersCount: (json['offersCount'] as num?)?.toInt() ?? 0,
      priceRange: priceRangeJson == null ? null : PriceRange.fromJson(priceRangeJson),
    );
  }
}

class BookDetails {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final List<AuthorShort> authors;
  final String? coverUrl;
  final String? publisher;
  final int? publishedYear;
  final String? language;
  final int? pageCount;
  final List<String> genres;
  final String? isbn10;
  final String? isbn13;
  final List<OfferItem> offers;

  const BookDetails({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.authors,
    this.coverUrl,
    this.publisher,
    this.publishedYear,
    this.language,
    this.pageCount,
    required this.genres,
    this.isbn10,
    this.isbn13,
    required this.offers,
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    return BookDetails(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      authors: ((json['authors'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AuthorShort.fromJson)
          .toList(),
      coverUrl: json['coverUrl'] as String?,
      publisher: json['publisher'] as String?,
      publishedYear: (json['publishedYear'] as num?)?.toInt(),
      language: json['language'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
      genres: ((json['genres'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      isbn10: json['isbn10'] as String?,
      isbn13: json['isbn13'] as String?,
      offers: ((json['offers'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OfferItem.fromJson)
          .toList(),
    );
  }
}

class AuthorSearchItem {
  final String id;
  final String name;
  final int? birthYear;
  final int? deathYear;
  final String? photoUrl;
  final int booksCount;

  const AuthorSearchItem({
    required this.id,
    required this.name,
    this.birthYear,
    this.deathYear,
    this.photoUrl,
    required this.booksCount,
  });

  factory AuthorSearchItem.fromJson(Map<String, dynamic> json) {
    return AuthorSearchItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      birthYear: (json['birthYear'] as num?)?.toInt(),
      deathYear: (json['deathYear'] as num?)?.toInt(),
      photoUrl: json['photoUrl'] as String?,
      booksCount: (json['booksCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AuthorDetails {
  final String id;
  final String name;
  final int? birthYear;
  final int? deathYear;
  final String? biography;
  final String? photoUrl;
  final List<BookListItem> books;

  const AuthorDetails({
    required this.id,
    required this.name,
    this.birthYear,
    this.deathYear,
    this.biography,
    this.photoUrl,
    required this.books,
  });

  factory AuthorDetails.fromJson(Map<String, dynamic> json) {
    return AuthorDetails(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      birthYear: (json['birthYear'] as num?)?.toInt(),
      deathYear: (json['deathYear'] as num?)?.toInt(),
      biography: json['biography'] as String?,
      photoUrl: json['photoUrl'] as String?,
      books: ((json['books'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookListItem.fromJson)
          .toList(),
    );
  }
}

class CurrencyRateItem {
  final String code;
  final String name;
  final double rate;
  final String rateDate;

  const CurrencyRateItem({
    required this.code,
    required this.name,
    required this.rate,
    required this.rateDate,
  });

  factory CurrencyRateItem.fromJson(Map<String, dynamic> json) {
    return CurrencyRateItem(
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      rateDate: (json['rateDate'] as String?) ?? '',
    );
  }
}

class BookSearchResponse {
  final String query;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final List<BookListItem> items;

  const BookSearchResponse({
    required this.query,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.items,
  });

  factory BookSearchResponse.fromJson(Map<String, dynamic> json) {
    return BookSearchResponse(
      query: (json['query'] as String?) ?? '',
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookListItem.fromJson)
          .toList(),
    );
  }
}

class AuthorSearchResponse {
  final String query;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final List<AuthorSearchItem> items;

  const AuthorSearchResponse({
    required this.query,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.items,
  });

  factory AuthorSearchResponse.fromJson(Map<String, dynamic> json) {
    return AuthorSearchResponse(
      query: (json['query'] as String?) ?? '',
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AuthorSearchItem.fromJson)
          .toList(),
    );
  }
}

class CurrencyListResponse {
  final String base;
  final List<CurrencyRateItem> items;

  const CurrencyListResponse({required this.base, required this.items});

  factory CurrencyListResponse.fromJson(Map<String, dynamic> json) {
    return CurrencyListResponse(
      base: (json['base'] as String?) ?? '',
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CurrencyRateItem.fromJson)
          .toList(),
    );
  }
}
