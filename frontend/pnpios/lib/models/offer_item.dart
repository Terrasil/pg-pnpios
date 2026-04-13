import 'money_dto.dart';

class OfferItem {
  final String id;
  final String source;
  final String offerUrl;
  final MoneyDto originalPrice;
  final MoneyDto convertedPrice;

  const OfferItem({
    required this.id,
    required this.source,
    required this.offerUrl,
    required this.originalPrice,
    required this.convertedPrice,
  });
}
