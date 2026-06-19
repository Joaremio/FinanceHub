import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

export '../repositories/transaction_repository.dart'
    show TransactionFilter, TransactionSort;

class TransactionsController extends ChangeNotifier {
  final TransactionRepository _repository;
  final List<CategoryModel> _categories;

  TransactionsController({
    TransactionRepository? repository,
    List<CategoryModel>? categories,
  }) : _repository = repository ?? TransactionRepository(),
       _categories = categories ?? CategoryModel.defaults;

  List<TransactionModel> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? error;

  TransactionFilter filter = TransactionFilter.all;
  TransactionSort sort = TransactionSort.dateDesc;
  String search = '';

  int _page = 0;

  CategoryModel? categoryOf(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _page = 0;
    hasMore = true;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchPage(
        page: 0,
        filter: filter,
        sort: sort,
        search: search,
      );
      items = result;
      hasMore = result.length == TransactionRepository.pageSize;
    } catch (_) {
      error = 'Não foi possível carregar as transações.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      final result = await _repository.fetchPage(
        page: _page,
        filter: filter,
        sort: sort,
        search: search,
      );
      items = [...items, ...result];
      hasMore = result.length == TransactionRepository.pageSize;
    } catch (_) {
      _page--;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void setFilter(TransactionFilter value) {
    if (filter == value) return;
    filter = value;
    load();
  }

  void setSort(TransactionSort value) {
    if (sort == value) return;
    sort = value;
    load();
  }

  void setSearch(String value) {
    if (search == value) return;
    search = value;
    load();
  }
}
