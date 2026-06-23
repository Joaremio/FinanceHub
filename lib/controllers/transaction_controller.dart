import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';

export '../repositories/transaction_repository.dart'
    show TransactionFilter, TransactionSort;

class TransactionsController extends ChangeNotifier {
  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;

  TransactionsController({
    TransactionRepository? repository,
    CategoryRepository? categoryRepository,
  }) : _repository = repository ?? TransactionRepository(),
       _categoryRepository = categoryRepository ?? CategoryRepository();

  List<TransactionModel> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? error;
  bool isSaving = false;
  List<CategoryModel> categories = [];

  TransactionFilter filter = TransactionFilter.all;
  TransactionSort sort = TransactionSort.dateDesc;
  String search = '';

  int _page = 0;

  CategoryModel? categoryOf(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
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
      final results = await Future.wait([
        _categoryRepository.fetchAll(),
        _repository.fetchPage(page: 0, filter: filter, sort: sort, search: search),
      ]);
      categories = results[0] as List<CategoryModel>;
      final result = results[1] as List<TransactionModel>;
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

  Future<void> refreshCategories() async {
    categories = await _categoryRepository.fetchAll();
    notifyListeners();
  }

  Future<bool> create(TransactionModel transaction) => _save(
    () => _repository.create(transaction),
  );

  Future<bool> update(TransactionModel transaction) => _save(
    () => _repository.update(transaction),
  );

  Future<bool> delete(String id) => _save(() => _repository.delete(id));

  Future<bool> _save(Future<void> Function() operation) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      await load();
      return true;
    } catch (_) {
      error = 'Não foi possível salvar a transação.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
