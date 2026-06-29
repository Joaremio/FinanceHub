import 'package:financehub/controllers/transaction_controller.dart';
import 'package:financehub/widgets/category_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum DashboardPeriod {
  month,
  year
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final controller = TransactionsController();

  DashboardPeriod selectedPeriod = DashboardPeriod.month;

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final transactions = _filteredTransactions();

        final income = _totalIncome(transactions);
        final expense = _totalExpense(transactions);
        final balance = income - expense;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context),

            const SizedBox(height: 20),

            _buildPeriodFilter(),

            const SizedBox(height: 20),

            _buildSummaryCard(
              context,
              income: income,
              expense: expense,
              balance: balance,
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(
              context,
              title: "Entradas x Saídas",
              subtitle: "Comparativo do período selecionado",
            ),

            const SizedBox(height: 12),

            _buildIncomeExpenseChart(
              context,
              income: income,
              expense: expense,
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(
              context,
              title: "Despesas por categoria",
              subtitle: "Veja onde você mais está gastando",
            ),

            const SizedBox(height: 12),

            CategoryChart(controller: controller,transactions: transactions),

            const SizedBox(height: 24),

            _buildSectionTitle(
              context,
              title: "Últimas transações",
              subtitle: "Movimentações mais recentes",
            ),

            const SizedBox(height: 12),

            _buildRecentTransactions(transactions),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "Acompanhe suas entradas e saídas",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return SegmentedButton<DashboardPeriod>(
      selected: {selectedPeriod},
      onSelectionChanged: (value) {
        setState(() {
          selectedPeriod = value.first;
        });
      },
      segments: const [
        ButtonSegment(
          value: DashboardPeriod.month,
          label: Text("Mês"),
          icon: Icon(Icons.calendar_month_rounded),
        ),
        ButtonSegment(
          value: DashboardPeriod.year,
          label: Text("Ano"),
          icon: Icon(Icons.date_range_rounded),
        )
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required double income,
        required double expense,
        required double balance,
      }) {
    final green = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            green,
            green.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saldo do período",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_upward_rounded,
                  title: "Entradas",
                  value: _formatMoney(income),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_downward_rounded,
                  title: "Saídas",
                  value: _formatMoney(expense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseChart(
      BuildContext context, {
        required double income,
        required double expense,
      }) {
    final maxValue = income > expense ? income : expense;
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.25;

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
        child: SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.18),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const SizedBox.shrink();
                      }

                      return Text(
                        _shortMoney(value),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      String text = "";

                      if (value.toInt() == 0) {
                        text = "Entradas";
                      } else if (value.toInt() == 1) {
                        text = "Saídas";
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: income,
                      width: 42,
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: expense,
                      width: 42,
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, {
        required String title,
        required String subtitle,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List transactions) {
    if (transactions.isEmpty) {
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
                Icons.receipt_long_rounded,
                size: 42,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                "Nenhuma transação encontrada",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Adicione entradas ou saídas para visualizar o dashboard.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final latest = sorted.take(5).toList();

    return Column(
      children: latest.map((transaction) {
        final isExpense = _isExpense(transaction);
        final category = controller.categoryOf(transaction.categoryId);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.15),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor:
              (isExpense ? Colors.red : Colors.green).withOpacity(0.12),
              child: Icon(
                isExpense
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            title: Text(
              category?.name ?? "Sem categoria",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(_formatDate(transaction.date)),
            trailing: Text(
              "${isExpense ? '-' : '+'} ${_formatMoney(transaction.amount.abs())}",
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List _filteredTransactions() {
    final now = DateTime.now();

    return controller.items.where((transaction) {
      final date = transaction.date;

      switch (selectedPeriod) {
        case DashboardPeriod.month:
          return date.month == now.month && date.year == now.year;

        case DashboardPeriod.year:
          return date.year == now.year;
      }
    }).toList();
  }

  double _totalIncome(List transactions) {
    return transactions.where(_isIncome).fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount.abs(),
    );
  }

  double _totalExpense(List transactions) {
    return transactions.where(_isExpense).fold<double>(
      0,
          (sum, transaction) => sum + transaction.amount.abs(),
    );
  }

  bool _isIncome(dynamic transaction) {
    return _transactionType(transaction) == "income";
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

  String _shortMoney(double value) {
    if (value >= 1000) {
      return "R\$ ${(value / 1000).toStringAsFixed(1)}k";
    }

    return "R\$ ${value.toStringAsFixed(0)}";
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return "$day/$month/$year";
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}