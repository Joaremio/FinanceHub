class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.name,
    required this.value,
    required this.changePercent,
    required this.updatedAt,
  });

  final String symbol;
  final String name;
  final double value;
  final double changePercent;
  final DateTime? updatedAt;

  bool get isPositive => changePercent >= 0;
}
