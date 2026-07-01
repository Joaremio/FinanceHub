import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_quote.dart';

class MarketQuotesService {
  MarketQuotesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<MarketQuote>> fetchQuotes() async {
    final quotes = await _fetchCurrencyQuotes();
    if (quotes.isEmpty) {
      throw StateError('Nenhuma cotação disponível.');
    }
    return quotes;
  }

  Future<List<MarketQuote>> _fetchCurrencyQuotes() async {
    try {
      final uri = Uri.https(
        'economia.awesomeapi.com.br',
        '/json/last/USD-BRL,EUR-BRL,BTC-BRL',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        _currencyFromJson(body['USDBRL'], 'Dólar', 'USD'),
        _currencyFromJson(body['EURBRL'], 'Euro', 'EUR'),
        _currencyFromJson(body['BTCBRL'], 'Bitcoin', 'BTC'),
      ].whereType<MarketQuote>().toList();
    } catch (_) {
      return [];
    }
  }

  MarketQuote? _currencyFromJson(dynamic value, String name, String symbol) {
    if (value is! Map<String, dynamic>) return null;

    final price = double.tryParse(value['bid']?.toString() ?? '');
    final changePercent = double.tryParse(value['pctChange']?.toString() ?? '');
    if (price == null || changePercent == null) return null;

    return MarketQuote(
      symbol: symbol,
      name: name,
      value: price,
      changePercent: changePercent,
      updatedAt: DateTime.tryParse(value['create_date']?.toString() ?? ''),
    );
  }
}
