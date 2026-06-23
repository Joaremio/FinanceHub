import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

enum TransactionFilter { all, income, expense }

enum TransactionSort { dateDesc, dateAsc }

class TransactionCursor {
  const TransactionCursor._(this._document);

  final QueryDocumentSnapshot<Map<String, dynamic>> _document;
}

class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<TransactionModel> items;
  final TransactionCursor? cursor;
  final bool hasMore;
}

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

  Future<TransactionPage> fetchPage({
    required TransactionFilter filter,
    required TransactionSort sort,
    required String search,
    TransactionCursor? after,
  }) async {
    final items = <TransactionModel>[];
    final normalizedSearch = search.trim().toLowerCase();
    var cursor = after?._document;
    var hasMore = true;

    while (items.length < pageSize && hasMore) {
      final remaining = pageSize - items.length;
      Query<Map<String, dynamic>> query = _collection;

      query = query
          .orderBy('date', descending: sort == TransactionSort.dateDesc)
          .limit(remaining);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      cursor = snapshot.docs.last;
      hasMore = snapshot.docs.length == remaining;

      final fetchedItems = snapshot.docs.map(_fromDocument).where((item) {
        final matchesFilter = filter == TransactionFilter.all ||
            (filter == TransactionFilter.income && item.isIncome) ||
            (filter == TransactionFilter.expense && item.isExpense);
        final matchesSearch = normalizedSearch.isEmpty ||
            item.title.toLowerCase().contains(normalizedSearch);
        return matchesFilter && matchesSearch;
      });
      items.addAll(fetchedItems);
    }

    return TransactionPage(
      items: items,
      cursor: cursor == null ? null : TransactionCursor._(cursor),
      hasMore: hasMore,
    );
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
