import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    return _firestore.collection('users').doc(user.uid).collection('categories');
  }

  Future<List<CategoryModel>> fetchAll() async {
    final snapshot = await _collection.orderBy('name').get();
    return snapshot.docs.map((doc) {
      return CategoryModel.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<void> create(CategoryModel category) async {
    final document = _collection.doc();
    await document.set({...category.toJson(), 'id': document.id});
  }

  Future<void> update(CategoryModel category) async {
    await _collection.doc(category.id).set(category.toJson());
  }

  Future<void> delete(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final linkedTransactions = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();

    if (linkedTransactions.docs.isNotEmpty) {
      throw StateError('Categoria em uso por uma transação.');
    }
    await _collection.doc(id).delete();
  }
}
