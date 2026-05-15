import 'book_list_item.dart';
import 'price_range_dto.dart';

class BookListItemMapper {
  static BookListItem fromJson(Map<String, dynamic> json) {
    final priceRangeJson = json['priceRange'] as Map<String, dynamic>?;

    return BookListItem(
      id: json['id'] as String,
      title: json['title'] as String,
      authors: (json['authors'] as List<dynamic>).cast<String>(),
      coverUrl: json['coverUrl'] as String?,
      genre: json['genre'] as String?,
      offersCount: json['offersCount'] as int? ?? 0,
      priceRange: priceRangeJson == null
          ? null
          : PriceRangeDto(
              min: (priceRangeJson['min'] as num).toDouble(),
              max: (priceRangeJson['max'] as num).toDouble(),
              currency: priceRangeJson['currency'] as String,
            ),
    );
  }
}
