import 'package:financehub/models/category.dart';

class CategoryRepository {
  final List<CategoryModel> _data = List.from(CategoryModel.defaults);

  Future<List<CategoryModel>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_data);
  }

  Future<void> create(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _data.add(category);
  }

  Future<void> update(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _data.indexWhere((c) => c.id == category.id);
    if (index != -1) _data[index] = category;
  }

  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _data.removeWhere((c) => c.id == id);
  }
}
