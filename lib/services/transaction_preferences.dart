import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/transaction_repository.dart';

class TransactionPreferences {
  static const _filterKey = 'transactions.filter';
  static const _sortKey = 'transactions.sort';

  Future<TransactionFilter> loadFilter() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getString(_filterKey);
    return TransactionFilter.values.firstWhere(
      (value) => value.name == savedValue,
      orElse: () => TransactionFilter.all,
    );
  }

  Future<TransactionSort> loadSort() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getString(_sortKey);
    return TransactionSort.values.firstWhere(
      (value) => value.name == savedValue,
      orElse: () => TransactionSort.dateDesc,
    );
  }

  Future<void> saveFilter(TransactionFilter filter) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_filterKey, filter.name);
  }

  Future<void> saveSort(TransactionSort sort) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sortKey, sort.name);
  }
}
