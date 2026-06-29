import 'package:financehub/controllers/transaction_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryChart extends StatelessWidget {
  final TransactionsController controller;
  final List transactions;

  const CategoryChart({
    super.key,
    required this.controller,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final values = _groupExpensesByCategory();

    if (values.isEmpty) {
      return _buildEmptyState(context);
    }

    final total = values.values.fold<double>(
      0,
          (sum, value) => sum + value,
    );

    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 58,
                      startDegreeOffset: -90,
                      sections: entries.map((entry) {
                        final category = controller.categoryOf(entry.key);
                        final color = category?.color ?? Colors.grey;

                        final percent = total == 0
                            ? 0
                            : (entry.value / total) * 100;

                        return PieChartSectionData(
                          value: entry.value,
                          color: color,
                          radius: 82,
                          title: "${percent.toStringAsFixed(0)}%",
                          titleStyle: TextStyle(
                            color: _textColorFor(color),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMoney(total),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildLegend(context, entries),
          ],
        ),
      ),
    );
  }

  Map<String, double> _groupExpensesByCategory() {
    final values = <String, double>{};

    for (final transaction in transactions) {
      if (!_isExpense(transaction)) continue;

      values[transaction.categoryId] =
          (values[transaction.categoryId] ?? 0) + transaction.amount.abs();
    }

    return values;
  }

  Widget _buildLegend(
      BuildContext context,
      List<MapEntry<String, double>> entries,
      ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((entry) {
        final category = controller.categoryOf(entry.key);
        final color = category?.color ?? Colors.grey;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 5,
                backgroundColor: color,
              ),
              const SizedBox(width: 6),
              Text(
                category?.name ?? "Sem categoria",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 6),
              Text(
                _formatMoney(entry.value),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_rounded,
              size: 42,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              "Nenhuma despesa encontrada",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Adicione saídas neste período para visualizar o gráfico.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isExpense(dynamic transaction) {
    return _transactionType(transaction) == "expense";
  }

  String _transactionType(dynamic transaction) {
    return transaction.type.toString().split('.').last.toLowerCase();
  }

  String _formatMoney(double value) {
    return "R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  Color _textColorFor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}