import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/transaction_controller.dart';
import '../models/category.dart';
import '../models/transaction_model.dart';
import '../pages/location_picker_page.dart';

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.controller,
    this.existing,
  });

  final TransactionsController controller;
  final TransactionModel? existing;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _type;
  late DateTime _date;
  String? _categoryId;
  TransactionLocationSelection? _selectedLocation;
  String? _validationError;

  bool get _isEditing => widget.existing != null;

  List<CategoryModel> get _availableCategories => widget.controller.categories;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing == null
          ? ''
          : existing.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? 'expense';
    _date = existing?.date ?? DateTime.now();
    _categoryId = existing?.categoryId;
    if (existing != null && existing.hasLocation) {
      _selectedLocation = TransactionLocationSelection(
        point: LatLng(existing.locationLatitude!, existing.locationLongitude!),
        label: existing.locationName ?? 'Local selecionado no mapa',
        address: existing.locationAddress,
      );
    }
    if (!_availableCategories.any((category) => category.id == _categoryId)) {
      _categoryId = _availableCategories.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setType(String value) {
    setState(() {
      _type = value;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickLocation() async {
    final selection = await Navigator.push<TransactionLocationSelection>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerPage(initialSelection: _selectedLocation),
      ),
    );
    if (selection != null && mounted) {
      setState(() => _selectedLocation = selection);
    }
  }

  void _clearLocation() {
    setState(() => _selectedLocation = null);
  }

  Widget _buildLocationTile() {
    final selected = _selectedLocation;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected == null
            ? Icons.add_location_alt_outlined
            : Icons.location_on_outlined,
      ),
      title: Text(selected?.label ?? 'Adicionar local (opcional)'),
      subtitle: Text(
        selected?.address ??
            (selected == null
                ? 'Escolha no mapa, pesquise ou use o GPS'
                : '${selected.point.latitude.toStringAsFixed(5)}, ${selected.point.longitude.toStringAsFixed(5)}'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selected == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              onPressed: _clearLocation,
              icon: const Icon(Icons.close),
              tooltip: 'Remover local',
            ),
      onTap: _pickLocation,
    );
  }

  Future<void> _submit() async {
    final rawAmount = _amountController.text.trim();
    final normalizedAmount = rawAmount.contains(',')
        ? rawAmount.replaceAll('.', '').replaceAll(',', '.')
        : rawAmount;
    final amount = double.tryParse(normalizedAmount);
    if (_titleController.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        _categoryId == null) {
      setState(
        () => _validationError = 'Informe título, valor válido e categoria.',
      );
      return;
    }

    final transaction = TransactionModel(
      id: widget.existing?.id ?? '',
      title: _titleController.text.trim(),
      amount: amount,
      type: _type,
      categoryId: _categoryId!,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      locationName: _selectedLocation?.label,
      locationAddress: _selectedLocation?.address,
      locationLatitude: _selectedLocation?.point.latitude,
      locationLongitude: _selectedLocation?.point.longitude,
    );
    final success = _isEditing
        ? await widget.controller.update(transaction)
        : await widget.controller.create(transaction);
    if (success && mounted) Navigator.pop(context);
    if (!success && mounted) {
      setState(
        () => _validationError = 'Não foi possível salvar. Tente novamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Editar transação' : 'Nova transação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Saída'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Entrada'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (values) => _setType(values.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: _availableCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            if (_availableCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Crie uma categoria antes de salvar.'),
              ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Data'),
              subtitle: Text(
                '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
              ),
              onTap: _pickDate,
            ),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationTile(),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _validationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.controller.isSaving ? null : _submit,
                child: Text(_isEditing ? 'Salvar alterações' : 'Salvar transação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
