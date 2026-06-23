import 'dart:async';

import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/transaction_preferences.dart';

export '../repositories/transaction_repository.dart'
    show TransactionFilter, TransactionSort;

class TransactionsController extends ChangeNotifier {
  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;
  final TransactionPreferences _preferences;

  TransactionsController({
    TransactionRepository? repository,
    CategoryRepository? categoryRepository,
    TransactionPreferences? preferences,
  }) : _repository = repository ?? TransactionRepository(),
       _categoryRepository = categoryRepository ?? CategoryRepository(),
       _preferences = preferences ?? TransactionPreferences();

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

  TransactionCursor? _cursor;
  Timer? _searchDebounce;
  bool _preferencesLoaded = false;
  int _loadGeneration = 0;

  CategoryModel? categoryOf(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _cursor = null;
    hasMore = true;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _restorePreferences();
      final results = await Future.wait([
        _categoryRepository.fetchAll(),
        _repository.fetchPage(filter: filter, sort: sort, search: search),
      ]);
      if (generation != _loadGeneration) return;
      categories = results[0] as List<CategoryModel>;
      final page = results[1] as TransactionPage;
      items = page.items;
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (_) {
      if (generation != _loadGeneration) return;
      error = 'Não foi possível carregar as transações.';
    } finally {
      if (generation != _loadGeneration) return;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    final generation = _loadGeneration;
    isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchPage(
        filter: filter,
        sort: sort,
        search: search,
        after: _cursor,
      );
      if (generation != _loadGeneration) return;
      items = [...items, ...page.items];
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (_) {
      if (generation == _loadGeneration) {
        error = 'Não foi possível carregar mais transações.';
      }
    } finally {
      if (generation != _loadGeneration) return;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void setFilter(TransactionFilter value) {
    if (filter == value) return;
    filter = value;
    unawaited(_preferences.saveFilter(value));
    load();
  }

  void setSort(TransactionSort value) {
    if (sort == value) return;
    sort = value;
    unawaited(_preferences.saveSort(value));
    load();
  }

  void setSearch(String value) {
    if (search == value) return;
    search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<void> _restorePreferences() async {
    if (_preferencesLoaded) return;
    final values = await Future.wait([
      _preferences.loadFilter(),
      _preferences.loadSort(),
    ]);
    filter = values[0] as TransactionFilter;
    sort = values[1] as TransactionSort;
    _preferencesLoaded = true;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
