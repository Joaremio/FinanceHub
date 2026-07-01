import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../repositories/category_repository.dart';

class CategoryController extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryController({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  List<CategoryModel> items = [];
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      items = await _repository.fetchAll();
    } catch (_) {
      error = 'Não foi possível carregar as categorias.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(CategoryModel category) async {
    isSaving = true;
    notifyListeners();

    try {
      await _repository.create(category);
      await load();
      return true;
    } catch (_) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> update(CategoryModel category) async {
    isSaving = true;
    notifyListeners();

    try {
      await _repository.update(category);
      await load();
      return true;
    } catch (_) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  String generateId() => '';
}
