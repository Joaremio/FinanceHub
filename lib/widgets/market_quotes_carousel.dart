import 'package:flutter/material.dart';

import '../models/market_quote.dart';
import '../services/market_quotes_service.dart';

class MarketQuotesCarousel extends StatefulWidget {
  const MarketQuotesCarousel({super.key, MarketQuotesService? service})
    : _service = service;

  final MarketQuotesService? _service;

  @override
  State<MarketQuotesCarousel> createState() => _MarketQuotesCarouselState();
}

class _MarketQuotesCarouselState extends State<MarketQuotesCarousel>
    with SingleTickerProviderStateMixin {
  late final MarketQuotesService _service;
  late final AnimationController _controller;
  late Future<List<MarketQuote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? MarketQuotesService();
    _quotesFuture = _service.fetchQuotes();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MarketQuote>>(
      future: _quotesFuture,
      builder: (context, snapshot) {
        final quotes = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 42,
            child: Center(child: LinearProgressIndicator()),
          );
        }

        if (quotes.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 42,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = -constraints.maxWidth * _controller.value;
                  return OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(offset, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 4; i++) ...[
                            _TickerRow(quotes: quotes),
                            const SizedBox(width: 28),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TickerRow extends StatelessWidget {
  const _TickerRow({required this.quotes});

  final List<MarketQuote> quotes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: quotes.map((quote) => _TickerItem(quote: quote)).toList(),
    );
  }
}

class _TickerItem extends StatelessWidget {
  const _TickerItem({required this.quote});

  final MarketQuote quote;

  @override
  Widget build(BuildContext context) {
    final changeColor = quote.isPositive ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${quote.name} ${_formatMoney(quote.value)}',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Text(
            '${quote.isPositive ? '+' : ''}${quote.changePercent.toStringAsFixed(2).replaceAll('.', ',')}%',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: changeColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
