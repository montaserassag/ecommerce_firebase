import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_item.dart';
import '../models/product.dart';

// ✅ Keep Firestore logic in a service class — separate from UI.
// ✅ Handle Firestore errors separately from Auth errors.
class FirestoreException implements Exception {
  final String message;
  final String code;
  FirestoreException(this.message, this.code);
  @override String toString() => message;
}

class FirestoreService {
  FirestoreService._();
  static final _db = FirebaseFirestore.instance;

  // ─── Exercise 2: Products collection ────────────────────────────────────

  // ✅ Use snapshots() for real-time updates (Exercise 2 requirement)
  static Stream<List<Product>> productsStream() {
    return _db.collection('products').snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList())
        .handleError((e) => throw FirestoreException(
          'Unable to load products.', e is FirebaseException ? e.code : 'unknown'));
  }

  static Future<bool> productsCollectionIsEmpty() async {
    final snap = await _db.collection('products').limit(1).get();
    return snap.docs.isEmpty;
  }

  // Seed `products` once from a list using toFirestoreMap() — the toMap() side
  // of the fromDoc/toMap model class pattern (Exercise 2).
  static Future<void> seedProducts(List<Product> products) async {
    final batch = _db.batch();
    for (final p in products) {
      batch.set(_db.collection('products').doc(p.id.toString()), p.toFirestoreMap());
    }
    await batch.commit();
  }

  // ─── Exercise 3: users/{userId}/favorites ───────────────────────────────

  static CollectionReference<Map<String, dynamic>> _favsRef(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  // ✅ snapshots() — listen for real-time changes (Exercise 3)
  static Stream<List<FavoriteItem>> favoritesStream(String uid) {
    return _favsRef(uid).snapshots()
        .map((snap) => snap.docs.map((d) =>
            FavoriteItem.fromJson({...d.data(), 'id': int.tryParse(d.id) ?? 0})).toList())
        .handleError((e) => throw FirestoreException(
          'Unable to sync favorites.', e is FirebaseException ? e.code : 'unknown'));
  }

  // ✅ set() — add or replace a favorite document (Exercise 3 operation)
  static Future<void> setFavorite(String uid, FavoriteItem item) async {
    try {
      await _favsRef(uid).doc(item.id.toString()).set(item.toJson());
    } on FirebaseException catch (e) {
      throw FirestoreException('Could not save favorite.', e.code);
    }
  }

  // ✅ update() — partially update a favorite document (Exercise 3 operation)
  static Future<void> updateFavorite(String uid, int id, Map<String, dynamic> data) async {
    try {
      await _favsRef(uid).doc(id.toString()).update(data);
    } on FirebaseException catch (e) {
      throw FirestoreException('Could not update favorite.', e.code);
    }
  }

  static Future<void> removeFavorite(String uid, int id) async {
    try {
      await _favsRef(uid).doc(id.toString()).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException('Could not remove favorite.', e.code);
    }
  }
}
