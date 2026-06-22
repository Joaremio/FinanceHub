import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../repositories/category_repository.dart';

class CategoryController extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryController({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  // ── Estado público ─────────────────────────────────────────────────────────

  List<CategoryModel> income = [];
  List<CategoryModel> expense = [];
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  // ── Ações ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final all = await _repository.fetchAll();
      income = all.where((c) => c.type == 'income').toList();
      expense = all.where((c) => c.type == 'expense').toList();
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
      isSaving = false;
      notifyListeners();
      return false;
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
      isSaving = false;
      notifyListeners();
      return false;
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

  // Gera um ID simples. Substituir por UUID ou ID do banco futuramente.
  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}
