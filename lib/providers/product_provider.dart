import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

enum ProductStatus { initial, loading, loaded, offline, error }

const _cacheFile = 'products_cache.json';

// ✅ No Firestore calls inside build() — all handled here (Common Mistake #5).
// ✅ Exercise 2: reads products from Firestore with snapshots() (real-time).
// ✅ Exercise 3: caches last good data locally for offline use.
class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  ProductStatus _status   = ProductStatus.initial;
  String _errorMessage    = '';
  StreamSubscription<List<Product>>? _sub;

  List<Product> get products     => _products;
  List<Product> get deals        => _products.take(4).toList();
  List<Product> get trending     => _products.length > 4 ? _products.sublist(4) : [];
  ProductStatus get status       => _status;
  bool   get isLoading           => _status == ProductStatus.loading;
  bool   get isOffline           => _status == ProductStatus.offline;
  bool   get hasError            => _status == ProductStatus.error;
  String get errorMessage        => _errorMessage;

  ProductProvider() { _init(); }

  Future<void> _init() async {
    _status = ProductStatus.loading;
    notifyListeners();

    // Exercise 2: seed `products` collection once if it's empty
    try {
      if (await FirestoreService.productsCollectionIsEmpty()) {
        final raw = await ApiService.fetchProducts(limit: 20);
        await FirestoreService.seedProducts(raw.map(Product.fromApiJson).toList());
      }
    } catch (_) {
      // Firestore or network unavailable at seed check — continue to listen
    }

    _listenToFirestore();
  }

  void _listenToFirestore() {
    _sub?.cancel();
    // ✅ Exercise 2: snapshots() for real-time product updates
    _sub = FirestoreService.productsStream().listen(
      (products) {
        _products     = products;
        _status       = ProductStatus.loaded;
        _errorMessage = '';
        notifyListeners();
        // ✅ Exercise 3: cache after successful fetch
        StorageService.writeJson(_cacheFile,
            products.map((p) => {...p.toFirestoreMap(), 'id': p.id}).toList());
      },
      onError: (_) => _loadFromCache(
        msg: 'Unable to connect. Showing saved products.'),
    );
  }

  Future<void> _loadFromCache({required String msg}) async {
    final cached = await StorageService.readJson(_cacheFile);
    if (cached is List && cached.isNotEmpty) {
      _products = cached.whereType<Map<String, dynamic>>().map((j) {
        final cat = j['category'] is String ? j['category'] as String : 'Others';
        return Product(
          id:            j['id']    is num    ? (j['id']    as num).toInt()    : 0,
          name:          j['name']  is String ? j['name']  as String           : 'Product',
          category:      cat,
          price:         j['price'] is num    ? (j['price'] as num).toDouble() : 0.0,
          originalPrice: j['originalPrice'] is num ? (j['originalPrice'] as num).toDouble() : 0.0,
          discount:      j['discount'] is num ? (j['discount'] as num).toInt() : 0,
          iconData:      kCategoryIcons[cat]  ?? Icons.shopping_bag_rounded,
          accent:        kCategoryColors[cat] ?? kAccent,
          stock:         '${j['stock'] is num ? (j['stock'] as num).toInt() : 0} left',
          imageUrl:      j['imageUrl'] is String ? j['imageUrl'] as String : '',
        );
      }).toList();
      _status = ProductStatus.offline;
    } else {
      _status       = ProductStatus.error;
      _errorMessage = msg;
    }
    notifyListeners();
  }

  Future<void> fetchProducts() => _init();

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
