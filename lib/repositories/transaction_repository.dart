import '../models/transaction_model.dart';

// ─── Enums de filtro/ordenação ─────────────────────────────────────────────────
// Ficam aqui pois são parâmetros do repositório, não lógica de UI.

enum TransactionFilter { all, income, expense }

enum TransactionSort { dateDesc, dateAsc }

// ─── Dados mockados ────────────────────────────────────────────────────────────

final List<TransactionModel> _mockData = [
  TransactionModel(
    id: '1',
    title: 'Salário maio',
    amount: 5200.00,
    type: 'income',
    categoryId: '1',
    date: DateTime(2025, 5, 5),
    note: 'Pagamento mensal',
  ),
  TransactionModel(
    id: '2',
    title: 'Aluguel',
    amount: 1400.00,
    type: 'expense',
    categoryId: '6',
    date: DateTime(2025, 5, 6),
  ),
  TransactionModel(
    id: '3',
    title: 'Supermercado Extra',
    amount: 340.50,
    type: 'expense',
    categoryId: '4',
    date: DateTime(2025, 5, 8),
    note: 'Compra da semana',
  ),
  TransactionModel(
    id: '4',
    title: 'Projeto website',
    amount: 800.00,
    type: 'income',
    categoryId: '2',
    date: DateTime(2025, 5, 10),
  ),
  TransactionModel(
    id: '5',
    title: 'Uber',
    amount: 45.90,
    type: 'expense',
    categoryId: '5',
    date: DateTime(2025, 5, 11),
  ),
  TransactionModel(
    id: '6',
    title: 'Farmácia',
    amount: 89.00,
    type: 'expense',
    categoryId: '7',
    date: DateTime(2025, 5, 13),
  ),
  TransactionModel(
    id: '7',
    title: 'Netflix',
    amount: 55.90,
    type: 'expense',
    categoryId: '8',
    date: DateTime(2025, 5, 14),
  ),
  TransactionModel(
    id: '8',
    title: 'Dividendos',
    amount: 210.00,
    type: 'income',
    categoryId: '3',
    date: DateTime(2025, 5, 15),
    note: 'ITSA4 + MXRF11',
  ),
  TransactionModel(
    id: '9',
    title: 'Restaurante',
    amount: 128.00,
    type: 'expense',
    categoryId: '4',
    date: DateTime(2025, 5, 17),
  ),
  TransactionModel(
    id: '10',
    title: 'Curso Udemy',
    amount: 49.90,
    type: 'expense',
    categoryId: '9',
    date: DateTime(2025, 5, 18),
  ),
  TransactionModel(
    id: '11',
    title: 'Gasolina',
    amount: 220.00,
    type: 'expense',
    categoryId: '5',
    date: DateTime(2025, 5, 20),
  ),
  TransactionModel(
    id: '12',
    title: 'Freelance app',
    amount: 1500.00,
    type: 'income',
    categoryId: '2',
    date: DateTime(2025, 5, 22),
    note: 'App de delivery',
  ),
  TransactionModel(
    id: '13',
    title: 'Academia',
    amount: 99.90,
    type: 'expense',
    categoryId: '7',
    date: DateTime(2025, 5, 23),
  ),
  TransactionModel(
    id: '14',
    title: 'Mercado livre',
    amount: 189.90,
    type: 'expense',
    categoryId: '10',
    date: DateTime(2025, 5, 25),
  ),
  TransactionModel(
    id: '15',
    title: 'Salário junho',
    amount: 5200.00,
    type: 'income',
    categoryId: '1',
    date: DateTime(2025, 6, 5),
  ),
  TransactionModel(
    id: '16',
    title: 'Aluguel junho',
    amount: 1400.00,
    type: 'expense',
    categoryId: '6',
    date: DateTime(2025, 6, 6),
  ),
  TransactionModel(
    id: '17',
    title: 'iFood',
    amount: 67.50,
    type: 'expense',
    categoryId: '4',
    date: DateTime(2025, 6, 7),
  ),
  TransactionModel(
    id: '18',
    title: 'Consulta médica',
    amount: 250.00,
    type: 'expense',
    categoryId: '7',
    date: DateTime(2025, 6, 9),
  ),
  TransactionModel(
    id: '19',
    title: 'Projeto logo',
    amount: 400.00,
    type: 'income',
    categoryId: '2',
    date: DateTime(2025, 6, 10),
  ),
  TransactionModel(
    id: '20',
    title: 'Spotify',
    amount: 21.90,
    type: 'expense',
    categoryId: '8',
    date: DateTime(2025, 6, 11),
  ),
];

class TransactionRepository {
  static const int pageSize = 8;

  Future<List<TransactionModel>> fetchPage({
    required int page,
    required TransactionFilter filter,
    required TransactionSort sort,
    required String search,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    var list = _mockData.toList();

    if (filter == TransactionFilter.income) {
      list = list.where((t) => t.isIncome).toList();
    } else if (filter == TransactionFilter.expense) {
      list = list.where((t) => t.isExpense).toList();
    }

    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q)).toList();
    }

    list.sort(
      (a, b) => sort == TransactionSort.dateDesc
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );

    final start = page * pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, (start + pageSize).clamp(0, list.length));
  }
}
