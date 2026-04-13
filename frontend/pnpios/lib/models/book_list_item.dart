import 'price_range_dto.dart';

class BookListItem {
  final String id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? genre;
  final int offersCount;
  final PriceRangeDto? priceRange;

  const BookListItem({
    required this.id,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.genre,
    required this.offersCount,
    this.priceRange,
  });
}
