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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Categorias',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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

    if (_controller.income.isEmpty && _controller.expense.isEmpty) {
      return const CategoryEmptyState();
    }

    return ListView(
      // Adicionamos um padding no final para a lista não ficar escondida atrás do FloatingActionButton
      padding: const EdgeInsets.only(bottom: 88, top: 8),
      children: [
        // Seção de Entradas
        if (_controller.income.isNotEmpty) ...[
          CategorySectionHeader(
            title: 'Entradas',
            color: Colors.green, // Cor que bate com o tema do form
            count: _controller.income.length,
          ),
          ..._controller.income.map(
            (category) => CategoryTile(
              category: category,
              onEdit: () => _showCategoryForm(category),
              onDelete: () => _controller.delete(category.id),
            ),
          ),
        ],

        // Seção de Saídas
        if (_controller.expense.isNotEmpty) ...[
          CategorySectionHeader(
            title: 'Saídas',
            color: Colors.red, // Cor que bate com o tema do form
            count: _controller.expense.length,
          ),
          ..._controller.expense.map(
            (category) => CategoryTile(
              category: category,
              onEdit: () => _showCategoryForm(category),
              onDelete: () => _controller.delete(category.id),
            ),
          ),
        ],
      ],
    );
  }
}
