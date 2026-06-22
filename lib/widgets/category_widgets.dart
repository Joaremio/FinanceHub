import 'package:financehub/models/category.dart';
import 'package:flutter/material.dart';

import '../controllers/category_controller.dart';

// ─── Tile de categoria na lista ───────────────────────────────────────────────

class CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Ícone da categoria
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIconData(category.icon),
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Botão excluir
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          'Deseja excluir "${category.name}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ─── Seção de título (Entradas / Saídas) ──────────────────────────────────────

class CategorySectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final int count;

  const CategorySectionHeader({
    super.key,
    required this.title,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet de criação/edição ──────────────────────────────────────────

class CategoryFormSheet extends StatefulWidget {
  final CategoryModel? existing; // null = criar, preenchido = editar
  final CategoryController controller;

  const CategoryFormSheet({super.key, this.existing, required this.controller});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late String _type;
  late String _selectedIcon;
  late int _selectedColor;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _type = e?.type ?? 'expense';
    _selectedIcon = e?.icon ?? _kIcons.first.key;
    _selectedColor = e?.colorValue ?? _kColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final category = CategoryModel(
      id: widget.existing?.id ?? widget.controller.generateId(),
      name: name,
      type: _type,
      colorValue: _selectedColor,
      icon: _selectedIcon,
    );

    final success = isEditing
        ? await widget.controller.update(category)
        : await widget.controller.create(category);

    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSaving = widget.controller.isSaving;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            Text(
              isEditing ? 'Editar categoria' : 'Nova categoria',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // Nome
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tipo
            Text(
              'Tipo',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Entrada',
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                    selected: _type == 'income',
                    onTap: () => setState(() => _type = 'income'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Saída',
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                    selected: _type == 'expense',
                    onTap: () => setState(() => _type = 'expense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cor
            Text(
              'Cor',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _selectedColor,
              onChanged: (v) => setState(() => _selectedColor = v),
            ),
            const SizedBox(height: 16),

            // Ícone
            Text(
              'Ícone',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _IconPicker(
              selected: _selectedIcon,
              selectedColor: Color(_selectedColor),
              onChanged: (v) => setState(() => _selectedIcon = v),
            ),
            const SizedBox(height: 24),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Salvar alterações' : 'Criar categoria'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Seletor de cor ───────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kColors.map((colorValue) {
        final isSelected = colorValue == selected;
        return GestureDetector(
          onTap: () => onChanged(colorValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(colorValue).withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Seletor de ícone ─────────────────────────────────────────────────────────

class _IconPicker extends StatelessWidget {
  final String selected;
  final Color selectedColor;
  final ValueChanged<String> onChanged;

  const _IconPicker({
    required this.selected,
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kIcons.map((entry) {
        final isSelected = entry.key == selected;
        return GestureDetector(
          onTap: () => onChanged(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withOpacity(0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: selectedColor, width: 1.5)
                  : null,
            ),
            child: Icon(
              entry.value,
              size: 20,
              color: isSelected ? selectedColor : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Botão de tipo (Entrada/Saída) ────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 56,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma categoria ainda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toque em + para criar a primeira.',
            style: TextStyle(fontSize: 14, color: colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Estado de erro ───────────────────────────────────────────────────────────

class CategoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CategoryErrorState({
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

// ─── Helpers e constantes ─────────────────────────────────────────────────────

IconData categoryIconData(String name) {
  final entry = _kIcons.where((e) => e.key == name).firstOrNull;
  return entry?.value ?? Icons.circle_outlined;
}

const List<int> _kColors = [
  0xFF4CAF50,
  0xFF2196F3,
  0xFF9C27B0,
  0xFFFF5722,
  0xFFFF9800,
  0xFF795548,
  0xFFF44336,
  0xFF00BCD4,
  0xFF3F51B5,
  0xFF607D8B,
  0xFFE91E63,
  0xFFFFEB3B,
  0xFF009688,
  0xFF8BC34A,
  0xFFFF5252,
];

const List<MapEntry<String, IconData>> _kIcons = [
  MapEntry('work', Icons.work_outline),
  MapEntry('laptop', Icons.laptop),
  MapEntry('trending_up', Icons.trending_up),
  MapEntry('restaurant', Icons.restaurant),
  MapEntry('directions_car', Icons.directions_car),
  MapEntry('home', Icons.home_outlined),
  MapEntry('health_and_safety', Icons.health_and_safety_outlined),
  MapEntry('sports_esports', Icons.sports_esports_outlined),
  MapEntry('school', Icons.school_outlined),
  MapEntry('more_horiz', Icons.more_horiz),
  MapEntry('shopping_cart', Icons.shopping_cart_outlined),
  MapEntry('flight', Icons.flight),
  MapEntry('pets', Icons.pets),
  MapEntry('fitness_center', Icons.fitness_center),
  MapEntry('music_note', Icons.music_note),
  MapEntry('savings', Icons.savings_outlined),
  MapEntry('phone', Icons.phone_outlined),
  MapEntry('local_gas_station', Icons.local_gas_station),
];
