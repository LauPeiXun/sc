import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<T?> getModel<T>({
    required String collection,
    required String docId,
    required T Function(Map<String, dynamic> map) fromMap,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();

      if (doc.exists) {
        return fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setModel<T>({
    required String collection,
    required String docId,
    required T model,
    required Map<String, dynamic> Function(T model) toMap,
  }) async {
    try {
      final data = toMap(model);
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      rethrow;
    }
  }

  String generateDocId(String collection) {
    return _firestore.collection(collection).doc().id;
  }
}