import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

enum TransactionFilter { all, income, expense }

enum TransactionSort { dateDesc, dateAsc }

class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const int pageSize = 8;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    return _firestore.collection('users').doc(user.uid).collection('transactions');
  }

  Future<List<TransactionModel>> fetchPage({
    required int page,
    required TransactionFilter filter,
    required TransactionSort sort,
    required String search,
  }) async {
    final snapshot = await _collection.get();
    var items = snapshot.docs.map(_fromDocument).toList();

    if (filter == TransactionFilter.income) {
      items = items.where((item) => item.isIncome).toList();
    } else if (filter == TransactionFilter.expense) {
      items = items.where((item) => item.isExpense).toList();
    }

    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) => item.title.toLowerCase().contains(query)).toList();
    }

    items.sort((a, b) => sort == TransactionSort.dateDesc
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));

    final start = page * pageSize;
    if (start >= items.length) return [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  Future<void> create(TransactionModel transaction) async {
    final document = _collection.doc();
    await document.set(_toFirestore(transaction, document.id));
  }

  Future<void> update(TransactionModel transaction) async {
    await _collection.doc(transaction.id).set(_toFirestore(transaction, transaction.id));
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  TransactionModel _fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawDate = data['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();
    return TransactionModel.fromJson({...data, 'id': doc.id, 'date': date.toIso8601String()});
  }

  Map<String, dynamic> _toFirestore(TransactionModel transaction, String id) {
    return {
      ...transaction.toJson(),
      'id': id,
      'date': Timestamp.fromDate(transaction.date),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
