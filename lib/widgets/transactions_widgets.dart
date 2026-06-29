import 'package:financehub/controllers/transaction_controller.dart';
import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class TransactionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TransactionSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar transação...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class TransactionFilterBar extends StatelessWidget {
  final TransactionFilter filter;
  final TransactionSort sort;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final ValueChanged<TransactionSort> onSortChanged;

  const TransactionFilterBar({
    super.key,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            selected: filter == TransactionFilter.all,
            onTap: () => onFilterChanged(TransactionFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Entradas',
            selected: filter == TransactionFilter.income,
            onTap: () => onFilterChanged(TransactionFilter.income),
            selectedColor: Colors.green,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Saídas',
            selected: filter == TransactionFilter.expense,
            onTap: () => onFilterChanged(TransactionFilter.expense),
            selectedColor: Colors.red,
          ),
          const Spacer(),
          _SortButton(sort: sort, onChanged: onSortChanged),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = selectedColor ?? colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? activeColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final TransactionSort sort;
  final ValueChanged<TransactionSort> onChanged;

  const _SortButton({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesc = sort == TransactionSort.dateDesc;
    return GestureDetector(
      onTap: () => onChanged(
        isDesc ? TransactionSort.dateAsc : TransactionSort.dateDesc,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDesc ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Data',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionList extends StatelessWidget {
  final List<TransactionModel> items;
  final ScrollController scrollController;
  final TransactionsController controller;
  final bool isLoadingMore;
  final ValueChanged<TransactionModel> onEdit;
  final ValueChanged<String> onDelete;

  const TransactionList({
    super.key,
    required this.items,
    required this.scrollController,
    required this.controller,
    required this.isLoadingMore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonth(items);
    final keys = grouped.keys.toList();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: keys.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == keys.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final monthKey = keys[index];
        final transactions = grouped[monthKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(label: monthKey, transactions: transactions),
            ...transactions.map(
              (t) => TransactionTile(
                transaction: t,
                category: controller.categoryOf(t.categoryId),
                onEdit: () => onEdit(t),
                onDelete: () => onDelete(t.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<TransactionModel>> _groupByMonth(
    List<TransactionModel> list,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (final t in list) {
      map.putIfAbsent(_monthLabel(t.date), () => []).add(t);
    }
    return map;
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final List<TransactionModel> transactions;

  const _MonthHeader({required this.label, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (totalIncome > 0)
            Text(
              '+${_fmt(totalIncome)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (totalIncome > 0 && totalExpense > 0) const SizedBox(width: 6),
          if (totalExpense > 0)
            Text(
              '-${_fmt(totalExpense)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
}

// ─── Item de transação ────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = category?.color ?? Colors.grey;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;
    final sign = isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconData(category?.icon ?? 'more_horiz'),
                    color: catColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category?.name ?? 'Outros',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign R\$ ${transaction.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
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

  void _showDetail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = category?.color ?? Colors.grey;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconData(category?.icon ?? 'more_horiz'),
                    color: catColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        category?.name ?? 'Outros',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              label: 'Valor',
              value:
                  '${isIncome ? '+' : '-'} R\$ ${transaction.amount.toStringAsFixed(2).replaceAll('.', ',')}',
              valueColor: amountColor,
            ),
            _DetailRow(label: 'Tipo', value: isIncome ? 'Entrada' : 'Saída'),
            _DetailRow(
              label: 'Data',
              value:
                  '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}',
            ),
            if (transaction.note != null)
              _DetailRow(label: 'Nota', value: transaction.note!),
            if (transaction.hasLocation)
              _DetailRow(
                label: 'Local',
                value: transaction.locationName ?? 'Local selecionado',
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estados vazios ───────────────────────────────────────────────────────────

class TransactionEmptyState extends StatelessWidget {
  final TransactionFilter filter;
  final String search;

  const TransactionEmptyState({
    super.key,
    required this.filter,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSearch = search.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.receipt_long_outlined,
              size: 56,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? 'Nenhuma transação encontrada'
                  : 'Nenhuma transação ainda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasSearch)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tente buscar por outro termo.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.outlineVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TransactionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TransactionErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

IconData _iconData(String name) {
  const map = {
    'work': Icons.work_outline,
    'laptop': Icons.laptop,
    'trending_up': Icons.trending_up,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home_outlined,
    'health_and_safety': Icons.health_and_safety_outlined,
    'sports_esports': Icons.sports_esports_outlined,
    'school': Icons.school_outlined,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category_outlined,
  };
  return map[name] ?? Icons.circle_outlined;
}
