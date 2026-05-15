import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/app_models.dart';

void main() {
  group('BookListItem.fromJson', () {
    test('maps price range and optional fields from backend response', () {
      final item = BookListItem.fromJson({
        'id': 'OL1W',
        'title': 'The Hobbit',
        'subtitle': 'There and Back Again',
        'authors': ['J. R. R. Tolkien'],
        'coverUrl': 'https://example.com/cover.jpg',
        'language': 'eng',
        'genre': 'Fantasy',
        'isbn13': '9780345339683',
        'offersCount': 2,
        'priceRange': {
          'min': 18.20,
          'max': 22.40,
          'currency': 'PLN',
        },
      });

      expect(item.id, 'OL1W');
      expect(item.title, 'The Hobbit');
      expect(item.authors, ['J. R. R. Tolkien']);
      expect(item.offersCount, 2);
      expect(item.priceRange?.min, 18.20);
      expect(item.priceRange?.max, 22.40);
      expect(item.priceRange?.currency, 'PLN');
    });

    test('uses safe defaults when backend omits optional data', () {
      final item = BookListItem.fromJson({
        'id': 'OL2W',
        'title': 'Unknown book',
      });

      expect(item.id, 'OL2W');
      expect(item.authors, isEmpty);
      expect(item.offersCount, 0);
      expect(item.priceRange, isNull);
      expect(item.genre, isNull);
    });
  });

  group('OfferItem.fromJson', () {
    test('marks offer as priced only when converted price is present and positive', () {
      final priced = OfferItem.fromJson({
        'id': 'offer-1',
        'source': 'AbeBooks',
        'sourceType': 'Marketplace',
        'offerUrl': 'https://example.com/offer',
        'availability': 'AVAILABLE',
        'originalPrice': {'amount': 5.00, 'currency': 'USD'},
        'convertedPrice': {'amount': 18.20, 'currency': 'PLN'},
        'exchangeRate': 3.64,
        'lastUpdated': '2026-05-15T12:00:00Z',
      });
      final notPriced = OfferItem.fromJson({
        'id': 'offer-2',
        'source': 'AbeBooks',
        'sourceType': 'Marketplace',
        'offerUrl': 'https://example.com/offer-2',
        'availability': 'UNKNOWN',
      });

      expect(priced.hasPrice, isTrue);
      expect(priced.convertedPrice?.amount, 18.20);
      expect(notPriced.hasPrice, isFalse);
    });
  });
}
