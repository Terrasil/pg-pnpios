class PriceRangeDto {
  final double min;
  final double max;
  final String currency;

  const PriceRangeDto({
    required this.min,
    required this.max,
    required this.currency,
  });
}
