import 'package:financehub/controllers/category_controller.dart';
import 'package:financehub/models/category.dart';

import 'package:financehub/widgets/category_widgets.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CategoryController();
    _controller.addListener(_rebuild);
    _controller.load();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  void _showCategoryForm([CategoryModel? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          CategoryFormSheet(existing: category, controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return CategoryErrorState(
        message: _controller.error!,
        onRetry: _controller.load,
      );
    }

    if (_controller.items.isEmpty) {
      return const CategoryEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88, top: 8),
      children: [
        ..._controller.items.map(
          (category) => CategoryTile(
            category: category,
            onEdit: () => _showCategoryForm(category),
            onDelete: () => _deleteCategory(category),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final success = await _controller.delete(category.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir. Verifique se a categoria está em uso.',
          ),
        ),
      );
    }
  }
}
